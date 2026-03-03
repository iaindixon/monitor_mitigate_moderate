package ncl.scalable.benchmark_bumbles.common;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Random;

public class SentenceGenerator implements Serializable {
    private final Random rand;
    private final ArrayList<String> wordList;

    public SentenceGenerator() {
        rand = new Random();
        try {
            wordList = prepareWordList();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private ArrayList<String> prepareWordList() throws IOException {
        ArrayList<String> wordList = new ArrayList<>();
        BufferedReader reader = new BufferedReader(new InputStreamReader(getClass().getResourceAsStream("/words.txt")));
        String line;
        while ((line = reader.readLine()) != null) {
            wordList.add(line + " ");
        }
        return wordList;
    }

    public String nextWord(int skewPercent) {
        if (skewPercent > 0 && rand.nextInt(100) < skewPercent) {
            return "skew ";
        }
        else {
            return wordList.get(rand.nextInt(wordList.size()));
        }
    }


    public String getNext(int desiredSize, int skewPercent) {
        StringBuilder builder = new StringBuilder();
        while (desiredSize > 0) {
            String word = nextWord(skewPercent);
            desiredSize -= word.length();
            builder.append(word);
        }
        return builder.toString();
    }

    public String getNext(int desiredSize) {
        return getNext(desiredSize, 0);
    }

}
