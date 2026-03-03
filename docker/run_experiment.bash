#!/bin/bash

experiment_names=("all_at_once" "remaining_time" "simple_weighted_2" "simple_weighted_5" "simple_weighted_10" "linear_weighted_2" "linear_weighted_5" "linear_weighted_10" "exponential_weighted_2" "exponential_weighted_5" "exponential_weighted_10" "total_average")
spacing_methods=(0 1 2 2 2 3 3 3 4 4 4 5)
rolling_size=(0 0 2 5 10 2 5 10 2 5 10 0)
cutoff_names=("no_cutoff" "cutoff" "cutoff_next")
n="${#experiment_names[@]}"
for (( i = 1; i < 3; i++ )); do
  for (( j = 0; j < 1; j++)); do
    bash loop_executable.bash "${experiment_names[j]}_${cutoff_names[i]}" "${spacing_methods[j]}" "$i" "${rolling_size[j]}"
  done
done
