#!/bin/bash

pkill influxd

sentenceSize=100
transmissionLimit=60
calibrationSize=30
calibrationType=2
spacingMethod="$2"
cutoffMethod="$3"
rollingSize="$4"
middleChunk=30
stepStart=500
numSteps=4
spikeMultiplier=10
spikeDuration=20
waveFrequency=10
chainOperators=false

if [ ! -d experiment/ ]; then
  mkdir experiment
fi
if [ ! -d arts/ ]; then
    mkdir arts
fi
if [ -z "$1" ]; then
  echo "Please provide a base path."
else
  arrivals=(0)
  arrivalNames=("uniform" "stepped" "periodic" "poisson" "envelope" "spike")
  rates=(1000 1200)
#  rates=(800000 1000000 1200000 1400000 1600000)
  windows=(1000)
  workMethods=(0)
  workNames=("constant" "after" "stepped" "wave")
  undershoots=(1)
  sleeps=(10)
  workFrequencies=(10)
  for arrival in "${arrivals[@]}"; do
    for i in {1..1}; do
      for workMethod in "${workMethods[@]}"; do
        for workFrequency in "${workFrequencies[@]}"; do
          for rate in "${rates[@]}"; do
            for window in "${windows[@]}"; do
              for undershoot in "${undershoots[@]}"; do
                for sleep in "${sleeps[@]}"; do
                  experimentPath="$1/${arrivalNames[arrival]}/${workNames[workMethod]}/$rate/$window.$undershoot.$sleep.$workFrequency/run$i"
                  runPath="experiment/$experimentPath"
                  mkdir "experiment/$1"
                  mkdir "experiment/$1/${arrivalNames[arrival]}"
                  mkdir "experiment/$1/${arrivalNames[arrival]}/${workNames[workMethod]}"
                  mkdir "experiment/$1/${arrivalNames[arrival]}/${workNames[workMethod]}/$rate"
                  mkdir "experiment/$1/${arrivalNames[arrival]}/${workNames[workMethod]}/$rate/$window.$undershoot.$sleep.$workFrequency"
                  mkdir "$runPath"
    #             # Create bash params file and saves variables from the top of the file to it
                  echo sentence_size,transmission_limit,calibration_size,calibration_type,spacing_method,cutoff_method,rolling_size,work_method,middle_chunk,\
                       step_start,num_steps,spike_multiplier,spike_duration,wave_frequency,chain_operators,sleep_amount,window_size,work_frequency,\
                        undershoot,rate> "$runPath/bash_params.csv"
                  echo $sentenceSize,$transmissionLimit,$calibrationSize,$calibrationType,"$spacingMethod","$cutoffMethod",$rollingSize,$workMethod,$middleChunk,\
                       $stepStart,$numSteps,$spikeMultiplier,$spikeDuration,$waveFrequency,$chainOperators,"$sleep",$window,$workFrequency,\
                        $undershoot,$rate>> "$runPath/bash_params.csv"
                  CHAIN_OPERATORS="$chainOperators" SOURCE_RATE="$rate" SENTENCE_LENGTH="$sentenceSize" WINDOW_SIZE="$window" WINDOW_LIMIT="$transmissionLimit" ROLLING_SIZE="$rollingSize" SPACING_METHOD="$spacingMethod" CUTOFF_METHOD="$cutoffMethod" ARRIVAL_PROCESS="$arrival" CALIBRATION_SIZE="$calibrationSize" UNDERSHOOT_FACTOR="$undershoot" SLEEP_AMOUNT="$sleep" WORK_METHOD="$workMethod" STEP_START="$stepStart" SPIKE_MULTIPLIER="$spikeMultiplier" SPIKE_DURATION="$spikeDuration" WORK_FREQUENCY="$workFrequency" MIDDLE_CHUNK="$middleChunk" NUM_STEPS="$numSteps" WAVE_FREQUENCY="$waveFrequency" CALIBRATION_TYPE="$calibrationType" docker compose up --abort-on-container-exit >> "$runPath/output.txt"
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
fi

