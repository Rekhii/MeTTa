; Type Definition
(: Zero Peano)
(: Succ (-> Peano Peano))


; Convert Arabic to Peano
(= (to-peano $n)
   (if (== $n 0) Zero (Succ (to-peano (- $n 1)))))


; Convert Peano to Arabic
(= (from-peano Zero) 0)
(= (from-peano (Succ $n))
   (+ 1 (from-peano $n)))


; Addition
(= (peano-add Zero $m) $m)
(= (peano-add (Succ $n) $m)
   (Succ (peano-add $n $m)))


; Subtraction
(= (pred (Succ $n)) $n)
(= (peano-sub $n $m)
   (if (== $n Zero) Zero
   (if (== $m Zero) $n
   (peano-sub (pred $n) (pred $m)))))


; Tests (3 per function)

; to-peano tests
!(to-peano 0)
!(to-peano 3)
!(to-peano 5)

; from-peano tests
!(from-peano Zero)
!(from-peano (Succ (Succ Zero)))
!(from-peano (Succ (Succ (Succ Zero))))

; peano-add tests
!(let $r (peano-add (to-peano 0) (to-peano 3)) (from-peano $r))
!(let $r (peano-add (to-peano 2) (to-peano 3)) (from-peano $r))
!(let $r (peano-add (to-peano 4) (to-peano 4)) (from-peano $r))

; peano-sub tests
!(let $r (peano-sub (to-peano 5) (to-peano 3)) (from-peano $r))
!(let $r (peano-sub (to-peano 3) (to-peano 3)) (from-peano $r))
!(let $r (peano-sub (to-peano 2) (to-peano 5)) (from-peano $r))