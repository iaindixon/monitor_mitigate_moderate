package ncl.scalable.benchmark_bumbles.common;

import org.HdrHistogram.Histogram;
import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.io.Serializable;

/**
 * Outputs HdrHistogram objects to a provided file.
 *
 * @author Iain Dixon
 */
public class HDRHistogramOutputter implements Serializable {

    /**
     * Creates the string representation of the HDRHistogram object at the 0, 50, 90, 99.9, 99.99, 99.999, 100
     * percentiles
     *
     * @param histogram HDRHistogram object containing data
     * @param index     Window index
     * @return String containing representation of HDRHistogram
     */
    private String collectHdrHistogram(Histogram histogram, int index) {
        StringBuilder histogramString = new StringBuilder();
        double[] percentiles = new double[]{0.0, 50.0, 90.0, 99.0, 99.9, 99.99, 99.999, 100.0};
        for (double percentile : percentiles) {
            long value = histogram.getValueAtPercentile(percentile);
            if (index != Integer.MIN_VALUE) {
                histogramString.append(index).append(",");
            }
            histogramString.append(value).append(",").append(percentile).append(",").append(
                    histogram.getCountAtValue(value)).append("\n");
        }
        return histogramString.toString();
    }

    /**
     * Creates the string representation of the HDRHistogram object
     *
     * @param histogram HDRHistogram object containing data
     * @return String containing representation of HDRHistogram
     */
    private String collectHdrHistogram(Histogram histogram) {
        return collectHdrHistogram(histogram, Integer.MIN_VALUE);
    }

    /**
     * Outputs HdrHistogram histogram to CSV file fileName with header line fileHeader for the given percentiles.
     *
     * @param histograms HdrHistogram list containing window data
     * @param fileHeader CSV file header line
     * @param fileName   CSV file name
     */
    public void outputHDRHistogram(Histogram[] histograms, String fileHeader, String fileName) {
        StringBuilder output = new StringBuilder(fileHeader + "\n");
        int index = 0;
        for (Histogram histogram : histograms) {
            output.append(collectHdrHistogram(histogram, index));
            index++;
        }
        try (PrintWriter out = new PrintWriter(fileName + ".csv")) {
            out.println(output);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            System.err.println("Ran into a file not found exception when outputting histogram.");
        }
    }

    /**
     * Outputs HdrHistogram histogram to CSV file fileName with header line fileHeader for percentiles 0.0, 50.0, 90.0,
     * 99.0, 99.9, 99.99, 99.999, 100.0.
     *
     * @param histogram  HdrHistogram containing data
     * @param fileHeader CSV file header line
     * @param fileName   CSV file name
     */
    public void outputHDRHistogram(Histogram histogram, String fileHeader, String fileName) {
        StringBuilder output = new StringBuilder(fileHeader + "\n");
        output.append(collectHdrHistogram(histogram));
        try (PrintWriter out = new PrintWriter(fileName + ".csv")) {
            out.println(output);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            System.err.println("Ran into a file not found exception when outputting histogram.");
        }

    }
}
