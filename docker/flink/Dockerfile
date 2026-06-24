FROM flink:1.19.3-scala_2.12-java17

ARG FLINK_VERSION=1.19.3
ARG FLINK_KAFKA_CONNECTOR_VERSION=3.3.0-1.19

ADD https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/${FLINK_KAFKA_CONNECTOR_VERSION}/flink-sql-connector-kafka-${FLINK_KAFKA_CONNECTOR_VERSION}.jar /opt/flink/lib/flink-sql-connector-kafka-${FLINK_KAFKA_CONNECTOR_VERSION}.jar
ADD https://repo.maven.apache.org/maven2/org/apache/flink/flink-json/${FLINK_VERSION}/flink-json-${FLINK_VERSION}.jar /opt/flink/lib/flink-json-${FLINK_VERSION}.jar

RUN chmod 0644 /opt/flink/lib/flink-sql-connector-kafka-${FLINK_KAFKA_CONNECTOR_VERSION}.jar \
    /opt/flink/lib/flink-json-${FLINK_VERSION}.jar
