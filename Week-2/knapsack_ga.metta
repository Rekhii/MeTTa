; # Problem Definition
; Each item has a weight and a value. The chromosome is a 5-bit list
; where bit i = 1 means item i is included in the knapsack.

(= (item-weight 0) 2)
(= (item-weight 1) 3)
(= (item-weight 2) 4)
(= (item-weight 3) 5)
(= (item-weight 4) 9)

(= (item-value 0) 6)
(= (item-value 1) 10)
(= (item-value 2) 12)
(= (item-value 3) 13)
(= (item-value 4) 18)

; Maximum weight the knapsack can hold
(= (cap) 15)


; # Total Weight
; Recursively sums the weights of all selected items.
; Walks the chromosome list, multiplying each bit by its item's weight.
; Index $i tracks which item we are currently looking at.

(= (tw Nil $i) 0)

(= (tw (Cons $b $t) $i)
   (+ (* $b (item-weight $i))
      (tw $t (+ $i 1))))


; # Total Value
; Same structure as total-weight but sums values instead.
; Bit = 1 means add the value, bit = 0 means add zero.

(= (tv Nil $i) 0)

(= (tv (Cons $b $t) $i)
   (+ (* $b (item-value $i))
      (tv $t (+ $i 1))))


; # Fitness Function
; Returns 0 for invalid solutions (over capacity), otherwise returns
; the total value. This penalty approach makes the GA learn to avoid
; invalid solutions through selection pressure.

(= (fit $c)
   (if (> (tw $c 0) (cap))
       0
       (tv $c 0)))


; # Tournament Selection
; Compares two chromosomes and returns the one with higher fitness.
; This is the simplest form of tournament selection (size 2).

(= (tournament $c1 $c2)
   (if (>= (fit $c1) (fit $c2))
       $c1
       $c2))


; # Mutation
; Flips a single bit at a specified position in the chromosome.
; Helps the GA escape local optima by introducing small random changes.

; Bit-flip helpers: flip 0 to 1 and 1 to 0
(= (fl 0) 1)
(= (fl 1) 0)

; Recursive walk that flips the bit when current index matches target
(= (mut Nil $pos $cur) Nil)

(= (mut (Cons $h $t) $pos $cur)
   (if (== $cur $pos)
       (Cons (fl $h) $t)
       (Cons $h (mut $t $pos (+ $cur 1)))))

; Public mutation function: starts the recursive walk at index 0
(= (mutate $c $pos)
   (mut $c $pos 0))


; # Crossover at Point 2
;
; Splits both parents after position 2 and swaps tails.
; Pattern matching destructures both 5-bit parents at once,
; avoiding the nondeterminism of generic list operations.
;
; p1 = [a, b, c, d, e]
; p2 = [f, g, h, i, j]
;
; child A = [a, b, h, i, j]   (first 2 from p1, last 3 from p2)
; child B = [f, g, c, d, e]   (first 2 from p2, last 3 from p1)

(= (cross2-a
      (Cons $a (Cons $b (Cons $c (Cons $d (Cons $e Nil)))))
      (Cons $f (Cons $g (Cons $h (Cons $i (Cons $j Nil))))))
   (Cons $a (Cons $b (Cons $h (Cons $i (Cons $j Nil))))))

(= (cross2-b
      (Cons $a (Cons $b (Cons $c (Cons $d (Cons $e Nil)))))
      (Cons $f (Cons $g (Cons $h (Cons $i (Cons $j Nil))))))
   (Cons $f (Cons $g (Cons $c (Cons $d (Cons $e Nil))))))


; # Crossover at Point 3
;
; Same idea as cross2 but splits after position 3.
;
; p1 = [a, b, c, d, e]
; p2 = [f, g, h, i, j]
;
; child A = [a, b, c, i, j]   (first 3 from p1, last 2 from p2)
; child B = [f, g, h, d, e]   (first 3 from p2, last 2 from p1)

