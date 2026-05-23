# Week 3 — PLN, NARS, and Markov Logic Networks in MeTTa

Implementations of three uncertain-reasoning frameworks in MeTTa, run through PeTTa (Prolog backend for MeTTa).

## Contents

### PLN_and_NARS
Implementation of deduction, induction, and abduction for two reasoning systems:
- **PLN** (Probabilistic Logic Networks) — uses (strength, confidence) on both terms and relationships
- **NARS** (Non-Axiomatic Reasoning System) — uses (frequency, confidence) on relationships only

Based on Goertzel (2024), *PLN and NARS Often Yield Similar strength × confidence Given Highly Uncertain Term Probabilities* (arXiv:2412.19524).

The MeTTa file implements:
- `nars-deduction`, `nars-induction`, `nars-abduction`
- `pln-deduction-indep-full`, `pln-deduction-cg-full`, `pln-induction-full`, `pln-abduction-full`
- Simplified PLN forms for the high term-probability-uncertainty regime
- Verification against the paper's three worked examples in Section 4

### MLN
Generic Markov Logic Network engine in MeTTa following Richardson and Domingos (2006). The engine is domain-independent:
- Formulas and weights are supplied as data
- Worlds are encoded as integers (one bit per ground atom)
- Inference is exact enumeration of `2^n` worlds, computing `P(x) = (1/Z) exp(Σ wᵢ nᵢ(x))`
- The smoking domain from Table I of the paper is included as a demo

## Running

PeTTa is required. With it installed at `~/PeTTa`:

```bash
sh ~/PeTTa/run.sh PLN_and_NARS/PLN_and_NARS.metta
sh ~/PeTTa/run.sh MLN/MLN.metta
```

Sample output for each is in `output/`.

## Results

### PLN vs NARS (Goertzel paper examples)

| Inference | PLN power | NARS power | Paper |
|---|---|---|---|
| Deduction (indep) | 0.3024 | 0.3024 | matches ✓ |
| Deduction (concept-geometry) | 0.2326 | — | matches paper's 0.2323 ✓ |
| Induction | 0.3024 | 0.3012 | matches paper's 0.3014 ✓ |
| Abduction | 0.084 | 0.1183 | matches ✓ |

Under highly uncertain term probabilities, PLN and NARS converge on similar power (strength × confidence) values. The bonus tests with confident term probabilities show the predicted divergence (Section 5.2 of the paper).

### MLN (smoking domain)

| Query | Probability |
|---|---|
| P(Smokes Anna) | 0.337 |
| P(Cancer Anna) | 0.607 |
| P(Friends Anna Bob) | 0.429 |
| P(Cancer Anna \| Smokes Anna) | 0.818 |
| P(Smokes Bob \| Smokes Anna, Friends Anna Bob) | 1.0 |

Smoking lifts cancer probability from 0.607 to 0.818 (weight 1.5 rule). The friends-similar-smoking rule (weight 1.1) tightly couples friends' smoking.
