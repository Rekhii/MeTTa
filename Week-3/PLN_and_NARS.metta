; TV helpers
; A TV is a pair like (TV 0.6 0.8) holding strength and confidence

; Pull out the strength
(= (strength (TV $s $c)) $s)

; Pull out the confidence
(= (confidence (TV $s $c)) $c)

; Power is strength times confidence, the main number the paper compares
(= (power (TV $s $c)) (* $s $c))


; NARS deduction
; From A->B (f1 c1) and B->C (f2 c2) infer A->C
; f = f1 f2 / (f1 + f2 - f1 f2)
; c = c1 c2 (f1 + f2 - f1 f2)
(= (nars-deduction (TV $f1 $c1) (TV $f2 $c2))
   ; Save the shared overlap term once and reuse it for both numbers
   (let $overlap (- (+ $f1 $f2) (* $f1 $f2))
        (TV (/ (* $f1 $f2) $overlap)
            (* (* $c1 $c2) $overlap))))


; NARS induction
; From B->A (f1 c1) and B (f2 c2) infer A
; f = f1, confidence shrinks with experience parameter k
(= (nars-induction (TV $f1 $c1) (TV $f2 $c2) $k)
   (let $evidence (* (* $f2 $c2) $c1)
        (TV $f1 (/ $evidence (+ $evidence $k)))))


; NARS abduction
; From A->B (f1 c1) and B (f2 c2) infer A
; Mirror of induction, takes f2 instead of f1
(= (nars-abduction (TV $f1 $c1) (TV $f2 $c2) $k)
   (let $evidence (* (* $f1 $c1) $c2)
        (TV $f2 (/ $evidence (+ $evidence $k)))))


; PLN deduction independence based, full form
; Term probabilities sA sB sC supply the Bayes correction
; sAC = sAB sBC + ((1 - sAB)(sC - sB sBC)) / (1 - sB)
(= (pln-deduction-indep-full (TV $sAB $cAB) (TV $sBC $cBC) $sA $sB $sC)
   (TV
       ; First piece is the simple product, second piece is the correction
       (+ (* $sAB $sBC)
          (/ (* (- 1 $sAB) (- $sC (* $sB $sBC)))
             (- 1 $sB)))
       (* $cAB $cBC)))


; PLN deduction concept geometry, full form
; sAC = (sAB sBC) / min(1, sAB + sBC)
(= (pln-deduction-cg-full (TV $sAB $cAB) (TV $sBC $cBC))
   (let $sum (+ $sAB $sBC)
        (TV (/ (* $sAB $sBC) (if (< $sum 1) $sum 1))
            (* $cAB $cBC))))


; PLN induction full form
; Bayes inverts B->A to A->B then runs deduction
; sAB = sBA sB / sA
(= (pln-induction-full (TV $sBA $cBA) (TV $sBC $cBC) $sA $sB $sC)
   (pln-deduction-indep-full
       (TV (/ (* $sBA $sB) $sA) $cBA)
       (TV $sBC $cBC)
       $sA $sB $sC))


; PLN abduction full form
; Bayes inverts C->B to B->C then runs deduction
; sBC = sCB sC / sB
(= (pln-abduction-full (TV $sAB $cAB) (TV $sCB $cCB) $sA $sB $sC)
   (pln-deduction-indep-full
       (TV $sAB $cAB)
       (TV (/ (* $sCB $sC) $sB) $cCB)
       $sA $sB $sC))


; PLN simplified forms, for highly uncertain term probabilities
; The Bayes correction drops away, leaving simple products

(= (pln-deduction-simple (TV $sAB $cAB) (TV $sBC $cBC))
   (TV (* $sAB $sBC) (* $cAB $cBC)))

(= (pln-deduction-cg-simple (TV $sAB $cAB) (TV $sBC $cBC))
   (TV (/ (* $sAB $sBC) (+ $sAB $sBC))
       (* $cAB $cBC)))

(= (pln-induction-simple (TV $sBA $cBA) (TV $sBC $cBC))
   (TV (* $sBA $sBC) (* $cBA $cBC)))

(= (pln-abduction-simple (TV $sAB $cAB) (TV $sCB $cCB))
   (TV (* $sAB $sCB) (* $cAB $cCB)))


; Example 1, deduction
; Premises A->B (0.6, 0.8) and B->C (0.7, 0.9)
; Expected powers 0.3024, 0.2323, 0.3024
!(println! "Example 1, deduction")
; Run the simple PLN formula and print its power
!(test  ("PLN independence    :" (power (pln-deduction-simple    (TV 0.6 0.8) (TV 0.7 0.9)))))
; Run the simple concept geometry version, which divides by the strength sum
!(test  ("PLN concept geometry:" (power (pln-deduction-cg-simple (TV 0.6 0.8) (TV 0.7 0.9)))))
; Run the NARS rule for comparison
!(test  ("NARS                :" (power (nars-deduction          (TV 0.6 0.8) (TV 0.7 0.9)))))


; Example 2, induction
; Premises B->A (0.6, 0.8) and B (0.7, 0.9), experience k = 0.5
; Expected powers 0.3024 and 0.3014
!(println! "Example 2, induction")
; Simple PLN induction, ignores term probabilities
!(test  ("PLN                 :" (power (pln-induction-simple (TV 0.6 0.8) (TV 0.7 0.9)))))
; NARS induction needs the experience parameter k passed in
!(test  ("NARS                :" (power (nars-induction       (TV 0.6 0.8) (TV 0.7 0.9) 0.5))))


; Example 3, abduction
; Premises A->B (0.5, 0.7) and B (0.4, 0.6), experience k = 0.5
; Expected powers 0.084 and 0.1183
!(println! "Example 3, abduction")
; Simple PLN abduction
!(test  ("PLN                 :" (power (pln-abduction-simple (TV 0.5 0.7) (TV 0.4 0.6)))))
; NARS abduction with the same k as induction
!(test  ("NARS                :" (power (nars-abduction       (TV 0.5 0.7) (TV 0.4 0.6) 0.5))))


; Full PLN with confident term probabilities sA = 0.3, sB = 0.5, sC = 0.4
; Shows the divergence from NARS when term probabilities are well known
!(println! "Bonus, full PLN with confident term probabilities")
; Full deduction uses the Bayes correction term, so the answer shifts a bit
!(test  ("Full deduction      :" (power (pln-deduction-indep-full (TV 0.6 0.8) (TV 0.7 0.9) 0.3 0.5 0.4))))
; Full induction first flips B->A into A->B, then deduces, giving a much higher number
!(test  ("Full induction      :" (power (pln-induction-full       (TV 0.6 0.8) (TV 0.7 0.9) 0.3 0.5 0.4))))
; Full abduction flips C->B into B->C, then deduces, again diverging from NARS
!(test  ("Full abduction      :" (power (pln-abduction-full       (TV 0.5 0.7) (TV 0.4 0.6) 0.3 0.5 0.4))))