import_metrics <- function(start_path, descriptor) {
  latency_df <- data.frame()
  throughput_df <- data.frame()
  paths <- list.dirs(start_path)
  paths <- paths[!grepl("influx", paths)]
  paths <- paths[grepl("run", paths)]
  total_throughputs <- data.frame()
  for (path in paths) {
    run_name <- str_split(path, "/")
    process_rate <- run_name[[1]][5]
    process_name <- run_name[[1]][4]
    work <- str_split(run_name[[1]][6], "[.]")[[1]][3]
    spike <- "0"
    if (str_split(run_name[[1]][4], '_')[[1]][1] == "spike") {
      spike <- str_split(run_name[[1]][4], '_')[[1]][2]
    }
    process <- paste0(descriptor, paste0("_", paste0(process_name, paste0("_", process_rate))))
    # Load Throughput
    total_throughput <- read.csv(paste0(path, "/total_throughput.csv")) %>% mutate(rate = process_rate, work = work, spike = spike)
    # read.csv
    assign(paste0(process, paste0("_", paste0(work, "_total_throughput_df"))), total_throughput, envir = parent.frame())
    window_throughput <- read.csv(paste0(path, "/window_throughput.csv")) %>% filter(throughput != 0) %>% mutate(rate = process_rate, process = process_name, work = work, spike = spike, window = window - 10) %>% filter(window >= 0)
    assign(paste0(process, paste0("_", paste0(work, "_window_throughput_df"))), window_throughput, envir = parent.frame())
    # Load Latency
    total_latency <- read.csv(paste0(path, "/total_latency.csv")) %>% mutate(rate = process_rate, work = work, spike = spike)
    assign(paste0(process, paste0("_", paste0(work, "_total_latency_df"))), total_latency, envir = parent.frame())
    window_latency <- read.csv(paste0(path, "/window_latency.csv")) %>% filter(total_count != 0) %>% mutate(rate = process_rate, work = work, spike = spike, window = window - 10) %>% filter(window >= 0)
    assign(paste0(process, paste0("_", paste0(work, "_window_latency_df"))), window_latency, envir = parent.frame())
    # Load Transmit Duration
    total_transmit <- read.csv(paste0(path, "/total_transmit.csv")) %>% mutate(rate = process_rate, work = work, spike = spike)
    assign(paste0(process, paste0("_", paste0(work, "_total_transmit_df"))), total_transmit, envir = parent.frame())
    window_transmit <- read.csv(paste0(path, "/window_transmit.csv")) %>% filter(total_count != 0) %>% mutate(rate = process_rate, work = work, spike = spike, window = window - 10) %>% filter(window >= 0)
    assign(paste0(process, paste0("_", paste0(work, "_window_transmit_df"))), window_transmit, envir = parent.frame())
    # Load Interarrival Duration
    total_interarrival <- read.csv(paste0(path, "/total_interarrival.csv")) %>% mutate(rate = process_rate, work = work, spike = spike)
    assign(paste0(process, paste0("_", paste0(work, "_total_interarrival_df"))), total_interarrival, envir = parent.frame())
    window_interarrival <- read.csv(paste0(path, "/window_interarrival.csv")) %>% filter(total_count != 0) %>% mutate(rate = process_rate, work = work, spike = spike, window = window - 10) %>% filter(window >= 0)
    assign(paste0(process, paste0("_", paste0(work, "_window_interarrival_df"))), window_interarrival, envir = parent.frame())
    # Load Generation Rate
    generation_rate <- read.csv(paste0(path, "/window_rate.csv")) %>% filter(rate != 0) %>% mutate(work = work, spike = spike, window = window - 10) %>% filter(window >= 0)
    assign(paste0(process, paste0("_", paste0(work, "_window_rate_df"))), generation_rate, envir = parent.frame())
  }
}
