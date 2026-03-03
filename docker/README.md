# Monitor, Mitigate, Moderate: Docker

In this folder of the project we contain all the docker code and bash scripts which allow us to run the Apache Flink Code. 

## Files

A brief explanation of each file and folder.

#### archive/
Containing all older code and previous runs of experiments. For use in cleaning up experiments and keeping experiment/ current.

#### arts/
Containing the .jar executable for the docker instance.

#### docker-compose.yml
Containing all docker file information, loading project .jar file with system params into the docker instance. 

#### experiment/
Containing all code from experimental runs via loop_executable.bash and run_experiment.bash

#### get_executable.bash
Retrieves the .jar executable for the docker instance from the Java project located in ~/BenchmarkBumbles/java/target/flink-examples-1.0-SNAPSHOT-jar-with-dependencies.jar 

#### loop_executable.bash
Runs a series of experiments given locally set variables valling run_experiment.bash and passing it through 
- NOTE: The `chainOperators` variable when set equal to true results in each operation being run on the same operator, resulting in the collected flink metrics being for the entire system at once.
#### run_experiment.bash
Runs an experimental loop executing the docker instance with java code given a set of parameters passed via loop_executable.bash and locally set variables.

#### pre_mitigation.bash
Creates the data required for Figures 8 and 9 

#### pre_mitigation_metrics.bash
Gets metrics from Flink using InfluxDBv1.0 and puts them into csv files for Figures 8 and 9

#### post_mitigation.bash
Creates the data required for Figures 11 and 12

#### post_mitigation_metrics.bash
Gets metrics from Flink using InfluxDBv1.0 and puts them into csv files for Figures 11 and 12

#### spacing.bash
Creates the data required for Figure 10

#### spacing_metrics.bash
Gets metrics from Flink using InfluxDBv1.0 and puts them into csv files for Figure 10