; Type Definition
(: Nil List)
(: Cons (-> $a List List))


; is_member
(= (is_member $x Nil) False)
(= (is_member $x (Cons $head $tail))
   (if (== $x $head) True (is_member $x $tail)))


; prepend
(= (prepend $x $list) (Cons $x $list))


; append
(= (append $x Nil) (Cons $x Nil))
(= (append $x (Cons $head $tail))
   (Cons $head (append $x $tail)))

; length
(= (length Nil) 0)
(= (length (Cons $head $tail))
   (+ 1 (length $tail)))


; Tests (3 per function)

; is_member tests
!(is_member 2 (Cons 1 (Cons 2 (Cons 3 Nil))))
!(is_member 99 (Cons 1 (Cons 2 (Cons 3 Nil))))
!(is_member 1 (Cons 1 Nil))

; prepend tests
!(prepend 0 (Cons 1 (Cons 2 Nil)))
!(prepend 5 Nil)
!(prepend 1 (Cons 2 (Cons 3 (Cons 4 Nil))))

; append tests
!(append 4 (Cons 1 (Cons 2 Nil)))
!(append 5 Nil)
!(append 3 (Cons 1 (Cons 2 (Cons 3 Nil))))

; length tests
!(length Nil)
!(length (Cons 1 (Cons 2 (Cons 3 Nil))))
!(length (Cons 10 (Cons 20 Nil)))