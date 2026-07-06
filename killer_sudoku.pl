:- use_module(main).

:- initialization(print_welcome).

% Prints welcome message and available commands on startup.
print_welcome :-
    nl,
    write('=== Killer Sudoku Solver, Generator and Difficulty Rater ==='), nl,
    nl,
    write('Available commands:'), nl,
    write('  play(N, Difficulty)               - generate, display and solve a puzzle'), nl,
    write('  generate(N, Difficulty, Cages)    - generate a puzzle'), nl,
    write('  solve_puzzle(Cages, Solution)     - solve a given puzzle'), nl,
    write('  display_grid(Solution)            - display a solved grid'), nl,
    write('  display_puzzle(Cages)             - display a puzzle with cage labels'), nl,
    write('  grade(Cages, Difficulty)          - estimate puzzle difficulty'), nl,
    nl,
    write('Grid sizes: 4, 6, 9, 12'), nl,
    write('Difficulty: easy, medium, hard'), nl,
    nl,
    write('Example: play(9, medium).'), nl,
    nl.