:- module(difficulty, [grade/2]).

:- use_module(utils).
:- use_module(solver).

% grade(+Cages, -Difficulty)
% Estimates puzzle difficulty based on three factors: avg cage size, number of cages, and solver inference count.
% Cages      - list of cage(Sum, [(Row,Col), ...])
% Difficulty - easy, medium, or hard
grade(Cages, Difficulty) :-
    length(Cages, NumCages),
    compute_avg_cage_size(Cages, AvgSize),
    grid_size_from_cages(Cages, N),
    statistics(inferences, Before),
    (solve_helper(N, Cages, _) -> true ; true),
    statistics(inferences, After),
    Inferences is After - Before,
    compute_score(AvgSize, NumCages, N, Inferences, Score),
    score_to_difficulty(Score, Difficulty).

% compute_avg_cage_size(+Cages, -AvgSize)
% Computes average cage size (number of cells per cage).
% Cages   - list of cage(Sum, [(Row,Col), ...])
% AvgSize - average cage size
compute_avg_cage_size(Cages, AvgSize) :-
    findall(Size, (member(cage(_, Coords), Cages), length(Coords, Size)), Sizes),
    length(Sizes, Count),
    sumlist(Sizes, Total),
    AvgSize is Total / Count.

% compute_score(+AvgSize, +NumCages, +N, +Inferences, -Score)
% Combines three factors into a difficulty score between 0.0 and 1.0.
%   F1 (40%) - avg cage size normalized by N
%   F2 (30%) - fewer cages means less info for the solver
%   F3 (30%) - log of solver inferences normalized per grid size
% AvgSize    - average cage size
% NumCages   - total number of cages
% N          - grid size
% Inferences - solver inferences measured during solving
% Score      - difficulty score in [0.0, 1.0]
compute_score(AvgSize, NumCages, N, Inferences, Score) :-
    MaxCages is N * N,
    MaxCageSize is float(N),

    F1 is min(1.0, AvgSize / MaxCageSize),
    F2 is max(0.0, 1.0 - (NumCages / float(MaxCages))),

    baseline_log(N, Baseline, Range),
    LogInf is log(float(max(1, Inferences))),
    F3 is min(1.0, max(0.0, (LogInf - Baseline) / Range)),

    Score is 0.4 * F1 + 0.3 * F2 + 0.3 * F3.

% baseline_log(+N, -Baseline, -Range)
% Expected log(inferences) interval for each grid size.
% Easy puzzles score near Baseline, hard puzzles near Baseline + Range.
% N        - grid size
% Baseline - log(inferences) for easy puzzle
% Range    - span to hard puzzle
baseline_log(4,  6.0,  3.0).
baseline_log(6,  10.0, 3.5).
baseline_log(9,  13.5, 5.5).
baseline_log(12, 17.0, 6.0).

% score_to_difficulty(+Score, -Difficulty)
% Maps numeric score to difficulty category.
% Score      - value in [0.0, 1.0]
% Difficulty - easy, medium, or hard
score_to_difficulty(Score, easy)   :- Score =< 0.35, !.
score_to_difficulty(Score, medium) :- Score =< 0.60, !.
score_to_difficulty(_, hard).