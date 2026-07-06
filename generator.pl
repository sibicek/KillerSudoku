:- module(generator, [generate/3, generate/4, generate_random_grid/2]).

:- use_module(library(clpfd)).
:- use_module(utils).
:- use_module(solver).

% Suppress gen_timeout messages after the alarm is handled
:- multifile user:message_hook/3.
user:message_hook(gen_timeout, _, _) :- !.

% generate_random_grid(+N, -Grid)
% Generates a random valid Sudoku grid.
% N    - grid size (4, 6, 9, or 12)
% Grid - filled NxN grid
generate_random_grid(N, Grid) :-
    length(Grid, N),
    maplist(length_list(N), Grid),
    append(Grid, AllCells),
    AllCells ins 1..N,
    maplist(all_distinct, Grid),
    get_columns(Grid, Columns),
    maplist(all_distinct, Columns),
    get_blocks(Grid, Blocks),
    maplist(all_distinct, Blocks),
    random_permutation(AllCells, Shuffled),
    labeling([ffc], Shuffled),
    !.

% generate(+N, +Difficulty, -Cages)
% Generates a Killer Sudoku puzzle.
% N          - grid size (4, 6, 9, or 12)
% Difficulty - easy, medium, or hard
% Cages      - list of cage(Sum, [(Row,Col), ...])
generate(N, Difficulty, Cages) :-
    generate(N, Difficulty, Cages, _).

% generate(+N, +Difficulty, -Cages, -Grid)
% Generates a Killer Sudoku puzzle, also returning the solution grid.
% Tries to find a unique puzzle within 15 seconds.
% If not found in time, returns a puzzle without uniqueness guaranteed.
% N          - grid size (4, 6, 9, or 12)
% Difficulty - easy, medium, or hard
% Cages      - list of cage(Sum, [(Row,Col), ...])
% Grid       - solution grid the puzzle was built from
generate(N, Difficulty, Cages, Grid) :-
    difficulty_to_cage_size(Difficulty, MaxSize),
    catch(
        (   alarm(15, throw(gen_timeout), AlarmId),
            generate_loop(N, MaxSize, Cages, Grid),
            remove_alarm(AlarmId)
        ),
        gen_timeout,
        (   write('Uniqueness not guaranteed'), nl,
            generate_random_grid(N, Grid),
            generate_cages(N, Grid, MaxSize, RawCages),
            compute_cage_sums(Grid, RawCages, Cages)
        )
    ),
    !.

% generate_loop(+N, +MaxSize, -Cages, -Grid)
% Keeps generating puzzles until a unique one is found.
% N       - grid size
% MaxSize - maximum cage size
% Cages   - generated cages
% Grid    - solution grid
generate_loop(N, MaxSize, Cages, Grid) :-
    repeat,
        generate_once(N, MaxSize, Grid, Cages),
        (   is_unique(N, Grid, Cages)
        ->  write('Uniqueness guaranteed!'), nl, !
        ;   fail
        ).

% generate_once(+N, +MaxSize, -Grid, -Cages)
% Generates one puzzle without checking uniqueness.
% N       - grid size
% MaxSize - maximum cage size
% Grid    - solution grid
% Cages   - generated cages
generate_once(N, MaxSize, Grid, Cages) :-
    generate_random_grid(N, Grid),
    generate_cages(N, Grid, MaxSize, RawCages),
    compute_cage_sums(Grid, RawCages, Cages).

% is_unique(+N, +Grid, +Cages)
% Succeeds if Grid is the only valid solution for the puzzle.
% N     - grid size
% Grid  - solution grid
% Cages - list of cage(Sum, [(Row,Col), ...])
is_unique(N, Grid, Cages) :-
    is_valid(N, Grid, Cages),
    \+ (solve_helper(N, Cages, Sol2), Sol2 \== Grid).

% difficulty_to_cage_size(+Difficulty, -MaxSize)
% Maps difficulty level to maximum cage size.
% Difficulty - easy, medium, or hard
% MaxSize    - maximum cage size
difficulty_to_cage_size(easy,   2).
difficulty_to_cage_size(medium, 3).
difficulty_to_cage_size(hard,   4).

