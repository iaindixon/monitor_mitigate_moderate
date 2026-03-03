#!/bin/bash

bash get_metrics.bash experiment/all_at_once_cutoff/uniform/constant/1000/1000.1.5.10/run1
bash get_metrics.bash experiment/all_at_once_cutoff/uniform/constant/1000/1000.1.10.10/run1
bash get_metrics.bash experiment/all_at_once_cutoff/uniform/constant/1000/1000.1.20.10/run1
mv experiment/all_at_once_cutoff ../analysis/data/