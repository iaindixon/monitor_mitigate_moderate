package ncl.scalable.benchmark_bumbles.flink.wordcount.sinks;

import ncl.scalable.benchmark_bumbles.common.HDRHistogramOutputter;
import org.HdrHistogram.Histogram;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.sink.RichSinkFunction;

import java.io.FileNotFoundException;
import java.io.PrintWriter;

public class HDRSink extends RichSinkFunction<Tuple2<String, Long>> {

    private final int totalWindows;
    private final HDRHistogramOutputter hdrOutputter;
    private transient Histogram[] latencyWindows;
    private transient long[] countsPerWindow;
    private long runStartTime;
    private int totalCount;

    public HDRSink(int totalWindows) {
        this.totalWindows = totalWindows * 2;
        totalCount = 0;
        hdrOutputter = new HDRHistogramOutputter();
    }

    @Override
    public void open(Configuration parameters) {
        totalCount = 0;
        latencyWindows = new Histogram[(int) (totalWindows)];
        countsPerWindow = new long[totalWindows];
        for (int i = 0; i < totalWindows; i++) {
            latencyWindows[i] = new Histogram(0);
        }
        runStartTime = System.nanoTime();
    }


    @Override
    public void invoke(Tuple2<String, Long> value, Context context) {
        int index = (int) ((System.nanoTime() - runStartTime) / 1000000000);
        if (index >= totalWindows) {
            index = totalWindows - 1;
        }
        if (System.nanoTime() >= value.f1) {
            // Record per-object latencies for a window
            latencyWindows[index].recordValue((System.nanoTime() - value.f1) / 1000000);
        }
        else {
            latencyWindows[index].recordValue(0L);
        }
        // Records the number of records seen every second
        countsPerWindow[index]++;
        totalCount++;
    }

    @Override
    public void close() throws Exception {
        super.close();
        long runTime = (System.nanoTime() - runStartTime) / 1000000000;
        System.out.println(totalCount);
        System.out.println("Sink Execution time: " + runTime + " seconds");
        // Outputs throughputs array
        outputThroughputs();
        // Output HDR Histogram for total run
        outputLatency();
        outputWindowLatencies();
        try (PrintWriter out = new PrintWriter("total_throughput.csv")) {
            out.println("TotalThroughput");
            out.println(totalCount / runTime);
        }
    }

    private void outputThroughputs() {
        StringBuilder output = new StringBuilder("window,throughput\n");
        for (int i = 0; i < totalWindows; i++) {
            output.append(i).append(",").append(countsPerWindow[i]).append("\n");
        }
        try (PrintWriter out = new PrintWriter("window_throughput.csv")) {
            out.println(output);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            System.err.println("Ran into a file not found exception when outputting throughput.");
        }
    }

    private void outputLatency() {
        Histogram latency = new Histogram(0);
        for (int i = 0; i < totalWindows; i++) {
            latency.add(latencyWindows[i]);
        }
        hdrOutputter.outputHDRHistogram(latency, "value,percentile,total_count", "total_latency");
    }

    private void outputWindowLatencies() {
        hdrOutputter.outputHDRHistogram(latencyWindows, "window,value,percentile,total_count", "window_latency");
    }

}
