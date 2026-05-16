import random
import sys

sys.setrecursionlimit(10000)

# 1. PROBLEM DATA
# Items, capacity, and mutation rate are data, not hardcoded
# in the GA engine. Change these to solve a different instance.
ITEMS = [(2, 6), (3, 10), (4, 12), (5, 13), (9, 18)]  # (weight, value)
CAPACITY = 15
MUTATION_RATE = 0.30  # 30%


# 2. FITNESS
# Returns 0 if total weight exceeds capacity.
def total_weight(chrom):
    return sum(bit * w for bit, (w, _) in zip(chrom, ITEMS))


def total_value(chrom):
    return sum(bit * v for bit, (_, v) in zip(chrom, ITEMS))


def fitness(chrom):
    if total_weight(chrom) > CAPACITY:
        return 0
    return total_value(chrom)


# 3. CROSSOVER (single-point, any chromosome length)
def crossover(p1, p2, k):
    return p1[:k] + p2[k:]


# 4. MUTATION (recursive, binary genes)
def mutate_helper(chrom, target, i):
    """Recursively flip the bit at position target."""
    if not chrom:
        return []
    if i == target:
        return [1 - chrom[0]] + chrom[1:]
    return [chrom[0]] + mutate_helper(chrom[1:], target, i + 1)


def mutate(chrom, pos):
    return mutate_helper(chrom, pos, 0)


# 5. SELECTION (tournament across whole population)
def tournament(a, b):
    return a if fitness(a) >= fitness(b) else b


def tournament_select(pop, rng):
    """Pick two random chromosomes from the whole population,
    return the fitter one."""
    a = rng.choice(pop)
    b = rng.choice(pop)
    return tournament(a, b)


# 6. EVOLUTION
def best_of_pop(pop):
    """Recursively find the best chromosome in the population."""
    if len(pop) == 1:
        return pop[0]
    return tournament(pop[0], best_of_pop(pop[1:]))


def make_child(pop, L, rng):
    """Tournament-select 2 parents, random crossover point,
    probabilistic mutation."""
    p1 = tournament_select(pop, rng)
    p2 = tournament_select(pop, rng)
    k = rng.randint(1, L - 1)
    child = crossover(p1, p2, k)
    if rng.random() < MUTATION_RATE:
        pos = rng.randint(0, L - 1)
        child = mutate(child, pos)
    return child


def build_children(pop, n, L, rng):
    """Recursively build n new children."""
    if n <= 0:
        return []
    return [make_child(pop, L, rng)] + build_children(pop, n - 1, L, rng)


def evolve_pop(pop, rng):
    """One generation with elitism. Edge-safe."""
    if not pop:
        return []
    L = len(pop[0])
    if L < 2:
        return pop
    best = best_of_pop(pop)
    children = build_children(pop, len(pop) - 1, L, rng)
    return [best] + children


# 7. RECURSIVE GA LOOP
def run_ga(pop, n, rng):
    """Recursive GA loop."""
    if n <= 0:
        return pop
    return run_ga(evolve_pop(pop, rng), n - 1, rng)


def run_ga_traced(pop, n, rng, total=None):
    """Same as run_ga but prints best fitness per generation."""
    if total is None:
        total = n
    if n <= 0:
        return pop
    new_pop = evolve_pop(pop, rng)
    gen_num = total - n + 1
    best_fit = fitness(best_of_pop(new_pop))
    print(f"  gen {gen_num:2d}  best-fit = {best_fit}")
    return run_ga_traced(new_pop, n - 1, rng, total)


# 8. INITIAL POPULATION
# Deliberately excludes the optimum [1,1,1,1,0] (fitness 41).
# Each chromosome has partial good genes; the GA must combine
# them through crossover and mutation to discover the optimum.
def init_pop():
    return [
        [1, 1, 0, 0, 0],  # items 0,1   weight 5  value 16
        [0, 0, 1, 1, 0],  # items 2,3   weight 9  value 25
        [1, 0, 0, 0, 1],  # items 0,4   weight 11 value 24
        [0, 1, 1, 0, 0],  # items 1,2   weight 7  value 22
        [1, 0, 1, 0, 0],  # items 0,2   weight 6  value 18
        [0, 1, 0, 1, 0],  # items 1,3   weight 8  value 23
        [0, 0, 1, 0, 1],  # items 2,4   weight 13 value 30
        [1, 0, 0, 1, 0],  # items 0,3   weight 7  value 19
    ]


# 9. TESTS
def run_tests():
    print("=== TESTS ===")
    print(f"test-1-fit-optimal     : {fitness([1, 1, 1, 1, 0])}")
    print(f"test-1-fit-overweight  : {fitness([1, 1, 1, 1, 1])}")
    print(f"test-2-crossover       : {crossover([1, 1, 1, 0, 0], [1, 1, 0, 1, 0], 3)}")
    print(f"test-3-mutate-pos-2    : {mutate([1, 0, 1, 0, 1], 2)}")

    pop = init_pop()
    print(f"test-4-pop-size        : {len(pop)}")
    print(f"test-4-chrom-len       : {len(pop[0])}")
    print(f"test-4-initial-best    : {best_of_pop(pop)}")
    print(f"test-4-initial-fit     : {fitness(best_of_pop(pop))}")
    print(f"test-4-mutation-rate   : {int(MUTATION_RATE * 100)}%")

    print(f"test-5-empty-pop-safe  : {evolve_pop([], random.Random(42))}")
    print()


# 10. MAIN
# Single GA run, reused for all outputs.
def main():
    run_tests()

    pop = init_pop()
    print("=== MAIN RUN ===")
    print(f"population-size       : {len(pop)}")
    print(f"chromosome-length     : {len(pop[0])}")
    print(f"mutation-rate-percent : {int(MUTATION_RATE * 100)}")
    print(f"initial-best-fitness  : {fitness(best_of_pop(pop))}")
    print()

    generations = 30
    seed = 42
    print(f"=== Traced GA seed {seed} for {generations} generations ===")
    rng = random.Random(seed)
    final_pop = run_ga_traced(pop, generations, rng)

    best = best_of_pop(final_pop)
    print()
    print("=== Final Results ===")
    print(f"final-best     : {best}")
    print(f"final-fitness  : {fitness(best)}")
    print(f"final-weight   : {total_weight(best)} / {CAPACITY}")
    print(f"final-value    : {total_value(best)}")


if __name__ == "__main__":
    main()