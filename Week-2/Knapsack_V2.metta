; 0/1 Knapsack Problem

; 1. LIST UTILITIES

(= (len Nil) 0)
(= (len (Cons $h $t)) (+ 1 (len $t)))

(= (take $k Nil) Nil)
(= (take $k (Cons $h $t))
   (if (<= $k 0) Nil (Cons $h (take (- $k 1) $t))))

(= (drop $k Nil) Nil)
(= (drop $k (Cons $h $t))
   (if (<= $k 0) (Cons $h $t) (drop (- $k 1) $t)))

(= (concat Nil $b) $b)
(= (concat (Cons $h $t) $b) (Cons $h (concat $t $b)))

(= (head-of Nil) Nil)
(= (head-of (Cons $h $t)) $h)

(= (nth $i Nil) 0)
(= (nth $i (Cons $h $t))
   (if (<= $i 0) $h (nth (- $i 1) $t)))


; 2. PSEUDO-RANDOM NUMBER GENERATOR
; LCG period 2^31, native % for constant-time reduction.
; Every random op returns Pair(value, new-seed).

(= (next-seed $seed)
   (% (+ (* $seed 1103515245) 12345) 2147483648))

(= (first  (Pair $a $b)) $a)
(= (second (Pair $a $b)) $b)

(= (rand-int $seed $max)
   (let $s2 (next-seed $seed)
     (Pair (% $s2 $max) $s2)))


; 3. PROBLEM DATA
; Items, capacity, and GA hyperparameters are all data.
; mutation-rate is out of 100 (e.g. 30 means 30%).

(= (items)
   (Cons (Pair 2 6)
   (Cons (Pair 3 10)
   (Cons (Pair 4 12)
   (Cons (Pair 5 13)
   (Cons (Pair 9 18)
         Nil))))))

(= (capacity) 15)
(= (mutation-rate) 30)

(= (pair-weight (Pair $w $v)) $w)
(= (pair-value  (Pair $w $v)) $v)


; 4. FITNESS

(= (weight-of Nil $items) 0)
(= (weight-of (Cons $b $bt) Nil) 0)
(= (weight-of (Cons $b $bt) (Cons $i $it))
   (+ (* $b (pair-weight $i)) (weight-of $bt $it)))

(= (value-of Nil $items) 0)
(= (value-of (Cons $b $bt) Nil) 0)
(= (value-of (Cons $b $bt) (Cons $i $it))
   (+ (* $b (pair-value $i)) (value-of $bt $it)))

(= (fitness $c)
   (let $is (items)
     (if (> (weight-of $c $is) (capacity))
         0
         (value-of $c $is))))


; 5. CROSSOVER


(= (crossover-a $p1 $p2 $k) (concat (take $k $p1) (drop $k $p2)))
(= (crossover-b $p1 $p2 $k) (concat (take $k $p2) (drop $k $p1)))



; 6. MUTATION

(= (flip 0) 1)
(= (flip 1) 0)

(= (mutate-helper Nil $target $i) Nil)
(= (mutate-helper (Cons $h $t) $target $i)
   (if (== $i $target)
       (Cons (flip $h) $t)
       (Cons $h (mutate-helper $t $target (+ $i 1)))))

(= (mutate $c $pos) (mutate-helper $c $pos 0))


; 7. SELECTION

(= (tournament $a $b)
   (if (>= (fitness $a) (fitness $b)) $a $b))

(= (pick-random $pop $seed)
   (if (== $pop Nil)
       (Pair Nil $seed)
       (let $r (rand-int $seed (len $pop))
         (Pair (nth (first $r) $pop) (second $r)))))

(= (tournament-select $pop $seed)
   (let* (($r1 (pick-random $pop $seed))
          ($r2 (pick-random $pop (second $r1))))
     (Pair (tournament (first $r1) (first $r2)) (second $r2))))



; 8. EVOLUTION

(= (chrom-len Nil) 0)
(= (chrom-len (Cons $c $rest)) (len $c))

(= (best-of-pop Nil) Nil)
(= (best-of-pop (Cons $h Nil)) $h)
(= (best-of-pop (Cons $h (Cons $h2 $rest)))
   (tournament $h (best-of-pop (Cons $h2 $rest))))

; make-child with probabilistic mutation.
; Roll a number in [0, 99]; mutate only if roll < mutation-rate.
; Returns Pair(child, new-seed).
(= (make-child $pop $L $seed)
   (let* (($r1 (tournament-select $pop $seed))
          ($p1 (first $r1))
          ($r2 (tournament-select $pop (second $r1)))
          ($p2 (first $r2))
          ($rk (rand-int (second $r2) (- $L 1)))
          ($k  (+ 1 (first $rk)))
          ($child (crossover-a $p1 $p2 $k))
          ($rm (rand-int (second $rk) 100)))
     (if (< (first $rm) (mutation-rate))
         (let $rp (rand-int (second $rm) $L)
              (Pair (mutate $child (first $rp)) (second $rp)))
         (Pair $child (second $rm)))))

