#!/usr/bin/env bash

./preCalculate.sh

./benchmarkCalculator ../raw_benches/sudoku_sm.csv bench_sudoku_sm True
cp bench-sudoku-sm.bench.* ../content/benchmarks/sudoku-sm

originalBenchmarks=(
    "bench-sudoku-sm.bench.eden-sudoku-sudoku17.1000.txt.csv"
    "bench-sudoku-sm.bench.eden-sudoku-sudoku17.16000.txt.csv"
    "bench-sudoku-sm.bench.multicore-sudoku-sudoku17.1000.txt.csv"
    "bench-sudoku-sm.bench.multicore-sudoku-sudoku17.16000.txt.csv"
    "bench-sudoku-sm.bench.parmonad-sudoku-sudoku17.1000.txt.csv"
    "bench-sudoku-sm.bench.parmonad-sudoku-sudoku17.16000.txt.csv"
)

parrowsBenchmarks=(
    "bench-sudoku-sm.bench.parrows-sudoku-parmap-eden-sudoku17.1000.txt.csv"
    "bench-sudoku-sm.bench.parrows-sudoku-parmap-eden-sudoku17.16000.txt.csv"
    "bench-sudoku-sm.bench.parrows-sudoku-parmap-mult-sudoku17.1000.txt.csv"
    "bench-sudoku-sm.bench.parrows-sudoku-parmap-mult-sudoku17.16000.txt.csv"
    "bench-sudoku-sm.bench.parrows-sudoku-parmap-par-sudoku17.1000.txt.csv"
    "bench-sudoku-sm.bench.parrows-sudoku-parmap-par-sudoku17.16000.txt.csv"
)

outFileNames=(
    "eden-cp-1000-diff.csv"
    "eden-cp-16000-diff.csv"
    "mult-1000-diff.csv"
    "mult-16000-diff.csv"
    "par-1000-diff.csv"
    "par-16000-diff.csv"
)

displayNames=(
    "\"Eden CP vs. PArrows 1000\""
    "\"Eden CP vs. PArrows 16000\""
    "\"GpH vs. PArrows 1000\""
    "\"GpH vs. PArrows 16000\""
    "\"Par Monad vs. PArrows 1000\""
    "\"Par Monad vs. PArrows 16000\""
)

vs=(
    "\"Eden CP\""
    "\"Eden CP\""
    "\"GpH\""
    "\"GpH\""
    "\"Par Monad \""
    "\"Par Monad \""
)

params=(
    "\"1000\""
    "\"16000\""
    "\"1000\""
    "\"16000\""
    "\"1000\""
    "\"16000\""
)

benchmark="\"Sudoku (Shared-Memory)\""

bestAndWorstFileName=(
    "bestAndWorstSudoku-1000.csv"
    "bestAndWorstSudoku-16000.csv"
    "bestAndWorstSudoku-1000.csv"
    "bestAndWorstSudoku-16000.csv"
    "bestAndWorstSudoku-1000.csv"
    "bestAndWorstSudoku-16000.csv"
)

outputFolder="../content/benchmarks/sudoku-sm"

count=${#originalBenchmarks[@]}

for i in $(seq 0 $(expr ${count} - 1));
do
    cp header.txt ${bestAndWorstFileName[i]}
done

for i in $(seq 0 $(expr ${count} - 1));
do
    ./calculateDifferences ${originalBenchmarks[i]} ${parrowsBenchmarks[i]} ${outFileNames[i]}
    cp ${outFileNames[i]} ${outputFolder}

    echo -n "${benchmark},${vs[i]},${params[i]},${displayNames[i]}," >> ${bestAndWorstFileName[i]}
    ./calculateDifferences ${originalBenchmarks[i]} ${parrowsBenchmarks[i]} ${bestAndWorstFileName[i]} True
done


for i in $(seq 0 $(expr ${count} - 1));
do
    cp ${bestAndWorstFileName[i]} ${outputFolder}
done

rm *.csv