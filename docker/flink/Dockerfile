FROM flink:1.19.3-scala_2.12-java17

ARG FLINK_VERSION=1.19.3
ARG FLINK_KAFKA_CONNECTOR_VERSION=3.3.0-1.19
ARG FLINK_SHADED_HADOOP_VERSION=2.8.3-10.0
ARG PAIMON_VERSION=1.4.1

ADD https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/${FLINK_KAFKA_CONNECTOR_VERSION}/flink-sql-connector-kafka-${FLINK_KAFKA_CONNECTOR_VERSION}.jar /opt/flink/lib/flink-sql-connector-kafka-${FLINK_KAFKA_CONNECTOR_VERSION}.jar
ADD https://repo.maven.apache.org/maven2/org/apache/flink/flink-json/${FLINK_VERSION}/flink-json-${FLINK_VERSION}.jar /opt/flink/lib/flink-json-${FLINK_VERSION}.jar
ADD https://repo.maven.apache.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/${FLINK_SHADED_HADOOP_VERSION}/flink-shaded-hadoop-2-uber-${FLINK_SHADED_HADOOP_VERSION}.jar /opt/flink/lib/flink-shaded-hadoop-2-uber-${FLINK_SHADED_HADOOP_VERSION}.jar
ADD https://repo.maven.apache.org/maven2/org/apache/paimon/paimon-flink-1.19/${PAIMON_VERSION}/paimon-flink-1.19-${PAIMON_VERSION}.jar /opt/flink/lib/paimon-flink-1.19-${PAIMON_VERSION}.jar

RUN chmod 0644 /opt/flink/lib/flink-sql-connector-kafka-${FLINK_KAFKA_CONNECTOR_VERSION}.jar \
    /opt/flink/lib/flink-json-${FLINK_VERSION}.jar \
    /opt/flink/lib/flink-shaded-hadoop-2-uber-${FLINK_SHADED_HADOOP_VERSION}.jar \
    /opt/flink/lib/paimon-flink-1.19-${PAIMON_VERSION}.jar