; build-children returns Pair(children-list, final-seed)
(= (build-children $pop $n $L $seed)
   (if (<= $n 0)
       (Pair Nil $seed)
       (let* (($r (make-child $pop $L $seed))
              ($child (first $r))
              ($s2 (second $r))
              ($rest (build-children $pop (- $n 1) $L $s2))
              ($children (first $rest))
              ($s3 (second $rest)))
         (Pair (Cons $child $children) $s3))))

; evolve-pop returns Pair(new-pop, new-seed) - seed cleanly threaded
(= (evolve-pop $pop $seed)
   (if (== $pop Nil)
       (Pair Nil $seed)
       (if (< (chrom-len $pop) 2)
           (Pair $pop $seed)
           (let* (($best (best-of-pop $pop))
                  ($L (chrom-len $pop))
                  ($n (- (len $pop) 1))
                  ($r (build-children $pop $n $L $seed))
                  ($children (first $r))
                  ($new-seed (second $r)))
             (Pair (Cons $best $children) $new-seed)))))



; 9. RECURSIVE GA LOOP
; Uses the seed that evolve-pop returns - no separate advancement.
; Returns Pair(final-pop, final-seed).

(= (run-ga $pop $n $seed)
   (if (<= $n 0)
       (Pair $pop $seed)
       (let* (($r (evolve-pop $pop $seed))
              ($next-pop (first $r))
              ($next-seed (second $r)))
         (run-ga $next-pop (- $n 1) $next-seed))))

; Traced version - prints best fitness per generation
(= (run-ga-traced $pop $n $seed)
   (if (<= $n 0)
       (Pair $pop $seed)
       (let* (($r (evolve-pop $pop $seed))
              ($next-pop (first $r))
              ($next-seed (second $r))
              ($best-fit (fitness (best-of-pop $next-pop)))
              (() (println! (gen-remaining $n best-fit $best-fit))))
         (run-ga-traced $next-pop (- $n 1) $next-seed))))


; 10. INITIAL POPULATION
; Deliberately excludes the optimum [1,1,1,1,0].
; Each chromosome has partial good genes; GA must combine them.
; Initial best fitness should be well below 41.
(= (init-pop)
   (Cons (Cons 1 (Cons 1 (Cons 0 (Cons 0 (Cons 0 Nil)))))
   (Cons (Cons 0 (Cons 0 (Cons 1 (Cons 1 (Cons 0 Nil)))))
   (Cons (Cons 1 (Cons 0 (Cons 0 (Cons 0 (Cons 1 Nil)))))
   (Cons (Cons 0 (Cons 1 (Cons 1 (Cons 0 (Cons 0 Nil)))))
   (Cons (Cons 1 (Cons 0 (Cons 1 (Cons 0 (Cons 0 Nil)))))
   (Cons (Cons 0 (Cons 1 (Cons 0 (Cons 1 (Cons 0 Nil)))))
   (Cons (Cons 0 (Cons 0 (Cons 1 (Cons 0 (Cons 1 Nil)))))
   (Cons (Cons 1 (Cons 0 (Cons 0 (Cons 1 (Cons 0 Nil)))))
         Nil)))))))))



; 11. TESTS
!(println! (test-1-len (len (Cons 1 (Cons 0 (Cons 1 Nil))))))
!(println! (test-1-modulo (% 23 7)))
!(println! (test-1-rand (rand-int 7 5)))

!(println! (test-2-fit-optimal
  (fitness (Cons 1 (Cons 1 (Cons 1 (Cons 1 (Cons 0 Nil))))))))
!(println! (test-2-fit-overweight
  (fitness (Cons 1 (Cons 1 (Cons 1 (Cons 1 (Cons 1 Nil))))))))

!(println! (test-3-pop-size (len (init-pop))))
!(println! (test-3-chrom-len (chrom-len (init-pop))))
!(println! (test-3-initial-best (best-of-pop (init-pop))))
!(println! (test-3-initial-fit (fitness (best-of-pop (init-pop)))))
!(println! (test-3-mutation-rate (mutation-rate)))

; Confirm evolve-pop returns Pair(pop, seed)
!(println! (test-4-evolve-shape (evolve-pop (init-pop) 13)))

; Confirm run-ga returns Pair(pop, seed)
!(println! (test-4-run-ga-shape (run-ga (init-pop) 2 42)))

!(println! (test-5-empty-pop-safe (evolve-pop Nil 42)))
!(println! (test-5-empty-chrom-len (chrom-len Nil)))



; 12. MAIN
; Call run-ga-traced ONCE, materialize the result, reuse it
; for every final output.

!(println! (=== MAIN RUN ===))
!(println! (population-size (len (init-pop))))
!(println! (chromosome-length (chrom-len (init-pop))))
!(println! (mutation-rate-percent (mutation-rate)))
!(println! (initial-best-fitness (fitness (best-of-pop (init-pop)))))

!(let* (($result (run-ga-traced (init-pop) 30 42))
        ($final-pop (first $result))
        ($final-seed (second $result))
        ($best (best-of-pop $final-pop))
        (() (println! (=== Final Results ===)))
        (() (println! (final-best $best)))
        (() (println! (final-fitness (fitness $best))))
        (() (println! (final-weight (weight-of $best (items)))))
        (() (println! (final-value (value-of $best (items)))))
        (() (println! (final-seed $final-seed))))
   ())