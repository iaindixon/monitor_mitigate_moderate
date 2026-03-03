package ncl.scalable.benchmark_bumbles.common.generator;

import ncl.scalable.benchmark_bumbles.common.HDRHistogramOutputter;
import ncl.scalable.benchmark_bumbles.common.SentenceGenerator;
import org.HdrHistogram.Histogram;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.streaming.api.functions.source.RichParallelSourceFunction;
import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.io.Serializable;

/**
 *  Generator, contains logic for running Basic or Spaced generation loop.
 *
 * @author Iain Dixon
 */
public class Generator extends RichParallelSourceFunction<Tuple2<String, Long>> implements Serializable {
    /** the length of each sentence (in chars) */
    final int sentenceLength;
    /** the length of a window (default 1000ms) */
    final int windowSize;
    /** number of windows in an experiment */
    final int windowLimit;
    /** spike height */
    final int spikeMultiplier;
    /** cutoff method used to end window */
    final CutOff cutOff;
    /** method type of record arrival process (default 0: constant) */
    final ArrivalProcess arrivalProcess;
    /** generator to create record payloads */
    final SentenceGenerator generator;
    /** number of windows used for calibration */
    final int calibrationSize;
    /** the type of calibration for experiment */
    final short calibrationType;
    /** HDRHistogramOutputter object, used to output */
    final HDRHistogramOutputter hdrHistogramOutputter;
    /** how many records are sent per window */
    private final int recordRate;
    /** method type of how values are spaced in a transmission window (default 0: All at Once) */
    private final SpacingType spacingType;
    /** percentage of window utilisation to target */
    final double undershootFactor;
    /** generator metrics output */
    private final StringBuilder output;
    /** stream controller variable */
    volatile boolean running = true;

    /**
     * Constructor, sets all simulation variables.
     *
     * @param arrivalProcess   Arrival method
     * @param spacingMethod    Spacing method
     * @param cutoffMethod     Cutoff method
     * @param recordRate       Rate at which sentences are sent into system
     * @param sentenceLength   Length of each sentence
     * @param windowSize       Size of a transmission window
     * @param windowLimit      Limit on number of transmission windows
     * @param calibrationSize  Number of windows used to "warm up/calibrate" the systems
     * @param stepStart        (int) Starting rate of the stepped arrival process
     * @param undershootFactor Undershoot factor
     */
    public Generator(short arrivalProcess, short calibrationType, short spacingMethod, short cutoffMethod, int recordRate,
                     int sentenceLength, int windowSize, int windowLimit, int calibrationSize, int numSteps, int stepStart,
                     int spikeMultiplier, int spikeDuration, double undershootFactor) {
        // Input Validation
        if (recordRate < 0) {
            throw new IllegalArgumentException("Rate must be greater than 0.");
        }
        if (sentenceLength < 0) {
            throw new IllegalArgumentException("String length must be greater than 0.");
        }
        if (windowSize < 0) {
            throw new IllegalArgumentException("Window size must be greater than 0.");
        }
        if (windowLimit < 0) {
            throw new IllegalArgumentException("Window limit must be greater than 0.");
        }
        if (spacingMethod < 0 || spacingMethod >= SpacingType.values().length) {
            throw new IllegalArgumentException("Spacing type must be within Spacing enum's bounds.");
        }
        if (cutoffMethod < 0 || cutoffMethod >= CutoffType.values().length)
            throw new IllegalArgumentException("Cutoff type must be within Cutoff enum's bounds.");
        if (undershootFactor < 0 || undershootFactor > 1) {
            throw new IllegalArgumentException("Undershoot factor must be between 0 and 1.");
        }
        this.recordRate = (int)(((long)recordRate * windowSize) / 1000);
        this.sentenceLength = sentenceLength;
        this.windowSize = windowSize;
        this.windowLimit = (windowLimit * 1000) / windowSize;
        this.spacingType = SpacingType.values()[spacingMethod];
        this.cutOff = new CutOff(cutoffMethod, windowSize, undershootFactor);
        this.arrivalProcess = new ArrivalProcess(arrivalProcess, calibrationType, this.recordRate, this.windowLimit,
                calibrationSize, numSteps, stepStart, spikeMultiplier, spikeDuration);
        this.calibrationSize = (calibrationSize * 1000) / windowSize;
        this.calibrationType = calibrationType;
        this.undershootFactor = undershootFactor;
        this.spikeMultiplier = spikeMultiplier;
        generator = new SentenceGenerator();
        hdrHistogramOutputter = new HDRHistogramOutputter();
        output = new StringBuilder(
                "average_rate,sentence_length,window_size,undershoot_window_size,window_limit,spacing_name," +
                        "cutoff_type,current_rate,sentences_processed,end_time,emit_duration,work_duration," +
                        "sleep_duration,padding_duration,transmission_diff,number_of_sleeps,remaining_time," +
                        "between_loop_duration,number_of_transmitted_windows,spike\n");
    }

