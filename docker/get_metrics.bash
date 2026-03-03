#!/bin/bash

influx_path="$1"


# Kills any influxdb instance currently running
pkill influxd

influxd &
sleep 1 && influx -execute "SHOW DATABASES" && influx -execute "DROP DATABASE flink" && pgrep influxd | xargs kill

influxd restore -db flink -metadir ~/.influxdb/meta -datadir ~/.influxdb/data $influx_path/influxdb
influxd &
sleep 1 &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_accumulateBusyTimeMs" -format csv > $influx_path/accumulateBusyTimeMs.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_accumulateIdleTimeMs" -format csv > $influx_path/accumulateIdleTimeMs.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_accumulateBackPressuredTimeMs" -format csv > $influx_path/accumulateBackpressuredTimeMs.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_backPressuredTimeMsPerSecond" -format csv > $influx_path/backpressuredTimeMsPerSecond.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_isBackPressured" -format csv > $influx_path/isBackPressured.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_hardBackPressuredTimeMsPerSecond" -format csv > $influx_path/hardBackpressuredTimeMsPerSecond.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_softBackPressuredTimeMsPerSecond" -format csv > $influx_path/softBackpressuredTimeMsPerSecond.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_busyTimeMsPerSecond" -format csv > $influx_path/busyTimeMsPerSecond.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_idleTimeMsPerSecond" -format csv > $influx_path/idleTimeMsPerSecond.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_buffers_outPoolUsage" -format csv > $influx_path/outPoolUsage.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_buffers_inPoolUsage" -format csv > $influx_path/inPoolUsage.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_numBuffersOut" -format csv > $influx_path/numBuffersOut.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_buffers_outputQueueSize" -format csv > $influx_path/outputQueueSize.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_buffers_outputQueueLength" -format csv > $influx_path/outputQueueLength.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_Shuffle_Netty_Output_Buffers_outputQueueLength" -format csv > $influx_path/nettyOutputQueueLength.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_Shuffle_Netty_Output_Buffers_outPoolUsage" -format csv > $influx_path/nettyOutPoolUsage.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_Shuffle_Netty_Output_Buffers_outputQueueSize" -format csv > $influx_path/nettyOutputQueueSize.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_numBuffersOut" -format csv > $influx_path/numBuffersOut.csv &&\
influx -database "flink" -execute "SELECT * FROM taskmanager_job_task_numBuffersOutPerSecond" -format csv > $influx_path/numBuffersOut.csv

