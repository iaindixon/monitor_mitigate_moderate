# Add any project specific configuration here.
add.config(
  apply.override = FALSE
)

# Add project specific configuration that can be overridden from load.project()
add.config(
  apply.override = TRUE
)

# Load analysis functions
source('munge/01-load-experiments.R')
source('munge/02-load-latency-histograms.R')
source('munge/03-load-eyecatching-graph.R')
source('src/arrival_rate_exploration.R')
source('src/emit_time_ecdf.R')
source('src/proportion_created_ecdf.R')
source('src/latency_analysis.R')
source('src/throughput_analysis.R')
source('src/backpressure.R')
source('src/arrival_rate.R')
source('src/graph_overlays.R')
source('src/window_times.R')
options(scipen=10000)
