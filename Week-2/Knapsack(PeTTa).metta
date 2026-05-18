; PROBLEM DATA
; Change ONLY these three lines to swap problems.
(= (values)   (6 10 12 13 18))
(= (weights)  (2 3 4 5 9))
(= (capacity) 15)

; Known optimum for this instance:
;   chromosome (1 1 1 1 0), value 41, weight 14, fitness 41

; GA HYPERPARAMETERS (data, not code)
(= (mutation-rate) 10)        ; percent (0..100)
; Tournament size is currently fixed at 3 inside `tournament`.

; LIST HELPERS (recursive + edge-safe)

(= (llen $l)
   (if (== $l ())
       0
       (+ 1 (llen (cdr-atom $l)))))

; nth: returns () if out of bounds.
(= (nth $n $l)
   (if (== $l ())
       ()
       (if (== $n 1)
           (car-atom $l)
           (nth (- $n 1) (cdr-atom $l)))))

(= (lappend $a $b)
   (if (== $a ())
       $b
       (cons-atom (car-atom $a) (lappend (cdr-atom $a) $b))))

(= (ltake $n $l)
   (if (== $n 0)
       ()
       (if (== $l ())
           ()
           (cons-atom (car-atom $l) (ltake (- $n 1) (cdr-atom $l))))))

(= (ldrop $n $l)
   (if (== $n 0)
       $l
       (if (== $l ())
           ()
           (ldrop (- $n 1) (cdr-atom $l)))))

; RANDOM UTILITIES (guarded)
; random-int &rng 0 N is inclusive on both ends.
(= (rand-bit) (random-int &rng 0 1))

; rand-below: guards against $n <= 0 to avoid an invalid call.
(= (rand-below $n)
   (if (<= $n 0)
       0
       (random-int &rng 0 (- $n 1))))

(= (rand-chrom $n)
   (if (== $n 0)
       ()
       (cons-atom (rand-bit) (rand-chrom (- $n 1)))))

(= (rand-pop $size $n)
   (if (== $size 0)
       ()
       (cons-atom (rand-chrom $n) (rand-pop (- $size 1) $n))))

; FITNESS (generic, fully edge-safe)
; dot-product walks two lists in parallel.
; Stops as soon as either list is empty, never calls car/cdr on ().
(= (dot-product $bits $coeffs)
   (if (== $bits ())
       0
       (if (== $coeffs ())
           0
           (if (== (car-atom $bits) 1)
               (+ (car-atom $coeffs)
                  (dot-product (cdr-atom $bits) (cdr-atom $coeffs)))
               (dot-product (cdr-atom $bits) (cdr-atom $coeffs))))))

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
   (let* (($n   (llen $p1))
          ($cut (+ 1 (rand-below (- $n 1)))))
         (lappend (ltake $cut $p1) (ldrop $cut $p2))))

; MUTATION (rate as data)
(= (flip 0) 1)
(= (flip 1) 0)

(= (maybe-flip $bit)
   (if (< (rand-below 100) (mutation-rate))
       (flip $bit)
       $bit))

(= (mutate $chrom)
   (if (== $chrom ())
       ()
       (cons-atom (maybe-flip (car-atom $chrom))
                  (mutate (cdr-atom $chrom)))))

; BEST-IN POPULATION (edge-safe)
(= (best-in-helper $best $rest)
   (if (== $rest ())
       $best
       (best-in-helper (best-of-two $best (car-atom $rest))
                       (cdr-atom $rest))))

(= (best-in $pop)
   (if (== $pop ())
       ()
       (best-in-helper (car-atom $pop) (cdr-atom $pop))))

; EVOLUTION WITH ELITISM
(= (make-child $pop)
   (mutate (crossover (tournament $pop) (tournament $pop))))

(= (make-children $k $pop)
   (if (== $k 0)
       ()
       (cons-atom (make-child $pop) (make-children (- $k 1) $pop))))

; New population = elite + (size - 1) children.
(= (new-pop $size $pop)
   (cons-atom (best-in $pop) (make-children (- $size 1) $pop)))

(= (evolve $gens $pop $best)
   (if (== $gens 0)
       $best
       (let* (($next     (new-pop (llen $pop) $pop))
              ($pop-best (best-in $next))
              ($new-best (best-of-two $best $pop-best)))
             (evolve (- $gens 1) $next $new-best))))

; MAIN
(= (run-ga $pop-size $gens)
   (let* (($n      (llen (values)))
          ($pop0   (rand-pop $pop-size $n))
          ($best0  (best-in $pop0))
          ($final  (evolve $gens $pop0 $best0))
          ($v      (total-value  $final))
          ($w      (total-weight $final))
          ($f      (fitness $final))
          ($_1     (println! ===== GA_RESULT =====))
          ($_2     (println! (CHROMOSOME   $final)))
          ($_3     (println! (VALUE        $v)))
          ($_4     (println! (WEIGHT       $w)))
          ($_5     (println! (FITNESS      $f)))
          ($_6     (println! (POP_SIZE     $pop-size)))
          ($_7     (println! (CHROM_LENGTH $n)))
          ($_8     (println! (GENERATIONS  $gens)))
          ($_9     (println! (MUTATION_PCT (mutation-rate)))))
         done))

; VERIFICATION TRACES + RUN
!(trace! VERIFY_RANDOM   (rand-chrom 5))
!(trace! VERIFY_POP_INIT (rand-pop 4 5))
!(trace! VERIFY_FITNESS  (fitness (1 1 1 1 0)))
!(run-ga 20 30)