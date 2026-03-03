# Monitor, Mitigate, Moderate: Backpressure in Stream Benchmark Generators

This project is an exploration into design decisions that can be made when benchmarking stream processing engines. Built on top of the [DS2](https://github.com/strymon-system/ds2) wordcount implementation we modify the generator function to include spacing between records within a transmission window, and cutoff functionality to end a window and avoid violating the constraints of a rate.

When cloned, the folder structure should be as follows:
```
| README.md
| analysis/
| docker/
| java/
```
###### **Analysis**
The `analysis/` folder contains a simplified R ProjectTemplate, where the `analysis/src/` folder holds the files to generate the graphics used in the paper, `analysis/data/` folder holds the data files extracted from running experiments, and `analysis/graphs` folder holds the graphics produced. 

###### **Docker**
The `docker/` folder contains all of the specific experiment runs seen in the paper, as well as a general purpose `loop_executable.bash` and `run_experiment.bash` files to allow you to implement any specific combination that you wish. 

###### **Java**
The `java/` folder contains the java code used to build the MMM pipeline. To create the executable, open this folder in IntelliJ and create a package which you can move into the docker folder using the instructions below. 

## Installation Instructions
This experiment records two sets of metrics - custom metrics developed by authors and built-in Flink metrics. Flink metrics are saved in an InfluxDB timeseries database, but we use version Influx@1 which has slightly different install instructions.

To install the correct version of Influxdb on a Mac system using Homebrew please follow the following instructions:
   ```bash
   $ brew install influxdb@1
   $ echo 'export PATH="/opt/homebrew/opt/influxdb@1/bin:$PATH"' >> ~/.zshrc
   $ source ~/.zshrc
   $ influxd 

 8888888           .d888 888                   8888888b.  888888b.
   888            d88P"  888                   888  "Y88b 888  "88b
   888            888    888                   888    888 888  .88P
   888   88888b.  888888 888 888  888 888  888 888    888 8888888K.
   888   888 "88b 888    888 888  888  Y8bd8P' 888    888 888  "Y88b
   888   888  888 888    888 888  888   X88K   888    888 888    888
   888   888  888 888    888 Y88b 888 .d8""8b. 888  .d88P 888   d88P
 8888888 888  888 888    888  "Y88888 888  888 8888888P"  8888888P"

2024-07-24T13:06:03.436631Z	info	InfluxDB starting	{"log_id": "0qaDQhB0000", "version": "1.11.5", "branch": "unknown", "commit": "unknown"}
2024-07-24T13:06:03.436642Z	info	Go runtime	{"log_id": "0qaDQhB0000", "version": "go1.21.7", "maxprocs": 12}
2024-07-24T13:06:03.436646Z	info	configured logger	{"log_id": "0qaDQhB0001", "format": "auto", "level": "info"}
   ```
After the influx logo appears go ahead and cancel it out with cnt + c, this creates the file structure we need for later.
**Note**: Make sure you only have Influxdb@1 installed on your machine, it is unclear how this may conflict with other versions if InfluxDB

## Running MMMv1.0
These instructions assume a Unix-like system.

1. Make sure that you have at least Java 1.8 and Docker installed on your machine.

2. Open the project folder in Intellij. On the right side click the Maven icon and open the `LifeStyle` folder then click `package`

3. After the compiler has created our Jar, enter terminal and make sure you're on the `monitor_mitigate_moderate/docker` path before executing the following to retrieve our packaged simulation to deploy into Docker:
    ```bash
    $ pwd
    .../monitor_mitigate_moderate/docker
    $ bash get_executable.bash
    ```

4. From there, you can run any of the experiments (ex. `pre_mitigation.bash`) or modify the generic experiment loader `run_experiment.bash` which triggers the `loop_executable.bash` file. Results of the experiments are placed in `experiment/`, and can then be transfered to the `analysis/data` folder to be observed in R. 
    ```bash
    $ cd docker
    $ bash pre_mitigation.bash
    $ ls experiment/
    all_at_once_no_cutoff
    ```

   #### Generated Directory Stucture
   
   For an example of generated file structure, we will look at the results of running the `pre_mitigation.bash` file:
   ```
   | experiment
   |-- all_at_once_no_cutoff
      |-- uniform
        |-- constant
            |-- 1000
               |-- 1000.1.5.10
                  |-- run1
                     |-- generator.csv
                     |-- output.txt
                     |-- ...
                     |-- influxdb
                       |-- flink.autogen.00001.00
                       |-- meta.00
               |-- 1000.1.10.10
                  |-- run1/
               |-- 1000.1.20.10
                  |-- run1/
   ```
   In the innermost file structure for an individual run given a window and rate parameter, we have
   - `generator.csv` which is the mostly sanitised csv removing the non-parameter reporting lines from the console during an experimental run
   - `output.txt` which contains the complete dirty console output during an experimental run
   - `influxdb` which is a directory containing a snapshot of the flink metrics db at the end of an experimental run

5. Once we have the custom metrics extracted directly into the run1 folders, we can get the Flink metrics using InfluxDB by running the corresponding `*_metrics.bash` file, so for the above experiment `pre_mitigation.bash` we run the  `pre_mitigation_metrics.bash` file. This also grabs the corresponding experiment file in `experiments/` and moved it into the `analysis/data` folder for analysis in R automatically.
   ```bash
   $ ls experiment/
   all_at_once_no_cutoff
   $ bash pre_mitigation_metrics.bash
   ... Lots of InfluxDB data loading ...
   ... Moving results to analysis/data ...
   $ ls experiment/
   $ ls ../analysis/data
   all_at_once_no_cutoff
   ```

6. To replicate the results in the paper, repeat the above process for the `post_mitigation.bash` and `spacing.bash` files as well. Now, open up RStudio on the `analysis/` folder, and set the working directory to that location. Execute the lines in `analysis/src/paper_example.R` to produce the graphics seen in the paper (subject to some minor differences due to stochastic results). 

## Manually Loading Flink Metrics iva InfluxDB
After an experimental run has been conducted we create an `influxdb` folder which contains two files: `flink.autogen.00001.00` and `meta.00`.
We can load the metrics after a run and extract them into a csv file using the following commands:
```bash
   $ influxd restore -db flink -metadir ~/.influxdb/meta/ -datadir ~/.influxdb/data/ path_to_experiment/influxdb
   $ influxd & sleep 1 && \
   $ influx -database "flink" -execute "SELECT * FROM desired_metric" -format csv > path_to_location/output_file_name.csv
```
For a complete list of metrics that are tracked by Flink and can be extracted please refer to: https://nightlies.apache.org/flink/flink-docs-master/docs/ops/metrics/
Also please ensure that the job/task manager is selected in the metric name to get the appropriate data.
For example to get the backPressuredTimeMSPerSecond metric:
```bash
   $ influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_backPressuredTimeMsPerSecond" -format csv > path_to_location/taskmanager_job_task_backPressuredTimeMsPerSecond.csv
```

## Common Issues
If you attempt to run the experiment files, and the docker containers say that they can't launch the Flink cluster, go ahead and remove the containers from your machine. A fresh instance will allow you to run. 
