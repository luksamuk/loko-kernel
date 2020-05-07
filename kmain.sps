;; Kernel entry point
;; Copyright © 2020 Lucas S. Vieira
;; Distributed under the MIT License
#!r6rs

(import (rnrs)
        (loko system unsafe)
        (loko system fibers)
        (stdlib)
        (vga))


;; Entry point
(define (kmain)
  (vga-clear)
  (for-each vga-print
          '("Hello world!\n\n"
            "This is an example kernel written in Loko Scheme.\n"
            "Currently, it just prints stuff to VGA output.\n"
            "This looks dope!\n\n"
            "I'll hang on an infinite loop now."))
  (let main-loop ()
    (sleep 1/60)
    (main-loop)))


;; Run kernel
(kmain)