    /**
     * Saves the metrics for a window to the output StringBuilder object. Saves to file in outputWindowMetrics method.
     *
     * @param currentRate            Rate of current window
     * @param sentencesProcessed     Number of tuples transmitted in window
     * @param endTime                Time at end of window
     * @param emitDuration           Duration of time it took to transmit window
     * @param workDuration           Duration of time in which work occurred within window
     * @param sleepDuration          Duration of time in which sleep occurred within window
     * @param paddingDuration        Duration of time used to pad out the end of window
     * @param transmissionDifference Difference between emitDuration and windowLength
     * @param numberOfSleeps         Number of sleeps triggered during window
     * @param remainingTime          Time remaining in window i.e., Math.max(0, transmissionDifference)
     * @param bewteenLoopDuration    Time between transmission loops
     * @param windowIndex            Index of the current window
     */
    void saveWindowMetrics(int currentRate, int sentencesProcessed, long endTime, long emitDuration, long workDuration,
                           long sleepDuration, long paddingDuration, long transmissionDifference, int numberOfSleeps,
                           long remainingTime, long bewteenLoopDuration, int windowIndex) {
        output.append(recordRate).append(',').append(sentenceLength).append(',').append(windowSize).append(',').append(
                (long) windowSize * undershootFactor).append(',').append(windowLimit).append(',').append(
                spacingType).append(',').append(cutOff).append(',').append(currentRate).append(',').append(
                sentencesProcessed).append(',').append(endTime).append(',').append(emitDuration).append(',').append(
                workDuration).append(',').append(sleepDuration).append(',').append(paddingDuration).append(',').append(
                transmissionDifference).append(',').append(numberOfSleeps).append(',').append(remainingTime).append(
                ',').append(bewteenLoopDuration).append(',').append(windowIndex).append(',').append(spikeMultiplier).append('\n');
    }

    /**
     * Outputs window metrics from output StringBuilder to "generator.csv" file.
     */
    void outputWindowMetrics() {
        try (PrintWriter outputFile = new PrintWriter("generator.csv")) {
            outputFile.println(output);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            System.err.println("Ran into a file not found exception when outputting windows metrics.");
        }
    }

