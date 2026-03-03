package ncl.scalable.benchmark_bumbles.common.generator;

import java.io.Serializable;

/**
 * Cut-off implementation which ends window if window size is exceeded.
 */
public class CutOff implements Serializable {
    /**
     * type of cutoff
     */
    private final CutoffType cutoffType;
    /**
     * length of window adjusted with undershoot factor
     */
    private final long windowSize;

    /**
     * Sets the cutoffType and calculates the undershot window size.
     *
     * @param cutoffType       CutoffType of cutoff
     * @param windowSize       Total unadjusted window size
     * @param undershootFactor Undershoot factor to adjust window size for cutoff
     */
    public CutOff(short cutoffType, long windowSize, double undershootFactor) {
        this.cutoffType = CutoffType.values()[cutoffType];
        this.windowSize = (long) (windowSize * undershootFactor);
    }

    /**
     * Checks if the current window emit duration exceeds the desired window length based on cutoff logic.
     *
     * @param emitStartTime         Start time of emit period
     * @param emitCurrentTime       Current time of emit period
     * @param previousWindowOverrun Amount of time overran in previous window (for cutoff next)
     * @return True if window should be cutoff, false otherwise.
     */
    public boolean checkCutOff(long emitStartTime, long emitCurrentTime, long previousWindowOverrun) {
        switch (cutoffType) {
            case CUTOFF_CURRENT:
                if (emitCurrentTime - emitStartTime >= windowSize) {
                    return true;
                }
            case CUTOFF_NEXT:
                if (emitCurrentTime - emitStartTime >= windowSize - previousWindowOverrun) {
                    return true;
                }
        }
        return false;
    }

    @Override
    public String toString() {
        return cutoffType.toString();
    }
}
