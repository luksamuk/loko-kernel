;; Kernel memory library
;; Copyright © 2020 Lucas S. Vieira
;; Distributed under the MIT License
#!r6rs

(library (lib kmem)
  (export kmemcpy
          kmemset)
  (import (rnrs)
          (loko system unsafe))

  (define (kmemcpy dest src size)
    (when (not (or (= dest src)
                   (< src (+ dest size))))
      (let loop ((i 0))
        (when (< i size)
          (put-mem-u8 (+ dest i)
                      (get-mem-u8 (+ src i)))
          (loop (+ i 1))))))

  (define (kmemset dest c size)
    (let loop ((i 0))
      (when (< i size)
        (put-mem-u8 (+ dest i) c)
        (loop (+ i 1))))))
