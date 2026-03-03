package ncl.scalable.benchmark_bumbles.flink.wordcount.pipeline;

import org.apache.flink.api.common.functions.RichFlatMapFunction;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.util.Collector;
import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Simulates pipeline workload, time it takes for a pipeline operator to process tuples.
 *
 * Note: The FlatMap connector is used in case we don't want a one-to-one transformation (although we do use that in
 * this project). The Rich connector is used to provide us with access to the state of opening and closing the
 * metrics collected from this class.
 */
public class WorkSimulator extends RichFlatMapFunction<Tuple2<String, Long>, Tuple2<String, Long>> {
    private static final long serialVersionUID = 1L;
    /** Total number of windows in simulation */
    private final int totalWindows;
    /** Sleep to simulate work */
    private final long sleepAmount;
    /** Frequency of how often a sleep (representing work) should be introduced */
    private final int workFrequency;
    /** Lower bound of middle workload spike */
    private int lowerBound;
    /** Upper bound of middle workload spike */
    private int upperBound;
    /** Type of workload */
    private final WorkType workType;
    /** Index of records received during the workload period */
    private final AtomicInteger index;
    /**  */
    private int modifiedTotalWindows;
    private long runStartTime;
    private transient long[] workSimulated;
    private final int numSteps;
    /** The frequency of how many windows pass before work is simulated for the wave workload */
    private final int waveFrequency;
    private final short calibrationType;
    private final int calibrationWindows;

    /**
     * Constructor for WorkSimulator, sets class parameters
     *
     * @param workType     Type of workload
     * @param transmissionWindows Total number of windows in simulation
     * @param sleepAmount  Sleep to simulate work
     */
    public WorkSimulator(short workType, short calibrationType, int transmissionWindows, int calibrationWindows,
                         long sleepAmount, int workFrequency, int middleChunk, int numSteps, int waveFrequency) {
        this.index = new AtomicInteger();
        this.sleepAmount = sleepAmount;
        this.totalWindows = transmissionWindows;
        this.modifiedTotalWindows = transmissionWindows;
        this.calibrationType = calibrationType;
        this.calibrationWindows = calibrationWindows;
        this.workFrequency = workFrequency;
        this.workType = WorkType.values()[workType];
        this.lowerBound = (int) ((double) transmissionWindows / 2 - (double) middleChunk / 2);
        this.upperBound = (int) ((double) transmissionWindows / 2 + (double) middleChunk / 2);
        if (calibrationType > 0) {
            this.lowerBound += calibrationWindows;
            this.modifiedTotalWindows += calibrationWindows;
            if (calibrationType > 1) {
                this.upperBound += calibrationWindows;
                this.modifiedTotalWindows += calibrationWindows * (calibrationType - 1);
            }
        }
        this.numSteps = numSteps;
        this.waveFrequency = waveFrequency;
    }

    @Override
    public void open(Configuration parameters) {
        workSimulated = new long[modifiedTotalWindows];
        for (int i = 0; i < modifiedTotalWindows; i++) {
            workSimulated[i] = 0;
        }
        runStartTime = System.nanoTime();
    }

    @Override
    public void close() throws Exception {
        super.close();
        System.out.println("Work Simulator finished.");
        System.out.println("Work Execution time: " + (System.nanoTime() - runStartTime) / 1000000000);
        StringBuilder output = new StringBuilder("window,workload\n");
        for (int i = 0; i < modifiedTotalWindows; i++) {
            output.append(i).append(",").append(workSimulated[i]).append("\n");
        }
        try (PrintWriter out = new PrintWriter("workload_simulated.csv")) {
            out.println(output);
        } catch (FileNotFoundException e) {
            System.err.println("Ran into a file not found exception when outputting work simulated.");
        }
    }

    private boolean isCalibration(int indexWindow) {
        switch (calibrationType) {
            case 4:
            case 3:
            case 2:
                if (indexWindow >= (calibrationWindows + totalWindows)) {
                    return true;
                }
            case 1:
                if (indexWindow < calibrationWindows) {
                    return true;
                }
            default:
                return false;
        }
    }

    @Override
    public void flatMap(Tuple2<String, Long> tuple, Collector<Tuple2<String, Long>> collector) throws Exception {
        int indexWindow = (int) ((System.nanoTime() - runStartTime) / 1000000000);
        long workStartTime = System.currentTimeMillis();
        if (workFrequency != 0 && !isCalibration(indexWindow)) {
            switch (workType) {
                case CONSTANT:
                    workConstant();
                    break;
                case AFTER:
                    workAfter(indexWindow);
                    break;
                case STEPPED:
                    workStepped(calibrationType != 0 ? indexWindow - calibrationWindows : indexWindow);
                    break;
                case WAVE:
                    workWave(indexWindow);
                    break;
            }
        }
        // Check if we completely overrun the transmission and calibration windows, if so we dump all metrics into the
        // last window.
        if (indexWindow >= workSimulated.length) {
            workSimulated[workSimulated.length - 1] += System.currentTimeMillis() - workStartTime;
        } else {
            workSimulated[indexWindow] += System.currentTimeMillis() - workStartTime;
        }
        collector.collect(tuple);
    }

    /**
     * Provides a constant workload simulation
     *
     */
    private void workConstant() {
        if (index.getAndIncrement() % workFrequency == 0) {
            try {
                Thread.sleep(sleepAmount);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
    }

    /**
     * Provides a workload for the middle 40% - 80% of windows
     *
     * @param indexWindow Index of the current window
     */
    private void workAfter(int indexWindow) {
        if (indexWindow >= (lowerBound) && indexWindow <= (upperBound)) {
            workConstant();
        }
    }

    /**
     * Provides a workload which steps up from 0 to 16ms of workload across the middle 40% - 80% of windows
     *
     * @param indexWindow Index of the current window
     */
    private void workStepped(int indexWindow) {
        if (index.getAndIncrement() % (workFrequency * (numSteps - (indexWindow / (totalWindows / numSteps)))) == 0) {
            try {
                Thread.sleep(sleepAmount);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
    }


    private void workWave(int indexWindow) {
        if (indexWindow % waveFrequency == 0 && index.getAndIncrement() % workFrequency == 0) {
            try {
                Thread.sleep(sleepAmount);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
    }

    /**
     * Enum for which type of tuple work simulation should be run.
     */
    enum WorkType {
        CONSTANT, AFTER, STEPPED, WAVE
    }

}
