get_eyecatching <- function(start_path, undershootFactor, cutoffType) {
  if (missing(undershootFactor)) {
    undershootFactor = 1
  }
  if (missing(cutoffType)) {
    cutoffType = " - No Cutoff"
  }
  experiment_df <- data.frame()
  paths <- list.dirs(start_path)
  paths <- paths[!grepl("influx", paths)]
  paths <- paths[grepl("run", paths)]
  paths <- paths[grepl(paste0(undershootFactor, "."), paths)]
  print(paths)
  for (path in paths) {
    print(path)
    df <- clean_csv(paste0(path, "/clean_output.csv"))
    print(df)
    run_name <- str_split(path, "/")
    print(run_name)
    df <- df %>% filter(windowIndex >= 10) %>% 
      mutate(run = as.factor(substr(run_name[[1]][7], 4, nchar(run_name[[1]][7]))),
             rate = as.numeric(strsplit(run_name[[1]][6], ".", fixed=TRUE)[[1]][[1]]), 
             windowAverageSize = case_when(
               grepl("window|weighted", path) ~ 
                 as.factor(strsplit(run_name[[1]][3], "_")[[1]][3]),
               .default = "0"
             ),
             spacingName = ifelse(grepl("Window", spacingName), paste0(spacingName, windowAverageSize), spacingName),
             arrivalName = case_when(
               run_name[[1]][4] == "uniform_process" ~ "Uniform Process",
               run_name[[1]][4] == "stepped_process" ~ "Stepped Process",
               run_name[[1]][4] == "periodic_process" ~ "Periodic Process",
               run_name[[1]][4] == "poisson_process" ~ "Poisson Process",
               run_name[[1]][4] == "envelope_process" ~ "Envelope Process"
             ),
             busywork = as.factor(strsplit(run_name[[1]][[6]], ".", fixed=TRUE)[[1]][[3]])) %>%
      mutate(spacingName=as.factor(spacingName))
    print(df)
    experiment_df <- rbind(experiment_df, df)
    print(experiment_df)
  }
  experiment_df$spacingName <- paste0(paste0(experiment_df$spacingName, " - "), cutoffType)
  return(experiment_df)
}

