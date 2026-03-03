library('ProjectTemplate')
library('scales')
load.project()
source("src/ltb_analysis.R")

get_sleep_trans_window_helper <- function(file_path, sleep) {
  return(read.csv(paste0(paste0(file_path, sleep), ".10/run1/generator.csv")) %>% mutate(index = floor((end_time - first(end_time))/1000), window_duration = emit_duration + padding_duration, type = sleep) %>% select(index, window_duration, type))
}

get_sleep_trans_window_df <- function(file_path) {
  sleep_trans_window_1_df <- get_sleep_trans_window_helper(file_path, 5)
  sleep_trans_window_2_df <- get_sleep_trans_window_helper(file_path, 10)
  sleep_trans_window_4_df <- get_sleep_trans_window_helper(file_path, 20)
  return(rbind(sleep_trans_window_1_df, sleep_trans_window_2_df, sleep_trans_window_4_df) %>% mutate(type = factor(type, levels=c("5", "10", "20"))))
}

get_sleep_buffer_helper <- function(file_path, sleep) {
  buff <- read.csv(paste0(file_path, paste0(sleep, ".10/run1/outPoolUsage.csv"))) %>% filter(task_name == "Source: Source") %>% select(time, value)
  backpressure <- read.csv(paste0(file_path, paste0(sleep, ".10/run1/isBackpressured.csv"))) %>% filter(task_name == "Source: Source") %>% mutate(status = value) %>% select(time, status) 
  return(buff %>% left_join(backpressure, by = "time") %>% mutate(index = floor((time - first(time))/1000000000), buffer = value * 100, type = sleep) %>% select(index, buffer, type, status) %>% distinct(index, .keep_all = TRUE))
}

get_sleep_buffer_df <- function(file_path) {
  sleep_buffer_1_df <- get_sleep_buffer_helper(file_path, 5)
  sleep_buffer_2_df <- get_sleep_buffer_helper(file_path, 10)
  sleep_buffer_4_df <- get_sleep_buffer_helper(file_path, 20)
  return(rbind(sleep_buffer_1_df, sleep_buffer_2_df, sleep_buffer_4_df) %>% mutate(type = factor(type, levels=c("5", "10", "20"))))
}

get_sleep_backpressured_time_helper <- function(file_path, sleep) {
  return(read.csv(paste0(paste0(file_path, sleep), ".10/run1/backpressuredTimeMsPerSecond.csv"))  %>% filter(task_name == "Source: Source") %>% mutate(index = floor((time - first(time))/1000000000), bp_time = value, type = sleep) %>% select(index, bp_time, type) %>% distinct(index, .keep_all = TRUE))
}

get_sleep_backpressured_time_df <- function(file_path) {
  sleep_backpressured_time_1_df <- get_sleep_backpressured_time_helper(file_path, 5)
  sleep_backpressured_time_2_df <- get_sleep_backpressured_time_helper(file_path, 10)
  sleep_backpressured_time_4_df <- get_sleep_backpressured_time_helper(file_path, 20)
  return(rbind(sleep_backpressured_time_1_df, sleep_backpressured_time_2_df, sleep_backpressured_time_4_df) %>% mutate(type = factor(type, levels=c("5", "10", "20"))))
}

# Section 5 - Monitor
file_path <- paste0("data/all_at_once_no_cutoff/uniform/constant/1000/1000.1.")
experiment_type <- expression("Total Workload(Delta)")
total_work_labels <- c("500", "1000", "2000")
sleep_raw_params <- read.csv(paste0(file_path, "10.10/run1/bash_params.csv"))
sleep_params <- data.frame(calibration_length = sleep_raw_params$calibration_size, experiment_length = sleep_raw_params$transmission_limit, calibration_type = sleep_raw_params$calibration_type)