(= (cross3-a
      (Cons $a (Cons $b (Cons $c (Cons $d (Cons $e Nil)))))
      (Cons $f (Cons $g (Cons $h (Cons $i (Cons $j Nil))))))
   (Cons $a (Cons $b (Cons $c (Cons $i (Cons $j Nil))))))

(= (cross3-b
      (Cons $a (Cons $b (Cons $c (Cons $d (Cons $e Nil)))))
      (Cons $f (Cons $g (Cons $h (Cons $i (Cons $j Nil))))))
   (Cons $f (Cons $g (Cons $h (Cons $d (Cons $e Nil))))))


; # Best of 4 Chromosomes
;
; Finds the fittest chromosome in a population of 4.
; Uses two tournaments then a final tournament between the winners.
; Like a single elimination bracket.
;
; Population format: (Cons c1 (Cons c2 (Cons c3 (Cons c4 Nil))))

(= (best4
      (Cons $a
      (Cons $b
      (Cons $c
      (Cons $d Nil)))))
   (tournament
      (tournament $a $b)
      (tournament $c $d)))


; # Initial Chromosomes
; Four hand-picked starting chromosomes representing different
; potential solutions to demonstrate how the GA evolves them.
;
; c1 = [1,0,1,0,1] items 0,2,4 weight=15 value=36 (at capacity)
; c2 = [0,1,1,1,0] items 1,2,3 weight=12 value=35
; c3 = [1,1,1,0,0] items 0,1,2 weight=9  value=28
; c4 = [1,1,0,1,0] items 0,1,3 weight=10 value=29

(= (c1)
   (Cons 1 (Cons 0 (Cons 1 (Cons 0 (Cons 1 Nil))))))

(= (c2)
   (Cons 0 (Cons 1 (Cons 1 (Cons 1 (Cons 0 Nil))))))

(= (c3)
   (Cons 1 (Cons 1 (Cons 1 (Cons 0 (Cons 0 Nil))))))

(= (c4)
   (Cons 1 (Cons 1 (Cons 0 (Cons 1 (Cons 0 Nil))))))


; # Initial Population
; Wraps the four starting chromosomes into a single population list.

(= (pop0)
   (Cons (c1)
   (Cons (c2)
   (Cons (c3)
   (Cons (c4) Nil)))))


; # Next Generation with Elitism
;
; Builds the next population from the current one. Strategy:
;   - Slot 1: best chromosome from current population (elitism)
;   - Slot 2: child from cross2-a applied to first two parents
;   - Slot 3: child from cross2-b applied to first two parents
;   - Slot 4: child from cross3-b applied to last two parents
;
; Elitism guarantees the best fitness never decreases between generations.

(= (next-gen4
      (Cons $a
      (Cons $b
      (Cons $c
      (Cons $d Nil)))))
   (Cons (best4
           (Cons $a
           (Cons $b
           (Cons $c
           (Cons $d Nil)))))
   (Cons (cross2-a $a $b)
   (Cons (cross2-b $a $b)
   (Cons (cross3-b $d $c)
         Nil)))))


; # Generation Chain
; Each generation is built from the previous one by applying next-gen4.

(= (pop1) (next-gen4 (pop0)))
(= (pop2) (next-gen4 (pop1)))


; # Print Initial Population
; Show all four starting chromosomes with their fitness, weight, and value.

