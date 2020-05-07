;; VGA library
;; Copyright © 2020 Lucas S. Vieira
;; Distributed under the MIT License
#!r6rs

(library (vga)
  (export vga-clear
          vga-clear-line
          vga-newline
          vga-backspace
          vga-putchar
          vga-print)
  (import (rnrs)
          (loko system unsafe)
          (stdlib)
          (kmem))

  (define *vga-ptr* #xb8000)
  (define *vga-pos* 0)

  (define *space* #x20)
  (define *monochrome* #x4f)

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

  ;; Raw operations
  (define (vga-clear)
    (let loop ((i 0))
      (when (< i *vga-buf-sz*)
        (put-mem-u8 (vga-at i)
                    *space*)
        (put-mem-u8 (vga-at (+ i 1))
                    #x0f)
        (loop (+ i (vga-prop 'bpc)))))
    (set! *vga-pos* 0))

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
                    *monochrome*)
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
      (- *vga-pos* *vga-line-sz*)))

  (define (vga-putchar-raw c)
    (when (>= (+ *vga-pos* 1)
              *vga-buf-sz*)
      (vga-scroll-up))
    (put-mem-u8 (vga-at *vga-pos*) c)
    (put-mem-u8 (vga-at (+ *vga-pos* 1)) *monochrome*)
    (set! *vga-pos* (+ *vga-pos* 2)))

  (define (vga-newline)
    (let ((line-pos (mod *vga-pos*
                         (* (vga-prop 'cols)
                            (vga-prop 'bpc)))))
      (set! *vga-pos*
        (+ *vga-pos* (- (* (vga-prop 'cols)
                           (vga-prop 'bpc))
                        line-pos))))
    (when (>= *vga-pos* *vga-buf-sz*)
      (vga-scroll-up)))

  (define (vga-backspace)
    (when (not (= *vga-pos* 0))
      (set! *vga-pos* (- *vga-pos* 2))
      (put-mem-u8 (vga-at *vga-pos*)     *space*)
      (put-mem-u8 (vga-at (+ *vga-pos* 1))
                  *monochrome*)))

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
