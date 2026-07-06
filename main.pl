:- module(main, [play/2, generate/3, solve_puzzle/2, display_grid/1, display_puzzle/1, grade/2]).

:- use_module(solver).
:- use_module(generator).
:- use_module(difficulty).
:- use_module(display).

% play(+N, +Difficulty)
% Generates, displays and solves a Killer Sudoku puzzle, then prints the solution and difficulty rating.
% N          - grid size (4, 6, 9, or 12)
% Difficulty - easy, medium, or hard
play(N, Difficulty) :-
    format('~nGenerating ~wx~w Killer Sudoku (~w)...~n', [N, N, Difficulty]),
    generate(N, Difficulty, Cages),
    nl,
    write('Puzzle:'), nl,
    display_puzzle(Cages),
    nl,
    write('Solving...'), nl,
    solve_puzzle(Cages, Solution),
    (   Solution = no_solution
    ->  write('No solution found!'), nl
    ;   write('Solution:'), nl,
        display_grid(Solution),
        nl,
        grade(Cages, Grade),
        format('Requested difficulty: ~w~n', [Difficulty]),
        format('Estimated difficulty: ~w~n', [Grade])
    ).