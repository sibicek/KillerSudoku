:- module(display, [display_grid/1, display_puzzle/1]).

:- use_module(utils).

% display_grid(+Grid)
% Prints a filled sudoku grid to stdout.
% Grid - NxN grid with values
display_grid(Grid) :-
    length(Grid, N),
    block_size(N, BR, BC),
    NumBlocks is N // BC,
    print_horizontal_line(BC, NumBlocks, N),
    display_rows(Grid, BR, BC, NumBlocks, N).

% display_rows(+Rows, +BR, +BC, +NumBlocks, +N)
% Prints rows in groups of BR, each group followed by a horizontal line.
% Rows      - remaining rows to display
% BR        - number of rows per block
% BC        - number of columns per block
% NumBlocks - number of blocks per row
% N         - grid size
display_rows([], _, _, _, _) :- !.
display_rows(Rows, BR, BC, NumBlocks, N) :-
    take_rows(Rows, BR, RowGroup, Rest),
    display_row_group(RowGroup, BC, N),
    print_horizontal_line(BC, NumBlocks, N),
    display_rows(Rest, BR, BC, NumBlocks, N).

% take_rows(+List, +Count, -Taken, -Rest)
% Splits List into first Count elements and the Rest.
% List  - input list
% Count - number of elements to take
% Taken - first Count elements
% Rest  - remaining elements
take_rows(List, Count, Taken, Rest) :-
    length(Taken, Count),
    append(Taken, Rest, List).

% display_row_group(+Rows, +BC, +N)
% Prints one horizontal band of rows (BR rows).
% Rows - rows to print
% BC   - number of columns per block
% N    - grid size
display_row_group([], _, _) :- !.
display_row_group([Row|Rows], BC, N) :-
    display_row(Row, 1, BC, N),
    nl,
    display_row_group(Rows, BC, N).

% display_row(+Row, +ColNum, +BC, +N)
% Prints one row with '| ' before each block boundary.
% For 12x12 adjusts single-digit numbers for alignment.
% Row    - remaining cells to print
% ColNum - current column number
% BC     - number of columns per block
% N      - grid size
display_row([], _, _, _) :- write('|'), !.
display_row([Cell|Rest], ColNum, BC, N) :-
    (ColNum mod BC =:= 1 -> write('| ') ; true),
    (N =:= 12
    -> (Cell < 10 
        -> format(' ~w ', [Cell]); 
           format('~w ', [Cell])); 
        format('~w ', [Cell])
    ),
    NewColNum is ColNum + 1,
    display_row(Rest, NewColNum, BC, N).

% print_horizontal_line(+BC, +NumBlocks, +N)
% Prints a horizontal separator line like '+-----+-----+'.
% BC        - number of columns per block
% NumBlocks - number of blocks per row
% N         - grid size
print_horizontal_line(BC, NumBlocks, N) :-
    write('+'),
    print_blocks(BC, NumBlocks, N).

% print_blocks(+BC, +Num, +N)
% Prints Num block segments, each as '----+'.
% 12x12 uses 3 dashes per cell (to fit 2-digit numbers),
% smaller grids use 2 dashes per cell.
% BC  - number of columns per block
% Num - remaining blocks to print
% N   - grid size
print_blocks(_, 0, _) :- nl, !.
print_blocks(BC, Num, N) :-
    (N =:= 12 -> Dashes is BC * 3 + 1 ; Dashes is BC * 2 + 1),
    forall(between(1, Dashes, _), write('-')),
    write('+'),
    N1 is Num - 1,
    print_blocks(BC, N1, N).

% print_horizontal_line_labels(+BC, +NumBlocks)
% Prints a horizontal separator line for the cage label grid.
% BC        - number of columns per block
% NumBlocks - number of blocks per row
print_horizontal_line_labels(BC, NumBlocks) :-
    write('+'),
    print_blocks_labels(BC, NumBlocks).

% print_blocks_labels(+BC, +Num)
% Same as print_blocks but always uses 3 dashes per cell.
% BC  - number of columns per block
% Num - remaining blocks to print
print_blocks_labels(_, 0) :- nl, !.
print_blocks_labels(BC, Num) :-
    Dashes is BC * 3 + 1,
    forall(between(1, Dashes, _), write('-')),
    write('+'),
    N1 is Num - 1,
    print_blocks_labels(BC, N1).

