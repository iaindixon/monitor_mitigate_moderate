#!/bin/bash

pkill influxd

experiment_name="all_at_once_no_cutoff"
spacingMethod=0
cutoffMethod=0
sentenceSize=100
transmissionLimit=60
calibrationSize=30
calibrationType=2
chainOperators=false
arrivals=(0)
arrivalNames=("uniform" "stepped" "periodic" "poisson" "envelope" "spike")
workMethods=(0)
workNames=("constant" "after" "stepped" "wave")
rates=(1000)
windows=(1000)
undershoots=(1)
sleeps=(5 10 20)
workFrequencies=(10)
middleChunk=0
stepStart=0
numSteps=0
spikeMultiplier=0
spikeDuration=0
waveFrequency=0

if [ ! -d experiment/ ]; then
  mkdir experiment
fi
if [ ! -d arts/ ]; then
    mkdir arts
fi
for arrival in "${arrivals[@]}"; do
  for i in {1..1}; do
    for workMethod in "${workMethods[@]}"; do
      for workFrequency in "${workFrequencies[@]}"; do
        for rate in "${rates[@]}"; do
          for window in "${windows[@]}"; do
            for undershoot in "${undershoots[@]}"; do
              for sleep in "${sleeps[@]}"; do
                experimentPath="$experiment_name/${arrivalNames[arrival]}/${workNames[workMethod]}/$rate/$window.$undershoot.$sleep.$workFrequency/run$i"
                runPath="experiment/$experimentPath"
                mkdir "experiment/$experiment_name"
                mkdir "experiment/$experiment_name/${arrivalNames[arrival]}"
                mkdir "experiment/$experiment_name/${arrivalNames[arrival]}/${workNames[workMethod]}"
                mkdir "experiment/$experiment_name/${arrivalNames[arrival]}/${workNames[workMethod]}/$rate"
                mkdir "experiment/$experiment_name/${arrivalNames[arrival]}/${workNames[workMethod]}/$rate/$window.$undershoot.$sleep.$workFrequency"
                mkdir "$runPath"
                # Create bash params file and saves variables from the top of the file to it
                echo sentence_size,transmission_limit,calibration_size,calibration_type,spacing_method,cutoff_method,rolling_size,work_method,middle_chunk,\
                     step_start,num_steps,spike_multiplier,spike_duration,wave_frequency,chain_operators,sleep_amount,window_size,work_frequency,\
                      undershoot,rate> "$runPath/bash_params.csv"
                echo $sentenceSize,$transmissionLimit,$calibrationSize,$calibrationType,"$spacingMethod","$cutoffMethod",$workMethod,$middleChunk,\
                     $stepStart,$numSteps,$spikeMultiplier,$spikeDuration,$waveFrequency,$chainOperators,"$sleep",$window,$workFrequency,\
                      $undershoot,$rate>> "$runPath/bash_params.csv"
                CHAIN_OPERATORS="$chainOperators" SOURCE_RATE="$rate" SENTENCE_LENGTH="$sentenceSize" WINDOW_SIZE="$window" WINDOW_LIMIT="$transmissionLimit" SPACING_METHOD="$spacingMethod" CUTOFF_METHOD="$cutoffMethod" ARRIVAL_PROCESS="$arrival" CALIBRATION_SIZE="$calibrationSize" UNDERSHOOT_FACTOR="$undershoot" SLEEP_AMOUNT="$sleep" WORK_METHOD="$workMethod" STEP_START="$stepStart" SPIKE_MULTIPLIER="$spikeMultiplier" SPIKE_DURATION="$spikeDuration" WORK_FREQUENCY="$workFrequency" MIDDLE_CHUNK="$middleChunk" NUM_STEPS="$numSteps" WAVE_FREQUENCY="$waveFrequency" CALIBRATION_TYPE="$calibrationType" docker compose up --abort-on-container-exit >> "$runPath/output.txt"
                docker start influxdb
                docker exec -it influxdb influxd backup -db flink /opt/influxdb
                docker cp influxdb:/opt/influxdb/ "$runPath"
                docker stop influxdb
                docker start docker-taskmanager-1
                docker cp docker-taskmanager-1:/opt/flink/generator.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/total_latency.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/window_latency.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/total_throughput.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/window_throughput.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/total_transmit.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/window_transmit.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/total_interarrival.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/window_interarrival.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/window_rate.csv "$runPath"
                docker cp docker-taskmanager-1:/opt/flink/workload_simulated.csv "$runPath"
                docker stop docker-taskmanager-1
                docker rm docker-taskmanager-1
                docker rm docker-jobmanager-1
                docker rm influxdb
              done
            done
          done
        done
      done
    done
  done
done