package ncl.scalable.benchmark_bumbles.common.generator;

import java.io.Serializable;

/**
 * Implementations of Stepped, Periodic, Poisson, and Envelope arrival processes taken from Stuart Jamieson and
 * Matthew Forshaw.
 * <a href="https://github.com/MattForshaw/DEBS23_WindowingAndWeighting/tree/main/implementation/SourceFunctions">
 *     Github</a>
 * <p>
 * Additional implementations of uniform process and spike function by Iain Dixon
 */
public class ArrivalProcess implements Serializable {
    /** Name of the type of arrival process */
    private final ProcessType arrivalProcessName;
    /** Name of the type of calibration */
    private final short calibrationType;
    /** Rate of arrival process's arrival rate */
    private final int arrivalRate;
    /** Number of experimental windows */
    private final int numExpWindows;
    /** Number of calibration windows */
    private final int numCalWindows;
    /** Number of steps for the step arrival process */
    private final int numSteps;
    /** Starting point of the step arrival process */
    private final int stepStart;
    /** Multiplier on arrivalRate for the spike arrival process */
    private final int spikeMultiplier;
    /** Duration of spike for the spike arrival process */
    private final int spikeDuration;
    /** Starting time of the arrival process */
    private final long startTime;

    /**
     * ArrivalProcess constructor, provides the arrival process type, average arrival rate of each process, and total
     * number of transmission windows.
     *
     * @param arrivalProcessType (short) Type of arrival process, used to specify which arrival process to use
     * @param calibrationType    (short) Type of calibration for the experiment, 0 - no calibration, 1 - before
     *                           experiment calibration, 2 - before and after experiment calibration
     * @param arrivalRate        (int) Average arrival rate for the given process
     * @param numExpWindows      (int) Number of windows in experiment
     * @param numCalWindows      (int) Number of windows in burn-in
     * @param numSteps           (int) Number of steps for the step arrival process
     * @param stepStart          (int) Value of the start of the stepped arrival process
     * @param spikeMultiplier    (int) Multiplier for the spike arrival process
     * @param spikeDuration      (int) The number of windows the spike should occur in
     */
    public ArrivalProcess(short arrivalProcessType, short calibrationType, int arrivalRate, int numExpWindows,
                          int numCalWindows, int numSteps, int stepStart, int spikeMultiplier, int spikeDuration) {

        this.arrivalProcessName = ProcessType.values()[arrivalProcessType];
        this.calibrationType = calibrationType;
        this.arrivalRate = arrivalRate;
        this.numExpWindows = numExpWindows;
        this.numCalWindows = numCalWindows;
        this.numSteps = numSteps;
        this.stepStart = stepStart;
        this.spikeMultiplier = spikeMultiplier;
        this.spikeDuration = spikeDuration;
        this.startTime = System.currentTimeMillis();
    }

    /**
     * Wrapper to get the current arrival rate for each process, calls private functions which compute the window arrival
     * rate for each arrival process type.
     *
     * @return (int) Number of tuples to transmit for the current window according to the arrival process.
     */
    public int getCurrentArrivalRate() {
        int currentWindow = (int)(System.currentTimeMillis() - startTime) / 1000;
        if (calibrationType != 0 && (currentWindow < numCalWindows || currentWindow >= numExpWindows + numCalWindows * (calibrationType - 1))) {
            return arrivalRate;
        } else {
            if (calibrationType != 0) {
                currentWindow -= numCalWindows;
            }
            switch (arrivalProcessName) {
                case STEPPED:
                    return getSteppedArrivalRate(currentWindow);
                case PERIODIC:
                    return getPeriodicArrivalRate(currentWindow);
                case POISSON:
                    return getPoissonArrivalRate();
                case ENVELOPE:
                    return getEnvelopeArrivalRate(currentWindow);
                case SPIKE:
                    return getSpikeArrivalRate(currentWindow);
                default:
                    return arrivalRate;
            }
        }

    }

    /**
     * Gets the current window's arrival rate for a stepped process.
     *
     * @param currentWindow (int) The current window of the arrival process
     * @return (int) Current window's arrival rate for the stepped process.
     */
    private int getSteppedArrivalRate(int currentWindow) {
        int stepRate = arrivalRate / numSteps, stepSize = numExpWindows / numSteps;
        return stepStart + stepRate * (1 + ( currentWindow / stepSize));
    }

    /**
     * Gets the current window's arrival rate for a periodic process.
     *
     * @param currentWindow (int) The current window of the arrival process
     * @return (int) Current window's arrival rate for the periodic process
     */
    private int getPeriodicArrivalRate(int currentWindow) {
        int amplitude = arrivalRate / 2, phaseShift = 0, verticalShift = arrivalRate;
        double omega = 0.5, horizontalStepSize = 1.0;
        return (int) Math.round(
                (amplitude * (Math.sin(omega * ((currentWindow / horizontalStepSize) + phaseShift)))) + verticalShift);
    }

    /**
     * Calculates the arrival rate for a poisson process given a specific windows arrival rate.
     *
     * @return (int) Current window's arrival rate for the poisson process.
     */
    private int poissonArrivalRateHelper(int poissonRate) {
        return (int) Math.round(Math.log(1.0 - Math.random()) * -poissonRate);
    }

    /**
     * Gets the current window's arrival rate for a poisson process.
     *
     * @return (int) Current window's arrival rate for the poisson process.
     */
    private int getPoissonArrivalRate() {
        return poissonArrivalRateHelper(arrivalRate);
    }

    /**
     * Gets the current window's arrival rate for an envelope process.
     *
     * @param currentWindow (int) The current window of the arrival process
     * @return (int) Current window's arrival rate for the envelope process.
     */
    private int getEnvelopeArrivalRate(int currentWindow) {
        int periodicRate = getPeriodicArrivalRate(currentWindow);
        return poissonArrivalRateHelper(periodicRate);
    }

    /**
     * Gets the current window's arrival rate for a spike process.
     *
     * @param currentWindow (int) The current window of the arrival process
     * @return (int) Current window's arrival rate for the spike process.
     */
    private int getSpikeArrivalRate(int currentWindow) {
        if (currentWindow > (((numExpWindows / 2)) - (spikeDuration / 2)) && currentWindow <= (numExpWindows / 2 + (spikeDuration / 2))) {
            return arrivalRate * spikeMultiplier;
        }
        else {
            return arrivalRate;
        }
    }

    /**
     * Type of arrival process, the shape the arrival process makes when looking at rate over time.
     */
    private enum ProcessType {
        UNIFORM, STEPPED, PERIODIC, POISSON, ENVELOPE, SPIKE
    }

    /**
     * Type of calibration, where the calibration windows in the experiment are.
     */
    private enum CalibrationType {
        NONE, BEFORE, BEFOREANDAFTER;
    }
}
