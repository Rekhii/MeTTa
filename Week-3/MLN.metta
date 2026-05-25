; PeTTa's always returns a float, but for bit math we need a whole number,
; so we floor the result. Example: (idiv 7 2) returns 3, not 3.5
(= (idiv $a $b) (floor-math (/ $a $b)))


; Power-of-two helper using the stdlib pow-math function
; (pw2 5) = 2^5 = 32. We need this to extract individual bits from a world.
; Earlier versions used a lookup table, this is cleaner and unbounded.
(= (pw2 $b) (pow-math 2 $b))


; Extract bit b of integer w, returns 0 or 1
; The trick: shift right by b bits (divide by 2^b, drop the remainder),
; then look at the last bit (mod 2).
; Example: world 5 = binary 101
;   (bit 5 0) = 1, (bit 5 1) = 0, (bit 5 2) = 1
(= (bit $w $b) (% (idiv $w (pw2 $b)) 2))


; Logical primitives over 0/1 integers
; These let us evaluate logical formulas without using True/False symbols,
; so we can multiply them by weights for the MLN score

; Material implication, false only when antecedent is true and consequent false
(= (l-impl $a $b) (if (== $a 1) (if (== $b 1) 1 0) 1))

; Biconditional, 1 when both bits agree, 0 otherwise
(= (l-iff  $a $b) (if (== $a $b) 1 0))

; Conjunction
(= (l-and  $a $b) (if (== $a 1) (if (== $b 1) 1 0) 0))

; Disjunction
(= (l-or   $a $b) (if (== $a 1) 1 (if (== $b 1) 1 0)))

; Negation
(= (l-not  $a)    (if (== $a 1) 0 1))


; Clause evaluator
; A clause is a tree built from the following node types:
;   (atom n)     reference to bit n of the world
;   (const v)    a literal 0 or 1
;   (not c)
;   (and c1 c2)
;   (or c1 c2)
;   (impl c1 c2)
;   (iff c1 c2)
; eval-clause walks the tree and computes its truth value (0 or 1) in world w
(= (eval-clause $w (atom $n))    (bit $w $n))
(= (eval-clause $w (const $v))   $v)
(= (eval-clause $w (not  $a))    (l-not  (eval-clause $w $a)))
(= (eval-clause $w (and  $a $b)) (l-and  (eval-clause $w $a) (eval-clause $w $b)))
(= (eval-clause $w (or   $a $b)) (l-or   (eval-clause $w $a) (eval-clause $w $b)))
(= (eval-clause $w (impl $a $b)) (l-impl (eval-clause $w $a) (eval-clause $w $b)))
(= (eval-clause $w (iff  $a $b)) (l-iff  (eval-clause $w $a) (eval-clause $w $b)))


; Compute the MLN log-score of a world
; The MLN score is the weighted sum of satisfied formulas:
;   score(w) = sum over i of (weight_i * eval_clause(formula_i, w))
; The formulas list looks like ((1.5 clause1) (1.1 clause2) ...)
; We walk the list with car-atom/cdr-atom and sum the contributions
(= (score-formulas $w $formulas)
   (if (== $formulas ()) 0.0
       (let* (($pair  (car-atom $formulas))
              ($rest  (cdr-atom $formulas))
              ($wt    (car-atom $pair))
              ($spec  (car-atom (cdr-atom $pair))))
         (+ (* $wt (eval-clause $w $spec))
            (score-formulas $w $rest)))))


; Unnormalized world weight
; By the MLN definition (Equation 3 of Richardson and Domingos):
;   P(w) is proportional to exp(score(w))
; Hence wt(w) = exp(score(w)). The denominator Z normalizes these.
(= (wt $w $formulas) (exp (score-formulas $w $formulas)))


; Partition function Z, sum of wt over every possible world
; We enumerate worlds by counting down from $top to 0.
;   $top = 2^num_atoms - 1
; Each integer in [0, top] encodes a unique truth assignment via its bits.
(= (z-from $w $formulas)
   (if (< $w 0) 0.0
       (+ (wt $w $formulas) (z-from (- $w 1) $formulas))))


; Sum of world weights where the specified bit is 1
; Used to compute the marginal probability that a single ground atom is true:
;   P(atom_b = 1) = marg-from / Z
(= (marg-from $w $b $formulas)
   (if (< $w 0) 0.0
       (+ (* (bit $w $b) (wt $w $formulas))
          (marg-from (- $w 1) $b $formulas))))


; Sum of world weights where two specified bits are both 1
; Used for joint and conditional probabilities
(= (marg2-from $w $b1 $b2 $formulas)
   (if (< $w 0) 0.0
       (+ (* (bit $w $b1) (* (bit $w $b2) (wt $w $formulas)))
          (marg2-from (- $w 1) $b1 $b2 $formulas))))


; Top-level inference queries
; Z       = partition function, used as the denominator for everything
; P-bit   = marginal probability that a single atom is true
; P-both  = joint probability that two atoms are both true
; P-cond  = conditional probability P(b1 | b2) = P(b1 and b2) / P(b2)
(= (Z $top $formulas) (z-from $top $formulas))

(= (P-bit  $b      $top $formulas)
   (/ (marg-from  $top $b      $formulas) (Z $top $formulas)))

(= (P-both $b1 $b2 $top $formulas)
   (/ (marg2-from $top $b1 $b2 $formulas) (Z $top $formulas)))

(= (P-cond $b1 $b2 $top $formulas)
   (/ (P-both $b1 $b2 $top $formulas) (P-bit $b2 $top $formulas)))


; Domain definition, smoking MLN from Richardson and Domingos Table I
; Bit layout for two people Anna and Bob:
;   0 Smokes(Anna)         1 Smokes(Bob)
;   2 Cancer(Anna)         3 Cancer(Bob)
;   4 Friends(Anna,Bob)    5 Friends(Bob,Anna)
; Six atoms means 2^6 = 64 possible worlds, top index = 63
;
; Two weighted formulas from the paper:
;   weight 1.5  Smokes(x) implies Cancer(x), grounded for Anna and Bob
;   weight 1.1  Friends(x,y) implies Smokes(x) iff Smokes(y), both directions
(= (smoking-mln)
   ( (1.5 (impl (atom 0) (atom 2)))
     (1.5 (impl (atom 1) (atom 3)))
     (1.1 (impl (atom 4) (iff (atom 0) (atom 1))))
     (1.1 (impl (atom 5) (iff (atom 1) (atom 0)))) ))


; Tests, all in one block at the end

!(println! "Markov Logic Network, smoking domain")
!(println! "")
!(println! "Marginal probabilities")
!(test ("P(Smokes Anna)       =" (P-bit 0 63 (smoking-mln))))
!(test ("P(Smokes Bob)        =" (P-bit 1 63 (smoking-mln))))
!(test ("P(Cancer Anna)       =" (P-bit 2 63 (smoking-mln))))
!(test ("P(Cancer Bob)        =" (P-bit 3 63 (smoking-mln))))
!(test ("P(Friends Anna Bob)  =" (P-bit 4 63 (smoking-mln))))
!(println! "")
!(println! "Conditional probabilities")
!(test ("P(Cancer Anna | Smokes Anna) =" (P-cond 2 0 63 (smoking-mln))))
!(test ("P(Cancer Bob   | Smokes Bob) =" (P-cond 3 1 63 (smoking-mln))))
!(test ("P(Smokes Bob | Smokes Anna and Friends Anna Bob) ="
           (/ (marg2-from 63 1 4 (smoking-mln))
              (marg2-from 63 0 4 (smoking-mln)))))