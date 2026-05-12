import random


# Problem definition
# Each item has a weight and a value. The chromosome is a binary list
# where bit i = 1 means item i is included in the knapsack.
Items = [
    {"name": "item0", "weight": 2, "value": 6},
    {"name": "item1", "weight": 3, "value": 10},
    {"name": "item2", "weight": 4, "value": 12},
    {"name": "item3", "weight": 5, "value": 13},
    {"name": "item4", "weight": 9, "value": 18},
]
Capacity = 15
Num_items = len(Items)


# GA hyperparameters
# These control the behavior of the evolution. Tuning them changes
# the balance between exploration (trying new solutions) and
# exploitation (refining good solutions).
Population_size = 6      # Number of chromosomes in each generation
Num_generations = 30     # How many generations to evolve
Tournament_size = 3      # How many candidates compete in each tournament
Crossover_rate = 0.8     # Probability that two parents will crossover
Mutation_rate = 0.10     # Probability that each bit will flip
Elitism_count = 1        # Number of top chromosomes preserved unchanged

# Fixed seed for reproducibility. Remove or change this value to get
# different runs. Seed 7 produces a clear evolution from low fitness
# initial population to the optimum in about 2 generations.
random.seed(7)


# Fitness functions
# These evaluate how good a chromosome is. The fitness function
# returns 0 for invalid solutions (over capacity) so the GA learns
# to avoid them through selection pressure.

def total_weight(chromosome):
    # Sum the weights of all selected items (where bit = 1)
    return sum(c * item["weight"] for c, item in zip(chromosome, Items))


def total_value(chromosome):
    # Sum the values of all selected items (where bit = 1)
    return sum(c * item["value"] for c, item in zip(chromosome, Items))


def fitness(chromosome):
    # Penalty-based fitness: invalid solutions get fitness 0
    # This means tournament selection will rarely pick them
    if total_weight(chromosome) > Capacity:
        return 0
    return total_value(chromosome)


# Population initialization
# The starting population is generated randomly. With a small population
# this might give a poor starting point, which is what makes evolution
# interesting to watch.

def random_chromosome():
    # Generate a random 5-bit chromosome with each bit equally likely 0 or 1
    return [random.randint(0, 1) for _ in range(Num_items)]


def initial_population(size):
    # Build a list of random chromosomes for the starting generation
    return [random_chromosome() for _ in range(size)]


# Genetic operators
# These three operators (selection, crossover, mutation) are the heart
# of every GA. Together they implement the search through the space
# of possible solutions.

def tournament_selection(population, k=Tournament_size):
    # Pick k random chromosomes from the population
    # Return whichever one has the highest fitness
    # Higher k = stronger selection pressure (less diversity)
    contestants = random.sample(population, k)
    return max(contestants, key=fitness)


def crossover(parent1, parent2):
    # Single-point crossover combines two parents to make two children
    # Sometimes (with probability 1 - Crossover_rate) parents pass through
    # unchanged, which preserves diversity in the population
    if random.random() > Crossover_rate:
        return parent1[:], parent2[:]

    # Pick a random crossover point between bit 1 and bit 4
    # (point 0 or 5 would mean no actual crossover happened)
    point = random.randint(1, Num_items - 1)

    # Child 1 gets first half from parent 1, second half from parent 2
    # Child 2 gets the opposite
    child1 = parent1[:point] + parent2[point:]
    child2 = parent2[:point] + parent1[point:]
    return child1, child2


def mutate(chromosome):
    # Each bit has an independent chance of flipping
    # This introduces small random changes that help the GA escape
    # local optima and explore new regions of the search space
    return [
        (1 - bit) if random.random() < Mutation_rate else bit
        for bit in chromosome
    ]


# Generation evolution
# This function builds the next generation from the current one
# using selection, crossover, and mutation. Elitism ensures the
# best solution found so far is never lost.

