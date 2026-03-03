clean_csv <- function(input_csv) {
  df <- read_csv(input_csv)
  df <- df %>% mutate(end_time = as.POSIXct(as.numeric(end_time)/1000, origin="1970-01-01"),
           proportion_created = sentences_processed / current_rate) %>%
  return(df)
}

import_experiments <- function(start_path, undershootFactor) {
  if (missing(undershootFactor)) {
    undershootFactor = 1
  }
  experiment_df <- data.frame()
  paths <- list.dirs(start_path)
  paths <- paths[!grepl("influx", paths)]
  paths <- paths[grepl("run", paths)]
  # print(paths)
  for (path in paths) {
    # print(path)
    df <- clean_csv(paste0(path, "/generator.csv"))
    # print(df)
    run_name <- str_split(path, "/")
    # print(run_name)
    # df <- df %>% mutate(work = str_split(run_name[[1]][6], "[.]")[[1]][3], 
    #                     number_of_transmitted_windows = number_of_transmitted_windows - 10) %>% 
    #   filter(number_of_transmitted_windows >= 0) %>% 
    
    df <- df %>% mutate(work = str_split(run_name[[1]][6], "[.]")[[1]][3]) %>% 
      mutate(run = as.factor(substr(run_name[[1]][7], 4, nchar(run_name[[1]][7]))),
             rate = run_name[[1]][5], number_of_transmitted_windows = number_of_transmitted_windows - 10) %>%
      filter(number_of_transmitted_windows >= 0)
    experiment_df <- rbind(experiment_df, df)
    # print(experiment_df)
  }
  return(experiment_df)
}

aggregate_runs <- function(df) {
  return(df %>% group_by(windowIndex, rate, arrivalName, windowSize, spacingName) %>% 
           summarise(
             across(where(is.numeric), median),
             across(!where(is.numeric), first)
           ))
}