% generate_cages(+N, +Grid, +MaxSize, -Cages)
% Splits all grid cells into connected groups (cages) of at most MaxSize cells.
% No two cells in the same cage can have the same value.
% N       - grid size
% Grid    - solution grid
% MaxSize - maximum cage size
% Cages   - list of cages (without sums)
generate_cages(N, Grid, MaxSize, Cages) :-
    numlist(1, N, Ns),
    findall((R,C), (member(R, Ns), member(C, Ns)), AllCoords),
    random_permutation(AllCoords, Shuffled),
    assign_cages(Shuffled, MaxSize, Grid, Cages).

% assign_cages(+Unassigned, +MaxSize, +Grid, -Cages)
% Recursively assigns all unassigned cells to cages.
% Unassigned - remaining cells to assign
% MaxSize    - max cells per cage
% Grid       - solution grid
% Cages      - list of cages
assign_cages([], _, _, []) :- !.
assign_cages([First|Rest], MaxSize, Grid, [Cage|Cages]) :-
    assign_cage(First, [First], Rest, MaxSize, Grid, Cage, Remaining),
    assign_cages(Remaining, MaxSize, Grid, Cages).

% assign_cage(+Last, +Current, +Available, +MaxSize, +Grid, -Cage, -Remaining)
% Builds one cage by repeatedly adding adjacent cells to Current.
% Stops when MaxSize is reached or no valid neighbours are left.
% Last      - last added cell
% Current   - cells in the cage so far
% Available - unassigned cells
% MaxSize   - max cells per cage
% Grid      - solution grid
% Cage      - finished cage
% Remaining - cells still unassigned after this cage
assign_cage(_, Cage, Available, MaxSize, _, Cage, Available) :-
    length(Cage, MaxSize), !.
assign_cage(Last, Cage, Available, MaxSize, Grid, FinalCage, FinalRemaining) :-
    find_adjacent(Last, Available, Adjacent),
    include(no_duplicate(Grid, Cage), Adjacent, ValidAdjacent),
    (   ValidAdjacent = []
    ->  FinalCage = Cage, FinalRemaining = Available
    ;   random_member(Next, ValidAdjacent),
        delete(Available, Next, NewAvailable),
        append(Cage, [Next], NewCage),
        assign_cage(Next, NewCage, NewAvailable, MaxSize, Grid, FinalCage, FinalRemaining)
    ).

% no_duplicate(+Grid, +Cage, +(R,C))
% Checks that cell (R,C) doesnt share a value with any cell already in Cage.
% Grid - solution grid
% Cage - current cage cells
% (R,C) - candidate cell to add
no_duplicate(Grid, Cage, (R,C)) :-
    get_cell_value(Grid, (R,C), Value),
    \+ (member((R2,C2), Cage), get_cell_value(Grid, (R2,C2), Value)).

% find_adjacent(+(R,C), +Available, -Adjacent)
% Returns all cells from Available that are next to (R,C).
% (R,C)     - reference cell
% Available - list of unassigned cells
% Adjacent  - cells from Available touching (R,C) horizontally or vertically
find_adjacent((R,C), Available, Adjacent) :-
    findall(N, (
        member(N, Available),
        (N = (R1,C), R1 is R+1 ;
         N = (R1,C), R1 is R-1 ;
         N = (R,C1), C1 is C+1 ;
         N = (R,C1), C1 is C-1)
    ), Adjacent).

% get_cell_value(+Grid, +(R,C), -Value)
% Wrapper around cell_value/4
% Grid  - solution grid
% (R,C) - reference cell
% Value - value at that cell
get_cell_value(Grid, (R,C), Value) :-
    cell_value(Grid, R, C, Value).

% compute_cage_sums(+Grid, +RawCages, -Cages)
% Calculates the target sum for each cage from the solution grid.
% Grid     - solution grid
% RawCages - list of cages (without sums)
% Cages    - list of cage(Sum, [(Row,Col), ...])
compute_cage_sums(_, [], []) :- !.
compute_cage_sums(Grid, [Coords|Rest], [cage(Sum, Coords)|Cages]) :-
    maplist(get_cell_value(Grid), Coords, Values),
    sumlist(Values, Sum),
    compute_cage_sums(Grid, Rest, Cages).