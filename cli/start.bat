@ECHO OFF
SETLOCAL
SET datadir=..\data\
SET tank_params=%datadir%tank_params.csv
SET tank_prod=%datadir%tank_prod.csv
SET result_params=%datadir%result_params.csv
SET result_prod=%datadir%result_prod.csv
julia --project=.. main.jl --options options.toml --tank_params %tank_params% --tank_prod %tank_prod% --result_params %result_params% --result_prod %result_prod%
PAUSE