def evolve(population):
    # Elitism: copy the top N chromosomes directly to the next generation
    # This guarantees fitness never decreases between generations
    sorted_pop = sorted(population, key=fitness, reverse=True)
    new_population = sorted_pop[:Elitism_count]

    # Fill the rest of the new population with offspring
    while len(new_population) < len(population):
        # Select two parents using tournament selection
        parent1 = tournament_selection(population)
        parent2 = tournament_selection(population)

        # Apply crossover to produce two children
        child1, child2 = crossover(parent1, parent2)

        # Apply mutation to each child independently
        child1 = mutate(child1)
        child2 = mutate(child2)

        # Add children to new population
        new_population.append(child1)
        if len(new_population) < len(population):
            new_population.append(child2)

    return new_population


# Reporting helpers
# These functions print the GA's progress so we can see what's
# happening during evolution. Useful for debugging and analysis.

def print_chromosome(label, chrom):
    # Print a single chromosome with its fitness, weight, value, and items
    selected = [i for i, b in enumerate(chrom) if b == 1]
    print(f"  {label}: {chrom}  fit={fitness(chrom):3d}  "
          f"w={total_weight(chrom):3d}  v={total_value(chrom):3d}  "
          f"items={selected}")


def print_population_summary(gen, population):
    # Print summary statistics for one generation
    # Best fitness shows progress, average shows population diversity
    fits = [fitness(c) for c in population]
    best = max(population, key=fitness)
    avg = sum(fits) / len(fits)
    print(f"\n# Generation {gen:2d}")
    print(f"  Best fitness: {max(fits):3d}    "
          f"Avg fitness: {avg:5.1f}    "
          f"Worst: {min(fits):3d}")
    print_chromosome("  Best", best)


# Main GA driver
# This runs the full algorithm: initialize, evolve for N generations,
# track the best ever solution, and print the final result.

def run_ga():
    # Print configuration so the user knows what hyperparameters were used
    print("# Genetic Algorithm - 0/1 Knapsack Problem")
    print(f"Items: {Num_items}    Capacity: {Capacity}")
    print(f"Population size: {Population_size}    "
          f"Generations: {Num_generations}")
    print(f"Tournament size: {Tournament_size}    "
          f"Crossover: {Crossover_rate}    "
          f"Mutation: {Mutation_rate}")

    # Print the items so the user can see the problem instance
    print("\n# Items")
    for i, item in enumerate(Items):
        print(f"  item{i}: weight={item['weight']:2d}  value={item['value']:2d}")

    # Generate the starting population
    population = initial_population(Population_size)

    print("\n# Initial Population")
    for i, c in enumerate(population):
        print_chromosome(f"chrom{i}", c)

    # Track the best chromosome ever seen across all generations
    # This is separate from the current population's best because
    # mutation could theoretically lose a good solution (though
    # elitism prevents this in our implementation)
    best_ever = max(population, key=fitness)
    best_history = [fitness(best_ever)]

    # Main evolution loop
    # Each iteration creates a new generation from the previous one
    for gen in range(1, Num_generations + 1):
        # Apply selection, crossover, and mutation to evolve
        population = evolve(population)

        # Update best ever if current generation found something better
        gen_best = max(population, key=fitness)
        if fitness(gen_best) > fitness(best_ever):
            best_ever = gen_best[:]
        best_history.append(fitness(best_ever))

        # Print progress every 5 generations plus the first and last
        # This keeps the output readable for long runs
        if gen == 1 or gen % 5 == 0 or gen == Num_generations:
            print_population_summary(gen, population)

    # Print final result
    # The optimal solution for this problem instance is fitness 41
    # achieved by selecting items 0, 1, 2, 3 (weight 14, value 41)
    print("\n# Final Best Solution")
    print_chromosome("Best", best_ever)
    selected = [Items[i]['name'] for i, b in enumerate(best_ever) if b == 1]
    print(f"  Selected items: {selected}")
    print(f"  Total value:    {total_value(best_ever)}")
    print(f"  Total weight:   {total_weight(best_ever)} / {Capacity}")
    print(f"  Fitness:        {fitness(best_ever)}")
    print(f"  Optimal (41)?   {fitness(best_ever) == 41}")

    # Show the convergence trajectory so the user can see how
    # quickly the GA improved over generations
    print("\n# Best Fitness Over Time")
    print("  " + " -> ".join(str(f) for f in best_history))


if __name__ == "__main__":
    run_ga()