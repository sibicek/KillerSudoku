# Killer Sudoku

A set of tools for working with Killer Sudoku puzzles in Prolog — a variant of classic Sudoku extended with cage constraints. Includes a solver, puzzle generator and difficulty rater.

## Requirements

- [SWI-Prolog](https://www.swi-prolog.org/download) (tested on version 9.1.3)

## Running the program

Open SWI-Prolog console and load the main file:

```prolog
?- consult('killer_sudoku.pl').
```

On startup you will see:
```
=== Killer Sudoku Solver, Generator and Difficulty Rater ===

Available commands:
  play(N, Difficulty)               - generate, display and solve a puzzle
  generate(N, Difficulty, Cages)    - generate a puzzle
  solve_puzzle(Cages, Solution)     - solve a given puzzle
  display_grid(Solution)            - display a solved grid
  display_puzzle(Cages)             - display a puzzle with cage labels
  grade(Cages, Difficulty)          - estimate puzzle difficulty

Grid sizes: 4, 6, 9, 12
Difficulty: easy, medium, hard

Example: play(9, medium).

```

## Commands

### `play(N, Difficulty)`

Generates, displays and solves a Killer Sudoku puzzle in one step.

**Example:**

```prolog
?- play(4, hard).
```

**Possible output:**

```
Generating 4x4 Killer Sudoku (hard)...
Uniqueness guaranteed!
Puzzle:
+-------+-------+
| A4 A1 | A1 A1 |
| A4 A3 | A3 A1 |
+-------+-------+
| A0 A3 | A5 A2 |
| A0 A0 | A0 A2 |
+-------+-------+
Cage A0: 10
Cage A1: 10
Cage A2: 3
Cage A3: 9
Cage A4: 5
Cage A5: 3
Solving...
Solution:
+-----+-----+
| 4 2 | 1 3 |
| 1 3 | 2 4 |
+-----+-----+
| 2 4 | 3 1 |
| 3 1 | 4 2 |
+-----+-----+
Requested difficulty: hard
Estimated difficulty: hard

```

----------

### `generate(N, Difficulty, Cages)`

Generates a new Killer Sudoku puzzle and returns its cages.

**Example:**

```prolog
?- generate(6, hard, Cages), display_puzzle(Cages).
```

**Possible output:**

```
Uniqueness guaranteed!
+----------+----------+
| A6 A6 A8 | A8 A0 A0 |
| A6 B1 A3 | A3 A0 A0 |
+----------+----------+
| A6 A3 A3 | A1 A1 A9 |
| A4 A4 A5 | A5 A1 A9 |
+----------+----------+
| A4 A4 A5 | A5 A1 A2 |
| B0 A7 A7 | A2 A2 A2 |
+----------+----------+
Cage A0: 14
Cage A1: 14
Cage A2: 17
Cage A3: 15
Cage A4: 15
Cage A5: 14
Cage A6: 13
Cage A7: 5
Cage A8: 11
Cage A9: 3
Cage B0: 3
Cage B1: 2
Cages = [cage(14, [(2, 6), (1, 6), (1, 5), (2, 5)]), cage(14, [(5, 5), (4, 5), (3, 5), (3, 4)]), cage(17, [(5, 6), (6, 6), (6, 5), (6, 4)]), cage(15, [(2, 4), (2, 3), (3, 3), (…, …)]), cage(15, [(4, 2), (5, 2), (…, …)|…]), cage(14, [(4, 4), (…, …)|…]), cage(13, [(…, …)|…]), cage(5, […|…]), cage(…, …)|…].

```

----------

### `solve_puzzle(Cages, Solution)`

Solves a given Killer Sudoku puzzle.

**Example:**

```prolog
?- solve_puzzle([
     cage(3, [(1,1),(1,2)]),
     cage(7, [(1,3),(1,4)]),
     cage(7, [(2,1),(2,2)]),
     cage(3, [(2,3),(2,4)]),
     cage(3, [(3,1),(3,2)]),
     cage(7, [(3,3),(3,4)]),
     cage(7, [(4,1),(4,2)]),
     cage(3, [(4,3),(4,4)])
   ], Sol), display_grid(Sol).
```

**Output:**

```
+-----+-----+
| 1 2 | 3 4 |
| 3 4 | 1 2 |
+-----+-----+
| 2 1 | 4 3 |
| 4 3 | 2 1 |
+-----+-----+
Sol = [[1, 2, 3, 4], [3, 4, 1, 2], [2, 1, 4, 3], [4, 3, 2, 1]].
```

If no solution exists, returns `no_solution`:
```prolog
?- solve_puzzle([cage(999, [(1,1)])], Sol).
Sol = no_solution.
```

### `grade(Cages, Difficulty)`

Estimates the difficulty of a puzzle.

**Example:**

```prolog
?- generate(12, easy, Cages), grade(Cages, D).
```
**Possible output:**
```
Uniqueness guaranteed!
Cages = [cage(16, [(12, 4), (11, 4)]), cage(19, [(8, 10), (8, 11)]), cage(5, [(12, 2), (11, 2)]), cage(7, [(4, 7), (5, 7)]), cage(14, [(6, 9), (6, 10)]), cage(11, [(2, 9), (…, …)]), cage(7, [(…, …)|…]), cage(16, […|…]), cage(…, …)|…],
D = easy.
```

----------

### `display_grid(Solution)`

Displays a solved grid.

**Example:**
```prolog
?- Grid = [[1,2,3,4],[3,4,1,2],[2,1,4,3],[4,3,2,1]], display_grid(Grid).
```
**Output:**
```
+-----+-----+
| 1 2 | 3 4 |
| 3 4 | 1 2 |
+-----+-----+
| 2 1 | 4 3 |
| 4 3 | 2 1 |
+-----+-----+
```

----------

### `display_puzzle(Cages)`

Displays a puzzle with cage labels and sums.

**Example:**
```prolog
?- generate(9, medium, Cages), display_puzzle(Cages).
```
**Possible Output:**
```
Uniqueness guaranteed!
+----------+----------+----------+
| C3 C1 C7 | B4 B4 C2 | B7 B7 C9 |
| C0 C1 C1 | B4 D1 C2 | B8 B7 C9 |
| C0 B6 B6 | B6 A8 A4 | B8 B8 D3 |
+----------+----------+----------+
| C0 A0 A0 | A8 A8 A4 | A2 A2 A2 |
| C4 A0 A6 | A6 D4 A4 | D5 A9 D6 |
| B0 B0 A6 | D2 A3 B1 | B1 A9 A9 |
+----------+----------+----------+
| B0 B5 A7 | A3 A3 C6 | B1 B3 B3 |
| A1 A1 A7 | A7 C5 A5 | A5 A5 B3 |
| D0 A1 C8 | B9 B9 B9 | B2 B2 B2 |
+----------+----------+----------+

Cage A0: 14
Cage A1: 20
Cage A2: 17
Cage A3: 12
Cage A4: 13
...
```

----------

## Cage format

Cages are specified as a list of `cage(Sum, Coords)` where `Coords` is a list of `(Row, Col)` :

```prolog
cage(15, [(1,1),(1,2),(2,1)])
```

This means: cells at row 1 col 1, row 1 col 2, and row 2 col 1 must sum to 15.

## Known limitations

-   Uniqueness verification uses a 15-second timeout. For large grids (12x12) or hard difficulty, uniqueness may not always be guaranteed.
-   Solver performance for 12x12 hard puzzles may be slow due to the size of the search space.
