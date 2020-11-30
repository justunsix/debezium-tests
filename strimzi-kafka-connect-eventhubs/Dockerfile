FROM strimzi/kafka:0.19.0-kafka-2.5.0
USER root:root
RUN mkdir -p /opt/kafka/plugins/debezium

# DOWNLOAD and copy connector
RUN curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-sqlserver/1.3.0.Final/debezium-connector-sqlserver-1.3.0.Final-plugin.tar.gz | tar xvz
RUN mv ./debezium-connector-sqlserver/* /opt/kafka/plugins/debezium/ 
    
USER 1001