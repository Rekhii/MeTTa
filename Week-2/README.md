# Week 2 - Genetic Algorithm for 0/1 Knapsack Problem

## Overview
Implementation of a Genetic Algorithm (GA) in MeTTa language to solve
the classic 0/1 Knapsack Problem, with a Python version for comparison.

## Problem Description
The 0/1 Knapsack Problem:
- Given 5 items each with a weight and value
- Knapsack has a maximum capacity of 15
- Goal: maximize total value without exceeding capacity
- Each item is either taken (1) or left (0)

## Items
| Item | Weight | Value |
|------|--------|-------|
|  0   |   2    |   6   |
|  1   |   3    |  10   |
|  2   |   4    |  12   |
|  3   |   5    |  13   |
|  4   |   9    |  18   |

**Capacity = 15**

## GA Components Implemented

### 1. Chromosome Encoding
- Binary string of length 5
- Bit i = 1 means item i is selected
- Bit i = 0 means item i is not selected

### 2. Fitness Function
- Returns total value if weight <= capacity
- Returns 0 if weight exceeds capacity (penalty)

### 3. Tournament Selection
- Pick 2 chromosomes
- Return the one with higher fitness

### 4. 1-Point Crossover
- cross2: split after position 2
- cross3: split after position 3
- Uses structural pattern matching in MeTTa

### 5. Mutation
- Flip a single bit at a given position

### 6. Elitism
- Best chromosome from current generation
  is always kept in next generation

## Files
| File | Description |
|------|-------------|
| `knapsack_ga.metta` | GA implementation in MeTTa language |
| `knapsack_ga.py`    | GA implementation in Python (matches MeTTa output) |
| `Knapsack_GA.pdf`   | Reference tutorial - Whitley GA Tutorial |

## How to Run

### MeTTa
```bash
# Make sure hyperon is installed
pip install hyperon

# Run the MeTTa implementation
metta knapsack_ga.metta
```

### Python
```bash
python knapsack_ga.py
```

## Results

| Generation | Best Chromosome | Fitness | Weight | Value |
|------------|----------------|---------|--------|-------|
| Gen 0      | [1,0,1,0,1]    |   36    |   15   |  36   |
| Gen 1      | [1,1,1,1,0]    |   41    |   14   |  41   |
| Gen 2      | [1,1,1,1,0]    |   41    |   14   |  41   |

## Optimal Solution Found

Chromosome : [1, 1, 1, 1, 0]

Items      : 0, 1, 2, 3

Weight     : 14 / 15

Value      : 41  (OPTIMAL)

## MeTTa vs Python Comparison
Both implementations produce identical results:
- Same tournament selection winners
- Same crossover children
- Same mutation results
- Same optimal solution

## Key Learning
MeTTa is a nondeterministic language by nature.
To avoid duplicate outputs, crossover was implemented
using structural pattern matching instead of
list splitting functions.

## References
- Whitley, D. "A Genetic Algorithm Tutorial"
- MeTTa Language: https://metta-lang.dev
- Hyperon: https://github.com/trueagi-io/hyperon-experimental