    /**
     * Performs the generators generation and transmission loop, creating and sending records into the pipeline based
     * on the spacingType.
     * @param out Stream output where values are sent into pipeline
     */
    @Override
    public void run(SourceContext<Tuple2<String, Long>> out) throws Exception {
        System.out.println("BEGIN GENERATOR");
        long generatorStart = System.currentTimeMillis();
        int windowIndex = 0, currentRate, sentencesProcessed, numberOfSleeps, windowLimitAdjusted;
        long timeOverran = 0, emitStartTime, remainingTime = 0, sleepDuration;
        windowLimitAdjusted = windowLimit + calibrationSize * calibrationType;
        int[] windowGeneratorRate = new int[windowLimitAdjusted];
        Histogram[] transmitWindows = new Histogram[windowLimitAdjusted];
        Histogram[] interArrivalWindows = new Histogram[windowLimitAdjusted];
        for (int i = 0; i < windowLimitAdjusted; i++) {
            transmitWindows[i] = new Histogram(0);
            interArrivalWindows[i] = new Histogram(0);
        }
        System.out.println("***** " + spacingType + " LOOP START *****");
        // Start running the actual generation
        long betweenLoopStart = System.currentTimeMillis();
        while (running && windowIndex < windowLimitAdjusted) {
            currentRate = arrivalProcess.getCurrentArrivalRate();
            sentencesProcessed = 0;
            numberOfSleeps = 0;
            sleepDuration = 0;
            long bewteenLoopDuration = System.currentTimeMillis() - betweenLoopStart;
            betweenLoopStart = System.currentTimeMillis();
            emitStartTime = System.currentTimeMillis();
            while (sentencesProcessed < currentRate) {
                if (cutOff.checkCutOff(emitStartTime, System.currentTimeMillis(), timeOverran)) {
                    break;
                }
                out.collect(new Tuple2<>(generator.getNext(sentenceLength), System.nanoTime()));
                sentencesProcessed++;
                // If the generator is set to perform the spacing generation loop
                if (spacingType == SpacingType.SPACED) {
                    try {
                        long sleepTime = 1L;
                        if (currentRate > remainingTime) {
                            if (remainingTime > 0 && sentencesProcessed % Math.ceil((double)currentRate / remainingTime) == 0) {
                                Thread.sleep(sleepTime);
                                numberOfSleeps++;
                                sleepDuration += (int) sleepTime;
                            }
                        }
                    } catch (InterruptedException e) {
                        System.err.println("Something went wrong whilst performing spacing.");
                        throw new RuntimeException(e);
                    }
                }
            }
            long emitDuration = System.currentTimeMillis() - emitStartTime,
                    transmissionDifference = windowSize - emitDuration,
                    workDuration = emitDuration - sleepDuration, paddingDuration = Math.max(0, transmissionDifference);
            remainingTime = (long) (Math.max(windowSize * this.undershootFactor - workDuration, 0));
            if (transmissionDifference > 0) {
                try {
                    Thread.sleep(paddingDuration);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    System.err.println("Interrupted while adding padding sleep.");
                }
                timeOverran = 0;
            }
            else {
                timeOverran = -transmissionDifference;
            }
            saveWindowMetrics(currentRate, sentencesProcessed, System.currentTimeMillis(), emitDuration, workDuration,
                    sleepDuration, paddingDuration, transmissionDifference, numberOfSleeps, remainingTime, bewteenLoopDuration,
                    windowIndex);
            windowIndex++;
        }
        System.out.println("***** " + spacingType + " LOOP FINISH *****");
        outputWindowMetrics();
        hdrHistogramOutputter.outputHDRHistogram(transmitWindows, "window,value,percentile,total_count\n",
                "window_transmit");
        hdrHistogramOutputter.outputHDRHistogram(interArrivalWindows, "window,value,percentile,total_count\n",
                "window_interarrival");
        Histogram transmit = new Histogram(0);
        Histogram interArrival = new Histogram(0);
        for (int i = 0; i < windowLimit; i++) {
            transmit.add(transmitWindows[i]);
            interArrival.add(interArrivalWindows[i]);
        }
        hdrHistogramOutputter.outputHDRHistogram(transmit, "value,percentile,total_count\n", "total_transmit");
        hdrHistogramOutputter.outputHDRHistogram(interArrival, "value,percentile,total_count\n", "total_interarrival");
        StringBuilder output = new StringBuilder("window,rate\n");
        for (int i = 0; i < windowLimitAdjusted; i++) {
            output.append(i).append(",").append(windowGeneratorRate[i]).append("\n");
        }
        try (PrintWriter outputter = new PrintWriter("window_rate.csv")) {
            outputter.println(output);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            System.err.println("Ran into a file not found exception when outputting rate.");
        }
        System.out.println("END GENERATOR");
        System.out.println("Elapsed Time: " + (System.currentTimeMillis() - generatorStart));
        out.close();
    }

    @Override
    public void cancel() {
        running = false;
    }

}