!(println! (# Initial Population))

!(println! (c1 (c1) fit= (fit (c1)) w= (tw (c1) 0) v= (tv (c1) 0)))
!(println! (c2 (c2) fit= (fit (c2)) w= (tw (c2) 0) v= (tv (c2) 0)))
!(println! (c3 (c3) fit= (fit (c3)) w= (tw (c3) 0) v= (tv (c3) 0)))
!(println! (c4 (c4) fit= (fit (c4)) w= (tw (c4) 0) v= (tv (c4) 0)))


; # Test Tournament
; Verify that tournament selection picks the higher-fitness chromosome.

!(println! (# Test Tournament))

!(println! (winner-c1-vs-c2
             (tournament (c1) (c2))
             fit= (fit (tournament (c1) (c2)))))

!(println! (winner-c3-vs-c4
             (tournament (c3) (c4))
             fit= (fit (tournament (c3) (c4)))))


; # Test Crossover
; Verify that crossover produces valid offspring from each parent pair.

!(println! (# Test Crossover))

!(println! (cross2-a-c1-c2
             (cross2-a (c1) (c2))
             fit= (fit (cross2-a (c1) (c2)))
             w= (tw (cross2-a (c1) (c2)) 0)
             v= (tv (cross2-a (c1) (c2)) 0)))

!(println! (cross2-b-c1-c2
             (cross2-b (c1) (c2))
             fit= (fit (cross2-b (c1) (c2)))
             w= (tw (cross2-b (c1) (c2)) 0)
             v= (tv (cross2-b (c1) (c2)) 0)))

!(println! (cross3-a-c4-c3
             (cross3-a (c4) (c3))
             fit= (fit (cross3-a (c4) (c3)))
             w= (tw (cross3-a (c4) (c3)) 0)
             v= (tv (cross3-a (c4) (c3)) 0)))

!(println! (cross3-b-c4-c3
             (cross3-b (c4) (c3))
             fit= (fit (cross3-b (c4) (c3)))
             w= (tw (cross3-b (c4) (c3)) 0)
             v= (tv (cross3-b (c4) (c3)) 0)))


; # Test Mutation
; Verify that mutation flips a single bit at the specified position.

!(println! (# Test Mutation))

!(println! (mutate-c1-pos0
             (mutate (c1) 0)
             fit= (fit (mutate (c1) 0))
             w= (tw (mutate (c1) 0) 0)
             v= (tv (mutate (c1) 0) 0)))

!(println! (mutate-c1-pos3
             (mutate (c1) 3)
             fit= (fit (mutate (c1) 3))
             w= (tw (mutate (c1) 3) 0)
             v= (tv (mutate (c1) 3) 0)))


; # Best of Population 0
; The fittest chromosome in the starting population.

!(println! (# Best Pop0))

!(println! (best-pop0 (best4 (pop0))))
!(println! (best-pop0-fitness (fit (best4 (pop0)))))
!(println! (best-pop0-weight (tw (best4 (pop0)) 0)))
!(println! (best-pop0-value (tv (best4 (pop0)) 0)))


; # Population 1
; First generation of evolution. Should show the optimum emerging
; via crossover.

!(println! (# Pop1))

!(println! (pop1 (pop1)))
!(println! (best-pop1 (best4 (pop1))))
!(println! (best-pop1-fitness (fit (best4 (pop1)))))
!(println! (best-pop1-weight (tw (best4 (pop1)) 0)))
!(println! (best-pop1-value (tv (best4 (pop1)) 0)))


; # Population 2
; Second generation. Elitism keeps the best from pop1.

!(println! (# Pop2))

!(println! (pop2 (pop2)))
!(println! (best-pop2 (best4 (pop2))))
!(println! (best-pop2-fitness (fit (best4 (pop2)))))
!(println! (best-pop2-weight (tw (best4 (pop2)) 0)))
!(println! (best-pop2-value (tv (best4 (pop2)) 0)))


; # Final Best Solution
; The optimal solution for this problem instance is fitness 41,
; achieved by chromosome [1,1,1,1,0] which selects items 0, 1, 2, 3
; with total weight 14 and total value 41.

!(println! (# Final Best Solution))

!(println! (best-chromosome (best4 (pop1))))
!(println! (best-fitness (fit (best4 (pop1)))))
!(println! (best-weight (tw (best4 (pop1)) 0)))
!(println! (best-value (tv (best4 (pop1)) 0)))
!(println! (items-selected item0=1 item1=1 item2=1 item3=1 item4=0))