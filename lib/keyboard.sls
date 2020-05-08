;; Keyboard library
;; Copyright © 2020 Lucas S. Vieira
;; Distributed under the MIT License
#!r6rs

(library (lib keyboard)
  (export)
  (import (rnrs)
          (loko system unsafe)
          (loko arch amd64 pc-interrupts))
  ;; https://wiki.osdev.org/Keyboard
  )