sleep_trans_window_data <- get_sleep_trans_window_df(file_path)
sleep_trans_window_graph <- graph_trans_window(df = sleep_trans_window_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_trans_window_graph

sleep_buffer_data <- get_sleep_buffer_df(file_path)
sleep_buffer_graph <- graph_buffer(df = sleep_buffer_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_buffer_graph

sleep_isBackpressured_graph <- graph_isBackpressured(df = sleep_buffer_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
backpressureLabels <- c("5" = "Delta == 500", "10" = "Delta == 1000", "20" = "Delta == 2000")
sleep_isBackpressured_graph <- sleep_isBackpressured_graph + facet_wrap(~type, ncol = 1, labeller = as_labeller(backpressureLabels, default = label_parsed)) + theme(strip.text = element_text(size = 22))
sleep_isBackpressured_graph

sleep_backpressured_time_data <- get_sleep_backpressured_time_df(file_path)
sleep_backpressured_time_graph <- graph_backpressured_time(df = sleep_backpressured_time_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_backpressured_time_graph
sleep_increase_graph <- (sleep_backpressured_time_graph | sleep_isBackpressured_graph | sleep_buffer_graph) + plot_annotation(expression(paste("Generator Flink Metrics vs Total Workload (", Delta, ")"))) + plot_layout(guides = "collect", axes = "collect") & theme(legend.position = 'bottom', plot.title = element_text(size = 28)) 
sleep_increase_graph


ggsave(filename = "graphs/transmission_window_pre_mitigation.png", plot = sleep_trans_window_graph, width = 10, height = 4)
ggsave(filename = "graphs/flink_metrics_pre_mitigation.png", plot = sleep_increase_graph, width = 20, height = 8)

# Section 6 - Cutoff
file_path <- paste0("data/all_at_once_cutoff/uniform/constant/1000/1000.1.")
experiment_type <- expression(paste0("Total Workload (",Delta")")
total_work_labels <- c("500", "1000", "2000")

sleep_raw_params <- read.csv(paste0(file_path, "10.10/run1/bash_params.csv"))
sleep_params <- data.frame(calibration_length = sleep_raw_params$calibration_size, experiment_length = sleep_raw_params$transmission_limit, calibration_type = sleep_raw_params$calibration_type)

sleep_trans_window_data <- get_sleep_trans_window_df(file_path)
sleep_trans_window_graph <- graph_trans_window(df = sleep_trans_window_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_trans_window_graph
sleep_buffer_data <- get_sleep_buffer_df(file_path)
sleep_buffer_graph <- graph_buffer(df = sleep_buffer_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_buffer_graph

sleep_isBackpressured_graph <- graph_isBackpressured(df = sleep_buffer_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
backpressureLabels <- c("5" = "Delta == 500", "10" = "Delta == 1000", "20" = "Delta == 2000")
sleep_isBackpressured_graph <- sleep_isBackpressured_graph + facet_wrap(~type, ncol = 1, labeller = as_labeller(backpressureLabels, default = label_parsed)) + theme(strip.text = element_text(size = 22))
sleep_isBackpressured_graph

sleep_backpressured_time_data <- get_sleep_backpressured_time_df(file_path)
sleep_backpressured_time_graph <- graph_backpressured_time(df = sleep_backpressured_time_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_backpressured_time_graph

sleep_increase_graph <- (sleep_backpressured_time_graph | sleep_isBackpressured_graph | sleep_buffer_graph) + plot_annotation(expression(paste("Generator Flink Metrics vs Total Workload (", Delta, ")"))) + plot_layout(guides = "collect", axes = "collect") & theme(legend.position = 'bottom', plot.title = element_text(size = 28)) 
sleep_increase_graph


ggsave(filename = sprintf(paste0("graphs/", date_selected, "/%s.png"), "transmission_window_post_mitigation"), plot = sleep_trans_window_graph, width = 10, height = 4)
ggsave(filename = sprintf(paste0("graphs/", date_selected, "/%s.png"), "flink_metrics_post_mitigation"), plot = sleep_increase_graph, width = 20, height = 8)

# Section 6 - Spacing
file_path <- paste0("data/spaced_no_cutoff/uniform/constant/1000/1000.1.")
experiment_type <- expression(paste0("Total Workload (",Delta")")
total_work_labels <- c("500", "1000", "2000")
sleep_raw_params <- read.csv(paste0(file_path, "10.10/run1/bash_params.csv"))
sleep_params <- data.frame(calibration_length = sleep_raw_params$calibration_size, experiment_length = sleep_raw_params$transmission_limit, calibration_type = sleep_raw_params$calibration_type)

sleep_trans_window_data <- get_sleep_trans_window_df(file_path)
sleep_trans_window_graph <- graph_trans_window(df = sleep_trans_window_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_trans_window_graph

sleep_buffer_data <- get_sleep_buffer_df(file_path)
sleep_buffer_graph <- graph_buffer(df = sleep_buffer_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_buffer_graph

sleep_isBackpressured_graph <- graph_isBackpressured(df = sleep_buffer_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
backpressureLabels <- c("5" = "Delta == 500", "10" = "Delta == 1000", "20" = "Delta == 2000")
sleep_isBackpressured_graph <- sleep_isBackpressured_graph + facet_wrap(~type, ncol = 1, labeller = as_labeller(backpressureLabels, default = label_parsed)) + theme(strip.text = element_text(size = 22))
sleep_isBackpressured_graph

sleep_backpressured_time_data <- get_sleep_backpressured_time_df(file_path)
sleep_backpressured_time_graph <- graph_backpressured_time(df = sleep_backpressured_time_data, params_df = sleep_params, work_labels = total_work_labels, legend_title = experiment_type)
sleep_backpressured_time_graph

sleep_increase_graph <- (sleep_backpressured_time_graph | sleep_isBackpressured_graph | sleep_buffer_graph) + plot_annotation(expression(paste("Generator Flink Metrics vs Total Workload (", Delta, ")"))) + plot_layout(guides = "collect", axes = "collect") & theme(legend.position = 'bottom', plot.title = element_text(size = 28)) 
sleep_increase_graph


ggsave(filename = sprintf(paste0("graphs/", date_selected, "/%s.png"), "transmission_window_spacing"), plot = sleep_trans_window_graph, width = 10, height = 4)
ggsave(filename = sprintf(paste0("graphs/", date_selected, "/%s.png"), "flink_metrics_spacing"), plot = sleep_increase_graph, width = 20, height = 8)