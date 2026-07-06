:- module(utils, [
    length_list/2,
    get_columns/2,
    get_blocks/2,
    cell_value/4,
    block_size/3,
    grid_size_from_cages/2
]).

% length_list(+N, ?List)
% Wrapper around length/2 with swapped arguments for use in maplist.
% N    - desired length
% List - list of length N
length_list(N, List) :-
    length(List, N).

% get_columns(+Grid, -Columns)
% Transposes a grid - extracts all columns from a list of rows.
% Grid    - list of lists (N rows x N columns)
% Columns - list of lists (N columns x N rows)
get_columns(Grid, Columns) :-
    Grid = [FirstRow|_],
    length(FirstRow, N),
    numlist(1, N, Indices),
    maplist(get_column(Grid), Indices, Columns).

% get_column(+Grid, +Idx, -Column)
% Extracts one column from the grid by taking the Idx-th element from each row.
% Grid   - NxN list of lists
% Idx    - column index 
% Column - list of values at position Idx in each row
get_column(Grid, Idx, Column) :-
    maplist(nth1(Idx), Grid, Column).

% get_blocks(+Grid, -Blocks)
% Splits grid into sub-blocks based on grid size.
% Grid   - list of lists (N rows x N columns)
% Blocks - list of blocks, each block is a flat list of N cells
get_blocks(Grid, Blocks) :-
    length(Grid, N),
    block_size(N, BR, BC),
    chunk(Grid, BR, RowChunks),
    maplist(get_col_blocks(BC), RowChunks, BlockGroups),
    flatten_one(BlockGroups, Blocks).

% chunk(+List, +Size, -Chunks)
% Splits a list into sublists of given size.
% List   - input list
% Size   - chunk size
% Chunks - list of sublists of length Size
chunk([], _, []).
chunk(List, Size, [Chunk|Rest]) :-
    length(Chunk, Size),
    append(Chunk, Tail, List),
    chunk(Tail, Size, Rest).

% get_col_blocks(+BC, +Rows, -Blocks)
% Extracts column blocks from a group of rows.
% BC     - block column count
% Rows   - group of BR rows
% Blocks - list of extracted blocks
get_col_blocks(BC, Rows, Blocks) :-
    Rows = [FirstRow|_],
    length(FirstRow, N),
    NumBlocks is N // BC,
    Last is NumBlocks - 1,
    numlist(0, Last, Indices),
    maplist(get_one_col_block(BC, Rows), Indices, Blocks).

% get_one_col_block(+BC, +Rows, +BlockIdx, -Block)
% Extracts a single block from a group of rows at given block index.
% BC       - number of columns per block
% Rows     - group of rows
% BlockIdx - 0-based block index
% Block    - flat list of cells in the block
get_one_col_block(BC, Rows, BlockIdx, Block) :-
    StartCol is BlockIdx * BC + 1,
    EndCol is StartCol + BC - 1,
    numlist(StartCol, EndCol, ColIndices),
    maplist(get_cells_from_row(ColIndices), Rows, RowParts),
    append(RowParts, Block).

% get_cells_from_row(+ColIndices, +Row, -Cells)
% Extracts cells at given column indices from a single row.
% ColIndices - list of 1-based column indices
% Row        - one row of the grid
% Cells      - values at the given indices
get_cells_from_row(ColIndices, Row, Cells) :-
    maplist(nth1_row(Row), ColIndices, Cells).

% nth1_row(+Row, +Idx, -Val)
% Helper for use in maplist - gets Idx-th element of Row.
nth1_row(Row, Idx, Val) :-
    nth1(Idx, Row, Val).

% flatten_one(+ListOfLists, -Flat)
% Flattens a list of lists by one level.
% ListOfLists - list of lists
% Flat        - concatenated flattened list
flatten_one([], []).
flatten_one([H|T], Result) :-
    flatten_one(T, Rest),
    append(H, Rest, Result).

% block_size(+N, -BlockRows, -BlockCols)
% Maps grid size to block dimensions.
% N         - grid size (4, 6, 9, or 12)
% BlockRows - number of rows per block
% BlockCols - number of columns per block
block_size(4,  2, 2).
block_size(6,  2, 3).
block_size(9,  3, 3).
block_size(12, 3, 4).

% cell_value(+Grid, +Row, +Col, -Value)
% Retrieves the value of a cell at given position.
% Grid   - list of lists (N rows x N columns)
% Row   - row index (1..N)
% Col   - column index (1..N)
% Value - value at that position
cell_value(Grid, Row, Col, Value) :-
    nth1(Row, Grid, RowList),
    nth1(Col, RowList, Value).

% grid_size_from_cages(+Cages, -N)
% Derives grid size from total cell count across all cages.
% Cages - list of cage(Sum, [(Row,Col), ...])
% N     - grid size
grid_size_from_cages(Cages, N) :-
    findall(Size, (member(cage(_, Coords), Cages), length(Coords, Size)), Sizes),
    sumlist(Sizes, TotalCells),
    N is round(sqrt(float(TotalCells))).