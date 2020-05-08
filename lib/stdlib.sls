;; Standard utility library
;; Copyright © 2020 Lucas S. Vieira
;; Distributed under the MIT License
#!r6rs

(library (lib stdlib)
  (export char->byte)
  (import (rnrs))

  (define (char->byte c)
    (bytevector-u8-ref (string->bytevector
                        (string c)
                        (native-transcoder))
                       0)))
