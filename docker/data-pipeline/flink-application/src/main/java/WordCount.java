import java.util.concurrent.TimeUnit;
import org.apache.flink.api.common.RuntimeExecutionMode;
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.common.functions.MapFunction;
//import org.apache.flink.api.common.restartstrategy.RestartStrategies;
//import org.apache.flink.api.common.time.Time;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class WordCount {
    private final static Logger logger = LoggerFactory.getLogger(WordCount.class);

    private final static String JOB_NAME = "word-count-job";

    public static void main(String[] args) throws Exception {
        // 1.准备环境
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        // 设置运行模式 | STREAMING, BATCH , AUTOMATIC
        env.setRuntimeMode(RuntimeExecutionMode.AUTOMATIC);

//        //(可选) 设置重启策略 | 没有指定重启策略，在本地部署时，不需要指定重启策略。
//        env.setRestartStrategy(RestartStrategies.fixedDelayRestart(
//                3, // 尝试重启的次数
//                Time.of(10, TimeUnit.SECONDS) // 间隔
//        ));//以免报: Caused by: org.apache.flink.runtime.JobException: Recovery is suppressed by NoRestartBackoffTimeStrategy

        // 2.加载数据源
        DataStreamSource<String> elementsSource = env.socketTextStream("127.0.0.1", 9000);

        // 3.数据转换
        /**
         * flapMap operator (flatMap 算子)
         * inputStream = { "Hello World", "Hello this is a Flink Job" }
         * operator code : val words = dataStream.flatMap ( input => input.split(" ") )
         * output: ["Hello", "World", "Hello", "this", "is", "a", "Flink", "Job"]
         */

        DataStream<String> originWordsDataStream = elementsSource.flatMap(new FlatMapFunction<String, String>() {
            @Override
            public void flatMap(String element, Collector<String> out) {
                logger.info("element | {}", element);
                String[] wordArr = element.replace(".", " ").replace(",", " ").split(" ");
                for (String word : wordArr) {
                    out.collect(word);
                }
            }
        });

        DataStream<String> filterWordDataStream = originWordsDataStream.filter(new FilterFunction<String>() {
            @Override
            public boolean filter(String word) throws Exception {
                boolean flag = false;
                flag = word.length() > 3 ? true : false;
                return flag;
            }
        } );


        //DataStream 下边为 DataStream 子类
        SingleOutputStreamOperator<String> source = filterWordDataStream.map(new MapFunction<String, String>() {
            @Override
            public String map(String value) {
                return value.toUpperCase();
            }
        });

        // 4.数据输出
        source.print();
        //dataStream.print();

        // 5.执行程序
        env.execute(JOB_NAME);
    }
}