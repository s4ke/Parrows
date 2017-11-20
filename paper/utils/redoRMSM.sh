#!/usr/bin/env bash

./benchmarkCalculator ../raw_benches/bench_sm_rm.csv bench_sm_rm True
cp bench-sm-rm.bench.* ../content/benchmarks/sm-rm

originalBenchmarks=(
    "bench-sm-rm.bench.skelrm-eden-cp-11213-32.csv"
    "bench-sm-rm.bench.skelrm-eden-cp-11213-64.csv"
    "bench-sm-rm.bench.skelrm-mult-11213-32.csv"
    "bench-sm-rm.bench.skelrm-mult-11213-64.csv"
    "bench-sm-rm.bench.skelrm-par-11213-32.csv"
    "bench-sm-rm.bench.skelrm-par-11213-64.csv"
)

parrowsBenchmarks=(
    "bench-sm-rm.bench.skelrm-parr-eden-cp-11213-32.csv"
    "bench-sm-rm.bench.skelrm-parr-eden-cp-11213-64.csv"
    "bench-sm-rm.bench.skelrm-parr-mult-11213-32.csv"
    "bench-sm-rm.bench.skelrm-parr-mult-11213-64.csv"
    "bench-sm-rm.bench.skelrm-parr-par-11213-32.csv"
    "bench-sm-rm.bench.skelrm-parr-par-11213-64.csv"
)

outFileNames=(
    "eden-cp-11213-32-diff.csv"
    "eden-cp-11213-64-diff.csv"
    "mult-11213-32-diff.csv"
    "mult-11213-64-diff.csv"
    "par-11213-32-diff.csv"
    "par-11213-64-diff.csv"
)

count=${#originalBenchmarks[@]}

for i in $(seq 0 $(expr ${count} - 1));
do
    ./calculateDifferences  ${originalBenchmarks[i]} ${parrowsBenchmarks[i]} ${outFileNames[i]}
    cp ${outFileNames[i]} ../content/benchmarks/sm-rm
done

rm *.csv
