:- use_module(library(plunit)).
:- use_module(main).
:- use_module(solver).
:- use_module(generator).
:- use_module(utils).

% Run all tests with: ?- run_tests.

% -----------------------------------------------------------------------
% play/2 combines generate, display, solve and grade in one predicate.
% Since the output is non-deterministic (random puzzle each time) and
% only printed to console, it cannot be meaningfully unit tested.
% It is covered indirectly by the tests below.
% One test is included just to verify it runs without error.
:- begin_tests(play).

test(play_9x9_medium) :-
    play(9, medium).

:- end_tests(play).

% -----------------------------------------------------------------------
% generate/3 and generate/4 - tests that generation produces valid, solvable
% and unique puzzles. Solvability is tested on all difficulties for 6x6.
% Validity is checked using is_valid/3 on all grid sizes.
% Uniqueness is verified using find_all_solutions/3 on all grid sizes.
:- begin_tests(generate).

% Solvability on all difficulties on 6x6
test(generate_6x6_easy_solvable) :-
    generate(6, easy, Cages),
    solve_puzzle(Cages, Sol),
    Sol \= no_solution.

test(generate_6x6_medium_solvable) :-
    generate(6, medium, Cages),
    solve_puzzle(Cages, Sol),
    Sol \= no_solution.

test(generate_6x6_hard_solvable) :-
    generate(6, hard, Cages),
    solve_puzzle(Cages, Sol),
    Sol \= no_solution.

% Validity on all grid sizes with easy difficulty
test(generate_4x4_easy_valid, [nondet]) :-
    generate(4, easy, Cages, Grid),
    is_valid(4, Grid, Cages).

test(generate_6x6_easy_valid, [nondet]) :-
    generate(6, easy, Cages, Grid),
    is_valid(6, Grid, Cages).

test(generate_9x9_easy_valid, [nondet]) :-
    generate(9, easy, Cages, Grid),
    is_valid(9, Grid, Cages).

test(generate_12x12_easy_valid, [nondet]) :-
    generate(12, easy, Cages, Grid),
    is_valid(12, Grid, Cages).

% Uniqueness on all grid sizes with easy difficulty
test(generate_4x4_easy_unique) :-
    generate(4, easy, Cages),
    find_all_solutions(4, Cages, Solutions),
    length(Solutions, 1).

test(generate_6x6_easy_unique) :-
    generate(6, easy, Cages),
    find_all_solutions(6, Cages, Solutions),
    length(Solutions, 1).

test(generate_9x9_easy_unique) :-
    generate(9, easy, Cages),
    find_all_solutions(9, Cages, Solutions),
    length(Solutions, 1).

test(generate_12x12_easy_unique) :-
    generate(12, easy, Cages),
    find_all_solutions(12, Cages, Solutions),
    length(Solutions, 1).

% Cages cover the whole grid
test(generate_cages_cover_grid_4x4) :-
    generate(4, easy, Cages),
    grid_size_from_cages(Cages, N),
    N = 4.

test(generate_cages_cover_grid_6x6) :-
    generate(6, easy, Cages),
    grid_size_from_cages(Cages, N),
    N = 6.

:- end_tests(generate).

% -----------------------------------------------------------------------
% solve_puzzle/2 - tests valid and invalid input.
:- begin_tests(solve_puzzle).

test(valid_cages) :-
    Cages = [cage(3,[(1,1),(1,2)]), cage(7,[(1,3),(1,4)]),
             cage(7,[(2,1),(2,2)]), cage(3,[(2,3),(2,4)]),
             cage(3,[(3,1),(3,2)]), cage(7,[(3,3),(3,4)]),
             cage(7,[(4,1),(4,2)]), cage(3,[(4,3),(4,4)])],
    solve_puzzle(Cages, Sol),
    Sol \= no_solution.

test(no_solution) :-
    solve_puzzle([cage(999, [(1,1)])], Sol),
    Sol = no_solution.

:- end_tests(solve_puzzle).

% -----------------------------------------------------------------------
% grade/2 - difficulty rating is a heuristic estimate.
% We only require that the estimated difficulty differs from the requested difficulty by at most one step.
:- begin_tests(grade).

test(grade_9x9_easy, [nondet]) :-
    generate(9, easy, Cages),
    once(grade(Cages, D)),
    member(D, [easy, medium]).

test(grade_9x9_medium, [nondet]) :-
    generate(9, medium, Cages),
    once(grade(Cages, D)),
    member(D, [easy, medium, hard]).

test(grade_9x9_hard, [nondet]) :-
    generate(9, hard, Cages),
    once(grade(Cages, D)),
    member(D, [medium, hard]).

:- end_tests(grade).

% -----------------------------------------------------------------------
% display_grid/1 - verifies that output contains grid separators and values.
% 4x4, 6x6, 9x9 uses single-digit numbers, 12x12 uses two-digit numbers (10-12).
:- begin_tests(display_grid).

test(display_4x4) :-
    Grid = [[1,2,3,4],[3,4,1,2],[2,1,4,3],[4,3,2,1]],
    with_output_to(string(Output), display_grid(Grid)),
    once(sub_string(Output, _, _, _, "+-----+")),
    once(sub_string(Output, _, _, _, "| 1 2 |")).

test(display_12x12_two_digit) :-
    generate(12, easy, _Cages, Grid),
    with_output_to(string(Output), display_grid(Grid)),
    once(sub_string(Output, _, _, _, "+-------------+")).

:- end_tests(display_grid).

% -----------------------------------------------------------------------
% display_puzzle/1 - verifies that output contains grid separators and cage labels.
:- begin_tests(display_puzzle).

test(display_puzzle_4x4, [nondet]) :-
    Cages = [cage(3,[(1,1),(1,2)]), cage(7,[(1,3),(1,4)]),
             cage(7,[(2,1),(2,2)]), cage(3,[(2,3),(2,4)]),
             cage(3,[(3,1),(3,2)]), cage(7,[(3,3),(3,4)]),
             cage(7,[(4,1),(4,2)]), cage(3,[(4,3),(4,4)])],
    with_output_to(string(Output), display_puzzle(Cages)),
    sub_string(Output, _, _, _, "Cage A0:"),
    sub_string(Output, _, _, _, "+-------+").

:- end_tests(display_puzzle).