FROM strimzi/kafka:0.20.0-kafka-2.5.0
USER root:root
RUN mkdir -p /opt/kafka/plugins/debezium2
RUN mkdir -p /opt/kafka/plugins/debezium

# Download and copy connector, latest was 1.3.0, using 1.2.5 due to issues with latest SQL connector
RUN curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-sqlserver/1.2.5.Final/debezium-connector-sqlserver-1.2.5.Final-plugin.tar.gz | tar xvz
RUN mv ./debezium-connector-sqlserver/* /opt/kafka/plugins/debezium/ 
    
USER 1001
