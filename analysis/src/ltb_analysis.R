colour_blind_safe_pallete <- c("#D81B60", "#1E88E5", "#FFC107")
graph_title_size <- 26
legent_title_size <- 24
legend_text_size <- 22
axis_text_size <- 22
axis_title_size <- 24

graph_trans_window <- function(df, params_df, work_labels, legend_title, include_calibration=TRUE, include_annotation=TRUE) {
  xLimits = 0
  if (params_df$calibration_type == 0) {
    xLimits = params_df$experiment_length
  } else if (params_df$calibration_type == 1) {
    xLimits = params_df$experiment_length + params_df$calibration_length
  } else if (params_df$calibration_type == 2) {
    xLimits = params_df$experiment_length + 2 * params_df$calibration_length
  }
  if (!include_calibration) {
    df <- df %>% mutate(index = index - params_df$calibration_length) %>% filter(index >= 1, index < params_df$experiment_length)
  } 
  arrival_graph <- ggplot(df, aes(x = index, y = window_duration, color = type)) +
    theme_bw() + 
    geom_point(size = 3, alpha = 0.5) +
    geom_line() +
    ggtitle("", subtitle = expression(paste("Transmission Window Duration (", delta["transmit"], ") vs Total Work (", Delta,")"))) +
    ylab("Window Duration (ms)") +
    xlab("Seconds Elapsed (s)") +
    guides(color=guide_legend(title=expression(legend_title))) +
    theme(legend.position="bottom", 
          plot.title = element_blank(),
          plot.subtitle = element_text(size = 20), 
          legend.title = element_text(size = 18), 
          legend.text = element_text(size = 16), 
          axis.text = element_text(size = 16), 
          axis.title = element_text(size = 20)) +
    scale_color_manual(values = colour_blind_safe_pallete, labels = work_labels)
  if (include_calibration && include_annotation) {
    arrival_graph <- arrival_graph + 
      annotate("rect", xmin = 0, xmax = params_df$calibration_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) +
      annotate("rect", xmin = params_df$calibration_length + params_df$experiment_length, xmax = params_df$calibration_length * params_df$calibration_type + params_df$experiment_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) 
    if (params_df$calibration_length * params_df$calibration_type + params_df$experiment_length < max(df$index)) {
      arrival_graph <- arrival_graph + annotate("rect", xmin = params_df$calibration_length * (params_df$calibration_type) + params_df$experiment_length, xmax = max(df$index), ymin = -Inf, ymax = Inf, color = "darkred", fill = "darkred", alpha = 0.1)
    }
      
  }
  return(arrival_graph)
}

graph_isBackpressured <- function(df, params_df, work_labels, legend_title, include_calibration=TRUE, include_annotation=TRUE) {
  xLimits = 0
  if (params_df$calibration_type == 0) {
    xLimits = params_df$experiment_length
  } else if (params_df$calibration_type == 1) {
    xLimits = params_df$experiment_length + params_df$calibration_length
  } else if (params_df$calibration_type == 2) {
    xLimits = params_df$experiment_length + 2 * params_df$calibration_length
  }
  if (!include_calibration) {
    df <- df %>% mutate(index = index - params_df$calibration_length) %>% filter(index >= 1, index < params_df$experiment_length)
  } 
  arrival_graph <- ggplot(df, aes(x = index, y = as.numeric(as.factor(status)))) +
    theme_bw() + 
    geom_rect(aes(xmin = index - 0.5, xmax = index + 0.5, ymin = 0, ymax = 1, fill = as.factor(status))) +
    # ggtitle("", subtitle = expression(paste("isBackpressured vs Total Work (", Delta,")"))) +
    ggtitle("", subtitle = "isBackpressured") +
    ylab("isBackpressured? \n(true/false)") +
    xlab("Seconds Elapsed (s)") +
    guides(color=guide_legend(title=legend_title)) +
    theme(legend.position="bottom", 
          plot.title = element_blank(),
          plot.subtitle = element_text(size = graph_title_size), 
          legend.title = element_text(size = legent_title_size), 
          legend.text = element_text(size = legend_text_size), 
          axis.text = element_text(size = axis_text_size), 
          axis.title = element_text(size = axis_title_size)) +
    scale_fill_manual(values = c(false = NA, true = "red")) +
    scale_y_continuous(limits = c(0,1), breaks = c(0,1)) +
    labs(fill = "Operator Backpressured?")
  if (include_calibration && include_annotation) {
    arrival_graph <- arrival_graph + 
      annotate("rect", xmin = 0, xmax = params_df$calibration_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) +
      annotate("rect", xmin = params_df$calibration_length + params_df$experiment_length, xmax = params_df$calibration_length * params_df$calibration_type + params_df$experiment_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) 
    if (params_df$calibration_length * params_df$calibration_type + params_df$experiment_length < max(df$index)) {
      arrival_graph <- arrival_graph + 
        annotate("rect", xmin = params_df$calibration_length * params_df$calibration_type + params_df$experiment_length, xmax = max(df$index), ymin = -Inf, ymax = Inf, color = "darkred", fill = "darkred", alpha = 0.1)
    }
  }
  return(arrival_graph)
}

