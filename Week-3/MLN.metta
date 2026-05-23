; Helpers
(= (min2 $a $b) (if (< $a $b) $a $b))

; Integer division, since PeTTa's / yields a float
(= (idiv $a $b) (floor-math (/ $a $b)))

; Powers of two for bit indexing
(= (pw2 0)  1)   (= (pw2 1)  2)   (= (pw2 2)  4)   (= (pw2 3)  8)
(= (pw2 4)  16)  (= (pw2 5)  32)  (= (pw2 6)  64)  (= (pw2 7)  128)
(= (pw2 8)  256) (= (pw2 9)  512) (= (pw2 10) 1024)

; Bit b of world w, returns 0 or 1
(= (bit $w $b) (% (idiv $w (pw2 $b)) 2))


; Logical primitives over 0 and 1
(= (l-impl $a $b) (if (== $a 1) (if (== $b 1) 1 0) 1))
(= (l-iff  $a $b) (if (== $a $b) 1 0))
(= (l-and  $a $b) (if (== $a 1) (if (== $b 1) 1 0) 0))
(= (l-or   $a $b) (if (== $a 1) 1 (if (== $b 1) 1 0)))
(= (l-not  $a)    (if (== $a 1) 0 1))


; Clause evaluator
; Clause spec is a tree built from
;   (atom n)      bit n of the world
;   (const v)     literal 0 or 1
;   (not c)
;   (and a b)
;   (or  a b)
;   (impl a b)
;   (iff a b)
(= (eval-clause $w (atom $n))    (bit $w $n))
(= (eval-clause $w (const $v))   $v)
(= (eval-clause $w (not  $a))    (l-not  (eval-clause $w $a)))
(= (eval-clause $w (and  $a $b)) (l-and  (eval-clause $w $a) (eval-clause $w $b)))
(= (eval-clause $w (or   $a $b)) (l-or   (eval-clause $w $a) (eval-clause $w $b)))
(= (eval-clause $w (impl $a $b)) (l-impl (eval-clause $w $a) (eval-clause $w $b)))
(= (eval-clause $w (iff  $a $b)) (l-iff  (eval-clause $w $a) (eval-clause $w $b)))


; Score a world against a formulas list, using car-atom/cdr-atom recursion
; A formulas list looks like ((w1 spec1) (w2 spec2) (w3 spec3) ...)
(= (score-formulas $w $formulas)
   (if (== $formulas ()) 0.0
       (let* (($pair  (car-atom $formulas))
              ($rest  (cdr-atom $formulas))
              ($wt    (car-atom $pair))
              ($spec  (car-atom (cdr-atom $pair))))
         (+ (* $wt (eval-clause $w $spec))
            (score-formulas $w $rest)))))


; Unnormalized world weight
(= (wt $w $formulas) (exp (score-formulas $w $formulas)))


; Enumerate worlds 0..top by counting down
(= (z-from $w $formulas)
   (if (< $w 0) 0.0
       (+ (wt $w $formulas) (z-from (- $w 1) $formulas))))

(= (marg-from $w $b $formulas)
   (if (< $w 0) 0.0
       (+ (* (bit $w $b) (wt $w $formulas))
          (marg-from (- $w 1) $b $formulas))))

(= (marg2-from $w $b1 $b2 $formulas)
   (if (< $w 0) 0.0
       (+ (* (bit $w $b1) (* (bit $w $b2) (wt $w $formulas)))
          (marg2-from (- $w 1) $b1 $b2 $formulas))))


; Top-level queries, top = (2^num_atoms - 1)
(= (Z $top $formulas) (z-from $top $formulas))
(= (P-bit  $b      $top $formulas) (/ (marg-from  $top $b      $formulas) (Z $top $formulas)))
(= (P-both $b1 $b2 $top $formulas) (/ (marg2-from $top $b1 $b2 $formulas) (Z $top $formulas)))
(= (P-cond $b1 $b2 $top $formulas) (/ (P-both $b1 $b2 $top $formulas) (P-bit $b2 $top $formulas)))


; Domain definition, smoking MLN from Richardson and Domingos Table I
; Bit layout
;   0 Smokes(Anna)   1 Smokes(Bob)
;   2 Cancer(Anna)   3 Cancer(Bob)
;   4 Friends(Anna,Bob)   5 Friends(Bob,Anna)
; Six atoms means top index = 63
(= (smoking-mln)
   ( (1.5 (impl (atom 0) (atom 2)))
     (1.5 (impl (atom 1) (atom 3)))
     (1.1 (impl (atom 4) (iff (atom 0) (atom 1))))
     (1.1 (impl (atom 5) (iff (atom 1) (atom 0)))) ))


; Tests, all in one block
!(println! "Markov Logic Network, smoking domain")
!(println! "")
!(println! "Marginal probabilities")
!(test  ("P(Smokes Anna)       =" (P-bit 0 63 (smoking-mln))))
!(test  ("P(Smokes Bob)        =" (P-bit 1 63 (smoking-mln))))
!(test  ("P(Cancer Anna)       =" (P-bit 2 63 (smoking-mln))))
!(test  ("P(Cancer Bob)        =" (P-bit 3 63 (smoking-mln))))
!(test  ("P(Friends Anna Bob)  =" (P-bit 4 63 (smoking-mln))))
!(println! "")
!(println! "Conditional probabilities")
!(test  ("P(Cancer Anna | Smokes Anna) =" (P-cond 2 0 63 (smoking-mln))))
!(test  ("P(Cancer Bob   | Smokes Bob) =" (P-cond 3 1 63 (smoking-mln))))
!(test  ("P(Smokes Bob | Smokes Anna and Friends Anna Bob) ="
            (/ (marg2-from 63 1 4 (smoking-mln))
               (marg2-from 63 0 4 (smoking-mln)))))