package com.github.frtu.vm.sample;

import java.util.Arrays;
import java.util.List;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;

/**
 * Skeleton for a Flink DataStream Job.
 *
 * <p>For a tutorial how to write a Flink application, check the
 * tutorials and examples on the <a href="https://flink.apache.org">Flink Website</a>.
 *
 * <p>To package your application into a JAR file for execution, run
 * 'mvn clean package' on the command line.
 *
 * <p>If you change the name of the main class (with the public static void main(String[] args))
 * method, change the respective entry in the POM.xml file (simply search for 'mainClass').
 */
public class DataStreamJob {
    public static void main(String[] args) throws Exception {
        // Sets up the execution environment, which is the main entry point
        // to building Flink applications.
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        List<String> lines = Arrays.asList(
                "Apache Flink is a powerful stream processor",
                "Flink is great for both batch and stream",
                "Stream processing with Flink is efficient"
        );

        DataStream<String> text = env.fromCollection(lines, TypeInformation.of(String.class));

        DataStream<Tuple2<String, Integer>> counts = text
                .flatMap(new Tokenizer())
                .keyBy(tuple -> tuple.f0)
                .sum(1);

        counts.print();
        env.execute("Flink 2.0 WordCount with Static Data");
    }
}
