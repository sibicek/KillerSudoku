:- module(solver, [solve_puzzle/2, find_all_solutions/3, solve_helper/3, is_valid/3, check_cage/2]).

:- use_module(library(clpfd)).
:- use_module(utils).

% solve_puzzle(+Cages, -Solution)
% Solves a Killer Sudoku puzzle.
% Cages    - list of cage(Sum, [(Row,Col), ...])
% Solution - NxN list of lists with solution, or atom no_solution
solve_puzzle(Cages, Solution) :-
    grid_size_from_cages(Cages, N),
    (   once(solve_helper(N, Cages, Solution))
    ->  true
    ;   Solution = no_solution
    ).

% solve_helper(+N, +Cages, -Solution)
% Core solving predicate using constraint propagation.
% Fails if no solution exists.
% N        - grid size
% Cages    - list of cage(Sum, [(Row,Col), ...])
% Solution - NxN list of lists
solve_helper(N, Cages, Solution) :-
    % Create NxN grid of CLP(FD) variables with domain 1..N
    length(Solution, N),
    maplist(length_list(N), Solution),
    append(Solution, AllCells),
    AllCells ins 1..N,

    % Classic Sudoku constraints - rows, columns, blocks
    maplist(all_distinct, Solution),
    get_columns(Solution, Columns),
    maplist(all_distinct, Columns),
    get_blocks(Solution, Blocks),
    maplist(all_distinct, Blocks),

    % Killer Sudoku constraints - cage sums and uniqueness
    maplist(apply_cage(Solution), Cages),

    % Label variables using first-fail heuristic
    labeling([ffc], AllCells).

% apply_cage(+Grid, +Cage)
% Applies sum and uniqueness constraints for one cage.
% Grid - NxN list of CLP(FD) variables
% Cage - cage(Sum, [(Row,Col), ...])
apply_cage(Grid, cage(Sum, Coords)) :-
    maplist(cell_value_from_grid(Grid), Coords, Cells),
    sum(Cells, #=, Sum),
    all_distinct(Cells).

% cell_value_from_grid(+Grid, +(Row,Col), -Value)
% Retrieves CLP(FD) variable at (Row,Col).
% Grid        - NxN list of CLP(FD) variables
% (Row, Col)  - position
% Value       - CLP(FD) variable at that position
cell_value_from_grid(Grid, (Row, Col), Value) :-
    cell_value(Grid, Row, Col, Value).

% is_valid(+N, +Grid, +Cages)
% Checks that a filled grid satisfies all sudoku and cage constraints.
% N     - grid size (unused, kept for interface consistency)
% Grid  - filled NxN grid
% Cages - list of cage(Sum, [(Row,Col), ...])
is_valid(_N, Grid, Cages) :-
    maplist(all_distinct, Grid),
    get_columns(Grid, Columns),
    maplist(all_distinct, Columns),
    get_blocks(Grid, Blocks),
    maplist(all_distinct, Blocks),
    maplist(check_cage(Grid), Cages).

% check_cage(+Grid, +Cage)
% Checks that cage cells sum to the target and contain no duplicates.
% Grid - filled NxN grid
% Cage - cage(Sum, [(Row,Col), ...])
check_cage(Grid, cage(Sum, Coords)) :-
    maplist(get_cell(Grid), Coords, Values),
    sumlist(Values, ActualSum),
    ActualSum =:= Sum,
    sort(Values, Sorted),
    length(Values, Len),
    length(Sorted, Len).

% get_cell(+Grid, +(R,C), -Value)
% Gets the value at position (R,C) in the grid.
% Grid  - filled NxN grid
% (R,C) - position
% Value - value at that position
get_cell(Grid, (R,C), Value) :-
    nth1(R, Grid, Row),
    nth1(C, Row, Value).

% find_all_solutions(+N, +Cages, -Solutions)
% Finds all solutions for a puzzle - used to verify uniqueness.
% N         - grid size
% Cages     - list of cage(Sum, [(Row,Col), ...])
% Solutions - list of all valid solutions
find_all_solutions(N, Cages, Solutions) :-
    findall(Solution, solve_helper(N, Cages, Solution), Solutions).