graph_buffer <- function(df, params_df, work_labels, legend_title, include_calibration=TRUE, include_annotation=TRUE) {
  xLimits = 0
  if (params_df$calibration_type == 0) {
    xLimits = params_df$experiment_length
  } else if (params_df$calibration_type == 1) {
    xLimits = params_df$experiment_length + params_df$calibration_length
  } else if (params_df$calibration_type == 2) {
    xLimits = params_df$experiment_length + 2 * params_df$calibration_length
  }
  if (!include_calibration) {
    df <- df %>% mutate(index = index - params_df$calibration_length) %>% filter(index >= 1, index < params_df$experiment_length)
  } 
  arrival_graph <- ggplot(df, aes(x = index, y = buffer, color = type)) +
    theme_bw() + 
    geom_point(size = 3, alpha = 0.5) +
    geom_line() +
    ggtitle("", subtitle = expression(paste("outPoolUsage vs Total Work (", Delta,")"))) +
    ggtitle("", subtitle = "outPoolUsage") +
    ylab("Output Buffer \nUtilisation (%)") +
    xlab("Seconds Elapsed (s)") +
    guides(color=guide_legend(title=legend_title)) +
    theme(legend.position="bottom", 
          plot.title = element_blank(),
          plot.subtitle = element_text(size = graph_title_size), 
          legend.title = element_text(size = legent_title_size), 
          legend.text = element_text(size = legend_text_size), 
          axis.text = element_text(size = axis_text_size), 
          axis.title = element_text(size = axis_title_size)) +
    scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 10)) +
    scale_color_manual(values = colour_blind_safe_pallete, labels = work_labels)

  if (include_calibration && include_annotation) {
    arrival_graph <- arrival_graph + 
      annotate("rect", xmin = 0, xmax = params_df$calibration_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) +
      annotate("rect", xmin = params_df$calibration_length + params_df$experiment_length, xmax = params_df$calibration_length * params_df$calibration_type + params_df$experiment_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) 
    if (params_df$calibration_length * params_df$calibration_type + params_df$experiment_length < max(df$index)) {
      arrival_graph <- arrival_graph + 
        annotate("rect", xmin = params_df$calibration_length * params_df$calibration_type + params_df$experiment_length, xmax = max(df$index), ymin = -Inf, ymax = Inf, color = "darkred", fill = "darkred", alpha = 0.1)
    }
  }
  return(arrival_graph)
}

