#!/bin/bash
home=`dirname $(readlink -e $0)`

# Execute this script in a directory prepared by experiment-controller/fetch-experiment-files.sh

# Read data from experiments, which is sometimes not cleanly terminated
# Load the bitflow-plugin-experiments Plugin to get the synchronize_tags() step
# Read the reference samples from the experiment controller, the "ground truth" about injected anomalies
# Give the reference samples a special "component" tag for the synchronize_tags() step below
# Print all input file names, separated by ";" to read them in parallel
# Append this script (prepare-data.bf) to the executed pipeline

NUM_COMPONENTS=$(find "bitflow-collector" -name 'data.bin' | wc -l)

docker run -w /data -v "$PWD:/data" -ti teambitflow/zerops-analysis \
       -files-robust \
       " { experiment-controller/experiment.csv \
                -> tags(tags={component=controller}) ; \
         $(find "bitflow-collector" -name '*.bin' -printf '%p ; ') } \
         $(cat "$home/prepare-data.bf" | sed "s/NUMBER_OF_COMPONENTS/$NUM_COMPONENTS/g") "

