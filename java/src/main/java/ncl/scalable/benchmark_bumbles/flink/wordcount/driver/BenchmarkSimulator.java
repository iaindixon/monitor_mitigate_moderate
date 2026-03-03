package ncl.scalable.benchmark_bumbles.flink.wordcount.driver;

import ncl.scalable.benchmark_bumbles.common.generator.Generator;
import ncl.scalable.benchmark_bumbles.flink.wordcount.pipeline.WorkSimulator;
import ncl.scalable.benchmark_bumbles.flink.wordcount.sinks.HDRSink;
import org.apache.flink.api.common.JobExecutionResult;
import org.apache.flink.api.common.RuntimeExecutionMode;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.utils.ParameterTool;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.datastream.DataStreamSink;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
/**
 *
 */
public class BenchmarkSimulator {
    private final static int SENTENCE_SIZE = 100;

    public static void main(String[] args) throws Exception {
        // Checking input parameters
        final ParameterTool params = ParameterTool.fromArgs(args);
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setRuntimeMode(RuntimeExecutionMode.STREAMING);
        env.setParallelism(1);
        env.setMaxParallelism(1);
        if (!params.getBoolean("chain-operators", false))
            env.disableOperatorChaining();

        // make parameters available in the web interface
        env.getConfig().setGlobalJobParameters(params);
        short spacingMethod = params.getShort("spacing-method", (short) 0), cutoffMethod = params.getShort(
                "cutoff-method", (short) 0), arrivalProcess = params.getShort("arrival-process",
                (short) 2), workMethod = params.getShort("work-method", (short) 0), calibrationType =
                params.getShort("calibration-type", (short) 0);
        int recordRate = params.getInt("source-rate", 100000), sentenceLength = params.getInt("sentence-size",
                SENTENCE_SIZE), windowSize = params.getInt("window-size",
                1000), windowLimit = params.getInt("window-limit", 60), rollingSize = params.getInt(
                "rolling-size", 0), calibrationSize = params.getInt("calibration-size",
                10), stepStart = params.getInt("step-start", 10000), spikeMultiplier = params.getInt("spike" +
                "-multiplier", 10), spikeDuration = params.getInt("spike-duration", 2), workFrequency = params.getInt("work-frequency",
                1000), middleChunk = params.getInt("middle-chunk", 10), numSteps = params.getInt("num-steps", 4),
                waveFrequency = params.getInt("wave-frequency", 2);
        long sleepAmount = params.getLong("sleep-amount", 0L);
        double undershootFactor = params.getDouble("undershoot-factor", 1.0);
        final DataStreamSink<Tuple2<String, Long>> pipeline = env.addSource(
                new Generator(arrivalProcess, calibrationType, spacingMethod, cutoffMethod, recordRate, sentenceLength, windowSize, windowLimit,
                        calibrationSize, numSteps, stepStart, spikeMultiplier,
                        spikeDuration, undershootFactor)).name("Source").forceNonParallel().flatMap(
                new WorkSimulator(workMethod, calibrationType, windowLimit, calibrationSize,
                        sleepAmount, workFrequency, middleChunk, numSteps, waveFrequency)).name("Work").forceNonParallel().addSink(
                new HDRSink(windowLimit + calibrationSize)).name("Sink").setParallelism(params.getInt("p3", 1));
        JobExecutionResult res = env.execute("Rate-controlled Streaming WordCount");
    }
}
