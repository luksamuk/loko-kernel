;; VGA library
;; Copyright © 2020 Lucas S. Vieira
;; Distributed under the MIT License
#!r6rs

(library (lib vga)
  (export vga-clear
          vga-clear-line
          vga-color
          vga-mix-color
          vga-set-color!
          vga-enable-cursor
          vga-disable-cursor
          vga-update-cursor
          vga-newline
          vga-backspace
          vga-putchar
          vga-print)
  (import (rnrs)
          (loko system unsafe)
          (lib stdlib)
          (lib kmem))

  (define *vga-ptr* #xb8000)
  (define *vga-pos* 0)

  (define *space* #x20)
  (define *monochrome* #x0f) ; unused
  (define *alert* #x4f)      ; unused

  ;; Global state elements
  (define *vga-props*
    '((cols  . 80)
      (lines . 25)
      (bpc   . 2)))

  (define (vga-prop prop)
    (cdr (assoc prop *vga-props*)))

  (define *vga-buf-sz*
    (* (vga-prop 'cols)
       (vga-prop 'lines)
       (vga-prop 'bpc)))

  (define *vga-line-sz*
    (* (vga-prop 'cols)
       (vga-prop 'bpc)))

  (define (vga-at pos)
    (+ *vga-ptr* pos))

  ;; Color operations
  (define *vga-color-set*
    (make-enumeration
    '(black
      blue
      green
      cyan
      red
      magenta
      brown
      light-grey
      dark-grey
      light-blue
      light-green
      light-cyan
      light-red
      light-magenta
      light-brown
      white)))

  (define (vga-color c)
    (let ((indexer (enum-set-indexer *vga-color-set*)))
      (indexer c)))

  (define (vga-mix-color fg bg)
    (bitwise-ior
     fg
     (bitwise-arithmetic-shift-left bg 4)))

  (define *vga-print-color*
    (vga-mix-color (vga-color 'white)
                   (vga-color 'black)))

  (define (vga-set-color! fg bg)
    (set! *vga-print-color*
      (vga-mix-color (vga-color fg)
                     (vga-color bg))))

  ;; Cursor
  ;; https://wiki.osdev.org/Text_Mode_Cursor
  (define (vga-enable-cursor start end)
    (put-i/o-u8 #x3d4 #x0a)
    (put-i/o-u8 #x3d5
                (bitwise-ior
                 (bitwise-and (get-i/o-u8 #x3d5)
                              #xc0)
                 start))
    (put-i/o-u8 #x3d4 #x0b)
    (put-i/o-u8 #x3d5
                (bitwise-ior
                 (bitwise-and (get-i/o-u8 #x3d5)
                              #xe0)
                 end)))

  (define (vga-disable-cursor)
    (put-i/o-u8 #x3d4 #x0a)
    (put-i/o-u8 #x3d5 #x20))

  (define (vga-update-cursor-raw pos)
    (put-i/o-u8 #x3d4 #x0f)
    (put-i/o-u8 #x3d5 (bitwise-and pos #xff))
    (put-i/o-u8 #x3d4 #x0e)
    (put-i/o-u8 #x3d5
                (bitwise-and
                 (bitwise-arithmetic-shift-right pos 8)
                 #xff)))
  
  (define (vga-update-cursor x y)
    (vga-update-cursor-raw
     (+ (+ (vga-prop 'lines) y)
        x)))

  ;; Raw operations
  (define (vga-clear)
    (let loop ((i 0))
      (when (< i *vga-buf-sz*)
        (put-mem-u8 (vga-at i)
                    *space*)
        (put-mem-u8 (vga-at (+ i 1))
                    #x0f)
        (loop (+ i (vga-prop 'bpc)))))
    (set! *vga-pos* 0)
    (vga-update-cursor-raw *vga-pos*))

  (define (vga-clear-line line)
    (when (< line (vga-prop 'lines))
      (set! line
        (* line *vga-line-sz*)))
    (let loop ((i 0))
      (when (< i (vga-prop 'cols))
        (put-mem-u8 (vga-at
                     (+ line (* i 2)))
                    *space*)
        (put-mem-u8 (vga-at
                     (+ line (* i 2) 1))
                    *vga-print-color*)
        (loop (+ i 1)))))

  (define (vga-scroll-up)
    (let loop ((i 1))
      (when (< i (vga-prop 'lines))
        (kmemcpy (vga-at
                  (* (- i 1)
                     *vga-line-sz*))
                 (vga-at
                  (* i *vga-line-sz*))
                 *vga-line-sz*)
        (loop (+ i 1))))
    (vga-clear-line 24)
    (set! *vga-pos*
      (- *vga-pos* *vga-line-sz*))
    (vga-update-cursor-raw *vga-pos*))

  (define (vga-putchar-raw c)
    (when (>= (+ *vga-pos* 1)
              *vga-buf-sz*)
      (vga-scroll-up))
    (put-mem-u8 (vga-at *vga-pos*) c)
    (put-mem-u8 (vga-at (+ *vga-pos* 1)) *vga-print-color*)
    (set! *vga-pos* (+ *vga-pos* 2))
    (vga-update-cursor-raw *vga-pos*))

  (define (vga-newline)
    (let ((line-pos (mod *vga-pos*
                         (* (vga-prop 'cols)
                            (vga-prop 'bpc)))))
      (set! *vga-pos*
        (+ *vga-pos* (- (* (vga-prop 'cols)
                           (vga-prop 'bpc))
                        line-pos)))
      (vga-update-cursor-raw *vga-pos*))
    (when (>= *vga-pos* *vga-buf-sz*)
      (vga-scroll-up)))

  (define (vga-backspace)
    (when (not (= *vga-pos* 0))
      (set! *vga-pos* (- *vga-pos* 2))
      (vga-update-cursor-raw *vga-pos*)
      (put-mem-u8 (vga-at *vga-pos*)     *space*)
      (put-mem-u8 (vga-at (+ *vga-pos* 1))
                  *vga-print-color*)))

  (define (vga-putchar c)
    (case c
      ((#x0a)
       (vga-newline))
      ((#x08)
       (vga-backspace))
      (else
       (vga-putchar-raw c))))

  (define (vga-print elt)
    (cond ((char? elt)
           (vga-putchar
            (char->byte elt)))
          ((number? elt)
           (vga-print (number->string elt)))
          ((string? elt)
           (let ((len (string-length elt))
                 (vec (string->bytevector
                       elt
                       (native-transcoder))))
             (let loop ((i 0))
               (when (< i len)
                 (vga-putchar (bytevector-u8-ref
                               vec i))
                 (loop (+ i 1))))))
          (else (for-each
                 display
                 (list "Unknown display for "
                       elt
                       #\linefeed))))))
