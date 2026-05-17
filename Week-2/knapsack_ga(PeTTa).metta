
; (just data, swap freely)
(= (values)   (1 2 3))     ; values of items
(= (weights)  (4 5 1))     ; weights of items
(= (capacity) 4)

; LIST HELPERS (all recursive)
(= (llen $l)
   (if (== $l ())
       0
       (+ 1 (llen (cdr-atom $l)))))

(= (nth $n $l)
   (if (== $n 1)
       (car-atom $l)
       (nth (- $n 1) (cdr-atom $l))))

(= (lappend $a $b)
   (if (== $a ())
       $b
       (cons-atom (car-atom $a) (lappend (cdr-atom $a) $b))))

(= (ltake $n $l)
   (if (== $n 0)
       ()
       (cons-atom (car-atom $l) (ltake (- $n 1) (cdr-atom $l)))))

(= (ldrop $n $l)
   (if (== $n 0)
       $l
       (ldrop (- $n 1) (cdr-atom $l))))

; RANDOM UTILITIES
(= (rand-bit)        (random-int &rng 0 1))
(= (rand-below $n)   (random-int &rng 0 (- $n 1)))

(= (rand-chrom $n)
   (if (== $n 0)
       ()
       (cons-atom (rand-bit) (rand-chrom (- $n 1)))))

(= (rand-pop $size $n)
   (if (== $size 0)
       ()
       (cons-atom (rand-chrom $n) (rand-pop (- $size 1) $n))))

; FITNESS (generic: walks chromosome + values + weights together)

; Sum the values of items whose bit is 1.
; Recursively walks three lists in parallel: chromosome bits, values, weights.
(= (dot-product $bits $vals)
   (if (== $bits ())
       0
       (if (== (car-atom $bits) 1)
           (+ (car-atom $vals) (dot-product (cdr-atom $bits) (cdr-atom $vals)))
           (dot-product (cdr-atom $bits) (cdr-atom $vals)))))

(= (total-weight $chrom) (dot-product $chrom (weights)))
(= (total-value  $chrom) (dot-product $chrom (values)))

(= (fitness $chrom)
   (if (> (total-weight $chrom) (capacity))
       0
       (total-value $chrom)))

; SELECTION (tournament, size 3)
(= (rand-from-pop $pop)
   (nth (+ 1 (rand-below (llen $pop))) $pop))

(= (best-of-two $a $b)
   (if (> (fitness $a) (fitness $b)) $a $b))

(= (tournament $pop)
   (best-of-two
     (best-of-two (rand-from-pop $pop) (rand-from-pop $pop))
     (rand-from-pop $pop)))

; CROSSOVER (single-point)
(= (crossover $p1 $p2)
   (let* (($n (llen $p1))
          ($cut (+ 1 (rand-below (- $n 1)))))
         (lappend (ltake $cut $p1) (ldrop $cut $p2))))

; MUTATION (~10% per bit)
(= (flip 0) 1)
(= (flip 1) 0)

(= (maybe-flip $bit)
   (if (< (rand-below 10) 1)
       (flip $bit)
       $bit))

(= (mutate $chrom)
   (if (== $chrom ())
       ()
       (cons-atom (maybe-flip (car-atom $chrom))
                  (mutate (cdr-atom $chrom)))))

; EVOLUTION
(= (make-child $pop)
   (mutate (crossover (tournament $pop) (tournament $pop))))

(= (new-pop $k $old)
   (if (== $k 0)
       ()
       (cons-atom (make-child $old) (new-pop (- $k 1) $old))))

(= (best-in-helper $best $rest)
   (if (== $rest ())
       $best
       (best-in-helper (best-of-two $best (car-atom $rest))
                       (cdr-atom $rest))))

(= (best-in $pop)
   (best-in-helper (car-atom $pop) (cdr-atom $pop)))

(= (evolve $gens $pop $best)
   (if (== $gens 0)
       $best
       (let* (($next-pop (new-pop (llen $pop) $pop))
              ($pop-best (best-in $next-pop))
              ($new-best (best-of-two $best $pop-best)))
             (evolve (- $gens 1) $next-pop $new-best))))

; MAIN
; n is computed from the values list - fully generic
(= (run-ga $pop-size $gens)
   (let* (($n      (llen (values)))
          ($pop0   (rand-pop $pop-size $n))
          ($best0  (best-in $pop0))
          ($final  (evolve $gens $pop0 $best0)))
         (Result $final (value (total-value $final)) (weight (total-weight $final)))))

!(trace! GA_RESULT (run-ga 6 5))