% display_puzzle(+N)
% Prints an unsolved puzzle - cage label grid followed by cage sums.
% Cages - list of cage(Sum, [(Row,Col), ...])
display_puzzle(Cages) :-
    grid_size_from_cages(Cages, N),
    block_size(N, BR, BC),
    NumBlocks is N // BC,
    assign_cage_labels(Cages, Labels),
    build_label_grid(N, Labels, LabelGrid),
    print_horizontal_line_labels(BC, NumBlocks),
    display_label_rows(LabelGrid, BR, BC, NumBlocks, N),
    nl,
    display_cage_sums(Labels).

% display_cage_sums(+Labels)
% Prints the sum for each labeled cage.
% Labels - list of (Label, Sum, Coords)
display_cage_sums([]).
display_cage_sums([(Label, Sum, _)|Rest]) :-
    format('Cage ~w: ~w~n', [Label, Sum]),
    display_cage_sums(Rest).

% assign_cage_labels(+Cages, -Labels)
% Assigns a unique two-character label (A0..Z9) to each cage.
% Cages  - list of cage(Sum, Coords)
% Labels - list of (Label, Sum, Coords)
assign_cage_labels(Cages, Labels) :-
    assign_cage_labels(Cages, 0, Labels).

% assign_cage_labels(+Cages, +Idx, -Labels)
% Recursive helper
% Cages  - remaining cages to label
% Idx    - current label index
% Labels - list of (Label, Sum, Coords)
assign_cage_labels([], _, []).
assign_cage_labels([cage(Sum, Coords)|Rest], Idx, [(Label, Sum, Coords)|Labels]) :-
    Letter is Idx // 10 + 65,
    Digit is Idx mod 10,
    char_code(Char, Letter),
    atom_concat(Char, Digit, Label),
    NextIdx is Idx + 1,
    assign_cage_labels(Rest, NextIdx, Labels).

% build_label_grid(+N, +Labels, -Grid)
% Builds NxN grid where each cell contains the label of its cage.
% N      - grid size
% Labels - list of (Label, Sum, Coords)
% Grid   - NxN grid of label atoms
build_label_grid(N, Labels, Grid) :-
    numlist(1, N, Rows),
    maplist(build_label_row(N, Labels), Rows, Grid).

% build_label_row(+N, +Labels, +R, -Row)
% Builds one row of cage labels for row R.
% N      - grid size
% Labels - list of (Label, Sum, Coords)
% R      - row index
% Row    - list of N cage labels for this row
build_label_row(N, Labels, R, Row) :-
    numlist(1, N, Cols),
    maplist(find_label(R, Labels), Cols, Row).

% find_label(+R, +Labels, +C, -Label)
% Returns the cage label for cell (R,C), or '?' if not found.
% R      - row index
% Labels - list of (Label, Sum, Coords)
% C      - column index
% Label  - cage label atom
find_label(R, Labels, C, Char) :-
    member((Char, _, Coords), Labels),
    member((R, C), Coords), !.
find_label(_, _, _, '?').

% display_label_rows(+Rows, +BR, +BC, +NumBlocks, +N)
% Prints label grid rows in groups of BR, each followed by a horizontal line.
% Rows      - remaining label rows to print
% BR        - rows per block
% BC        - columns per block
% NumBlocks - number of blocks per row
% N         - grid size
display_label_rows([], _, _, _, _) :- !.
display_label_rows(Rows, BR, BC, NumBlocks, N) :-
    take_rows(Rows, BR, RowGroup, Rest),
    display_label_row_group(RowGroup, BC, N),
    print_horizontal_line_labels(BC, NumBlocks),
    display_label_rows(Rest, BR, BC, NumBlocks, N).

% display_label_row_group(+Rows, +BC, +N)
% Prints one horizontal band of label rows.
% Rows - label rows to print
% BC   - columns per block (for separator placement)
% N    - grid size
display_label_row_group([], _, _) :- !.
display_label_row_group([Row|Rows], BC, N) :-
    display_label_row(Row, 1, BC, N),
    nl,
    display_label_row_group(Rows, BC, N).

% display_label_row(+Row, +ColNum, +BC, +N)
% Prints one row of cage labels with '| ' before each block boundary.
% Row    - remaining labels to print
% ColNum - current column number
% BC     - columns per block
% N      - grid size
display_label_row([], _, _, _) :- write('|'), !.
display_label_row([Cell|Rest], ColNum, BC, N) :-
    (ColNum mod BC =:= 1 -> write('| ') ; true),
    format('~w ', [Cell]),
    NewColNum is ColNum + 1,
    display_label_row(Rest, NewColNum, BC, N).