graph_backpressured_time <- function(df, params_df, work_labels, legend_title, include_calibration=TRUE, include_annotation=TRUE) {
  xLimits = 0
  if (params_df$calibration_type == 0) {
    xLimits = params_df$experiment_length
  } else if (params_df$calibration_type == 1) {
    xLimits = params_df$experiment_length + params_df$calibration_length
  } else if (params_df$calibration_type == 2) {
    xLimits = params_df$experiment_length + 2 * params_df$calibration_length
  }
  if (!include_calibration) {
    df <- df %>% mutate(index = index - params_df$calibration_length) %>% filter(index >= 1, index < params_df$experiment_length)
  } 
  arrival_graph <- ggplot(df, aes(x = index, y = bp_time, color = type)) +
    theme_bw() + 
    geom_point(size = 3, alpha = 0.5) +
    geom_line() +
    # ggtitle("", subtitle = expression(paste("msBackpressuredPerSecond vs Total Work (", Delta,")"))) +
    ggtitle("", subtitle = "msBackpressuredPerSecond") +
    ylab("Time Spent in \nBackpressure (ms)") +
    xlab("Seconds Elapsed (s)") +
    ylim(0, 1000) +
    guides(color=guide_legend(title=legend_title)) +
    theme(legend.position="bottom", 
          plot.title = element_blank(),
          plot.subtitle = element_text(size = graph_title_size), 
          legend.title = element_text(size = legent_title_size), 
          legend.text = element_text(size = legend_text_size), 
          axis.text = element_text(size = axis_text_size), 
          axis.title = element_text(size = axis_title_size)) +
    scale_color_manual(values = colour_blind_safe_pallete, labels = work_labels)
  if (include_calibration && include_annotation) {
    arrival_graph <- arrival_graph + 
      annotate("rect", xmin = 0, xmax = params_df$calibration_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) +
      annotate("rect", xmin = params_df$calibration_length + params_df$experiment_length, xmax = params_df$calibration_length * params_df$calibration_type + params_df$experiment_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) 
    if (params_df$calibration_length * params_df$calibration_type + params_df$experiment_length < max(df$index)) {
      arrival_graph <- arrival_graph + 
        annotate("rect", xmin = params_df$calibration_length * params_df$calibration_type + params_df$experiment_length, xmax = max(df$index), ymin = -Inf, ymax = Inf, color = "darkred", fill = "darkred", alpha = 0.1)
    }
  }
  return(arrival_graph)
}

graph_output_queue_length_time <- function(df, params_df, work_labels, legend_title, include_calibration=TRUE, include_annotation=TRUE) {
  xLimits = 0
  if (params_df$calibration_type == 0) {
    xLimits = params_df$experiment_length
  } else if (params_df$calibration_type == 1) {
    xLimits = params_df$experiment_length + params_df$calibration_length
  } else if (params_df$calibration_type == 2) {
    xLimits = params_df$experiment_length + 2 * params_df$calibration_length
  }
  if (!include_calibration) {
    df <- df %>% mutate(index = index - params_df$calibration_length) %>% filter(index >= 1, index < params_df$experiment_length)
  } 
  arrival_graph <- ggplot(df, aes(x = index, y = queue, color = type)) +
    theme_bw() + 
    geom_point(size = 3, alpha = 0.5) +
    geom_line() +
    ylim(0, 10) +
    ggtitle(paste("", "Output Queue Length")) +
    ylab("Number of Queued Buffers") +
    xlab("Seconds Elapsed") +
    guides(color=guide_legend(title=legend_title)) +
    theme(legend.position="bottom", 
          plot.title = element_blank(),
          plot.subtitle = element_text(size = graph_title_size), 
          legend.title = element_text(size = legent_title_size), 
          legend.text = element_text(size = legend_text_size), 
          axis.text = element_text(size = axis_text_size), 
          axis.title = element_text(size = axis_title_size)) +
    scale_color_manual(values = colour_blind_safe_pallete, labels = work_labels)
  if (include_calibration && include_annotation) {
    arrival_graph <- arrival_graph + 
      annotate("rect", xmin = 0, xmax = params_df$calibration_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) +
      annotate("rect", xmin = params_df$calibration_length + params_df$experiment_length, xmax = 2 * params_df$calibration_length + params_df$experiment_length, ymin = -Inf, ymax = Inf, color = "grey", fill = "grey", alpha = 0.1) +
      annotate("rect", xmin = 2 * params_df$calibration_length + params_df$experiment_length, xmax = max(df$index), ymin = -Inf, ymax = Inf, color = "darkred", fill = "darkred", alpha = 0.1)
  }
  return(arrival_graph)
}

