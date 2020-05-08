;; Kernel entry point
;; Copyright © 2020 Lucas S. Vieira
;; Distributed under the MIT License
#!r6rs

(import (rnrs)
        (loko system unsafe)
        (loko system fibers)
        (lib stdlib)
        (lib vga))


(define *version-major* 0)
(define *version-minor* 0)
(define *version-rev*   1)

(define (kdebrief)
  (vga-set-color! 'white 'black)
  (for-each vga-print
            (list
             "Lucas' Toy Kernel v"
             *version-major* #\. *version-minor* #\. *version-rev*
             #\linefeed
             "Copyright (c) 2020 Lucas S. Vieira\n\n"))
  (vga-set-color! 'white 'red)
  (vga-print "This software is very alpha!\n\n")
  (vga-set-color! 'white 'black))
  
;; Entry point
(define (kmain)
  (vga-clear)
  (vga-disable-cursor)
  (kdebrief)
  (vga-print "I'm gonna hang now on an infinite loop.")
  (let main-loop ()
    (sleep 1/60)
    (main-loop)))


;; Run kernel
(kmain)
