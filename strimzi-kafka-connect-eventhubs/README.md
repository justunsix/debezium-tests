# Streaming Change Data Capture (CDC) changes to Azure Event Hubs using Strimzi and Debezium on Redhat Openshift

Demo on how to set up a change data capture flow using [Azure Event Hubs](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-about), MS SQL, and [Debezium](https://debezium.io/). Debezium is deployed in a container using the Strimzi Kafka Connect base image to used within Openshift.

This technology can be used where you want to stream database change events (create/update/delete operations in database tables) for processing. Debezium can use change data capture features available in different databases and gives a set of Kafka Connect connectors that takes row-level changes in database table(s) and can make them into event streams that are then sent to Apache Kafka.

Demo and files are based on a split from this GitHub repository [strimzi-kafka-connect-eventhubs](https://github.com/lenisha/aks-tests/tree/master/oshift/strimzi-kafka-connect-eventhubs)

## Table of contents

<!--ts-->
- [Streaming Change Data Capture (CDC) changes to Azure Event Hubs using Strimzi and Debezium on Redhat Openshift](#streaming-change-data-capture-cdc-changes-to-azure-event-hubs-using-strimzi-and-debezium-on-redhat-openshift)
  - [Table of contents](#table-of-contents)
  - [What is in the Demo](#what-is-in-the-demo)
  - [Create SQL DB and enable CDC](#create-sql-db-and-enable-cdc)
  - [Prepare Kafka Connect Image with Debezium Plugin](#prepare-kafka-connect-image-with-debezium-plugin)
  - [Uninstall](#uninstall)
  - [Appendix Example Openshift Settings](#appendix-example-openshift-settings)
  - [Sample Performance Data](#sample-performance-data)
  - [Openshift Monitoring for User Projects](#openshift-monitoring-for-user-projects)
  - [Upgrading Strimzi and Debezium Kafka Connector](#upgrading-strimzi-and-debezium-kafka-connector)
  - [Appendix: Check Log4J Versions related to Vulnerabilities](#appendix-check-log4j-versions-related-to-vulnerabilities)
 <!--te-->

## What is in the Demo

1. Create an SQL database
2. Create Azure Event Hubs
3. Install Debezium
4. Test everything works
5. Example settings and performance data

![Stream with Apache Kafka: Flow of data from MS SQL to Debezium (Kafka Connect) to Azure Event Hubs (Kafka)](./images/MS-SQL-Debezium-KafkaConnection-AzureEventHubs-Kafka.png)

## Create SQL DB and enable CDC

This test used Azure SQL MI instance and as per docs on Debezium (Azure SQL is not yet supported)

- Create Azure SQL MI instance with Public endpoint, make sure port 3342 is enabled on NSG rules for access, get connection string for public endpoint
![Docs](./images/MIConnect.png)

- Enable CDC Capture as per docs: [CDC with ADF](https://docs.microsoft.com/en-us/azure/data-factory/tutorial-incremental-copy-change-tracking-feature-portal)

```sql
create table Persons
(
    PersonID int NOT NULL,
    Name varchar(255),
    Age int
    PRIMARY KEY (PersonID)
);

INSERT INTO Persons (PersonID,Name, Age) VALUES (1, 'Erichsen', 35);
INSERT INTO Persons (PersonID,Name, Age) VALUES (2, 'Kane', 25);

EXEC sys.sp_cdc_enable_db 

EXEC sys.sp_cdc_enable_table
@source_schema = 'dbo',
@source_name = 'Persons', 
@role_name = 'null',
@supports_net_changes = 1
```

### Create Azure EventHubs

We will use Azure EventHubs as Kafka broker and integrate it with Kafka Connect to stream data.

Create Azure EventHubs and take note of access keys
![Docs](./images/KafkaAccess.png)

### Install Strimzi Operator

KafkaConnect with its connectors could be used as a middleman that would stream CDC events to Azure EventHubs Broker.
To install Kafka connect we will use popular Strimzi operator but will only use CRDs to setup KafkaConnect and KafkaConnect SQL Connector.

- Option 1. Install from OperatorsHub  
![Docs](./images/OpsHub.png)

- Option2. Install operator using Helm or YAML manifests

[Install Helm](https://helm.sh/docs/intro/install/)

Install operator described in [Kafka Connect the easy way](https://itnext.io/kafka-connect-on-kubernetes-the-easy-way-b5b617b7d5e9).

```sh
# add helm chart repo for Strimzi
helm repo add strimzi https://strimzi.io/charts/
# install it! (I have used strimzi-kafka as the release name)
helm install strimzi-kafka strimzi/strimzi-kafka-operator

# Verify operator install
helm ls
```

or and [install Kafka Connect as described in the latest Strimzi documents](https://strimzi.io/docs/operators/latest/full/deploying.html#kafka-connect-str) and [Running Debezium on OpenShift](https://debezium.io/documentation/reference/operations/openshift.html)

```sh
export STRIMZI_VERSION=0.20.0
git clone -b $STRIMZI_VERSION https://github.com/strimzi/strimzi-kafka-operator
cd strimzi-kafka-operator

# Switch to an admin user to create security objects as part of installation:
oc login -u system:admin
oc create -f install/cluster-operator && oc create -f examples/templates/cluster-operator
```

Ensure [permissions are set](https://strimzi.io/docs/operators/latest/deploying.html) for the Strimzi Operator for users that will managed it.

## Prepare Kafka Connect Image with Debezium Plugin

KafkaConnect Loads Connectors from its internal `plugin.path`. Debezium is the most popular connector for CDC capture from various Databases.

The default KafkaConnect image does not include Debezium connector so we need extend the image.
The `Dockerfile` in this repo demonstrates how to extend the image.
Note for Debezium some connector versions may have issues with your environment and requires changing the version to have it work.
The following Dockerfile use a base image from the Strimzi operator. The Strimzi version of the base image should correspond with the version installed in Openshift as a cluster operator.

```Dockerfile
FROM strimzi/kafka:0.20.0-kafka-2.5.0
USER root:root
RUN mkdir -p /opt/kafka/plugins/debezium

# Download and copy connector, latest was 1.3.0, using 1.2.5 due to issues with latest SQL connector
RUN curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-sqlserver/1.2.5.Final/debezium-connector-sqlserver-1.2.5.Final-plugin.tar.gz | tar xvz
RUN mv ./debezium-connector-sqlserver/* /opt/kafka/plugins/debezium/ 
    
USER 1001
```

In the directory where the Dockerfile is located, build and push the image (sample is using a repo on DockerHub)

```sh
docker build -t justintungonline/strimzi-kafka-connect-debezium:latest .
docker push justintungonline/strimzi-kafka-connect-debezium:latest
```

### Install Kafka Connect

**Note:** all examples use kubernetes namespace `cdc-kafka`

Now we need to setup KafkaConnect worker to be able to talk to Azure EventHubs as a broker.

- Create a secret to hold AzureEventHubs auth details, replace in this yaml file `eventhubspassword` with your EventHubs Keys and apply:
`oc apply -f eventhubs-secret.yaml`

- Create Credentials for Connector to authenticate to Azure SQL MI, replace in `sqlserver-credentials.properties` fields for `database.password` and user and create a secret:

```sh
oc -n cdc-kafka create secret generic sql-credentials --from-file=sqlserver-credentials.properties
```

Apply to `kafka-connect.yaml` file to set up the Kafka connector. Notes on settings:

- It creates the KafkaConnect worker Cluster, using the image that was created in the step above.
- For TLS settings (e.g. cipher, protocol), set it in the config section of the file. By default in this configuration, the connector will use the highest possible TLS version when connecting to Kafka. See [Strimzi SSL reference](https://strimzi.io/docs/operators/master/using.html#con-common-configuration-ssl-reference) for details on variables and accepted values.

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaConnect
metadata:
  name: kafka-connect-cluster-debezium
  annotations:
    strimzi.io/use-connector-resources: "true"
spec:
  replicas: 1
  bootstrapServers: kafkastore.servicebus.windows.net:9093
  image: lenisha/kafka-connect-debezium:2.5.0-1.3.0
  version: 2.5.0
  config:
    group.id: connect-cluster
    offset.storage.topic: strimzi-connect-cluster-offsets
    config.storage.topic: strimzi-connect-cluster-configs
    status.storage.topic: strimzi-connect-cluster-status
    config.storage.replication.factor: 1
    offset.storage.replication.factor: 1
    status.storage.replication.factor: 1
    config.providers: file
    config.providers.file.class: org.apache.kafka.common.config.provider.FileConfigProvider
  authentication:
    type: plain
    username: $ConnectionString
    passwordSecret:
      secretName: eventhubssecret
      password: eventhubspassword
  tls:
    trustedCertificates: []
  logging:
    type: inline
    loggers:
      rootLogger.level: DEBUG
  resources:
    # Requests will still be limited by maximums/caps set at the Kubernetes level regardless of the request
    # 1 cpu = 1000 milicores
    # 2 Gigibytes = 2048 mb
    requests:
      cpu: "1"
      memory: 2Gi
    limits:
      cpu: "2"
      memory: 2Gi    
  jvmOptions: 
    "-Xmx": "1g"
    "-Xms": "1g"
  readinessProbe: 
    initialDelaySeconds: 15
    timeoutSeconds: 5
  livenessProbe:
    initialDelaySeconds: 15
    timeoutSeconds: 5  

  externalConfiguration:
    volumes:
      - name: connector-config
        secret:
          secretName: sql-credentials  
```

update:

- `bootstrapServers` to point to your AzureEventHubs namespace
- `image` with your connector image
- Apply the manifest

```sh
oc apply -f kafka-connect.yaml -n cdc-kafka
```

- Verify that KafkaConnect Cluster is running

```sh
$ oc get pods -n cdc-kafka
NAME                                                     READY   STATUS    RESTARTS   AGE
kafka-connect-cluster-debezium-connect-bdd84fd96-vj2p9   1/1     Running   0          33m
strimzi-cluster-operator-v0.19.0-7d4f9f5cbf-cxxlx        1/1     Running   0          14h

$ oc get svc -n cdc-kafka
NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
kafka-connect-cluster-debezium-connect-api   ClusterIP   172.30.109.146   <none>        8083/TCP   33m
```

If there are issues, [Strimzi can restart the Kafka Connect cluster](https://strimzi.io/docs/operators/latest/full/using.html#proc-manual-restart-connector-str) after a reconciliation every 2 minutes.

Connect to the Kafka Connect Server using the [Kafka Connect API](https://docs.confluent.io/platform/current/connect/references/restapi.html) and verify that SQL Connector plugin is loaded and available by executing commands in the container shell:

```sh
oc exec -i -n cdc-kafka kafka-connect-cluster-debezium-connect-6668b7d974-wcgnf -- curl localhost:8083/connector-plugins | jq
# or use this command
oc exec -i -n cdc-kafka kafka-connect-cluster-debezium-connect-6668b7d974-wcgnf -- curl -X GET http://kafka-connect-cluster-debezium-connect-api:808
3/connector-plugins | jq .

[
  {
    "class": "io.debezium.connector.sqlserver.SqlServerConnector",
    "type": "source",
    "version": "1.3.0.Final"
  },
  {
    "class": "org.apache.kafka.connect.file.FileStreamSinkConnector",
    "type": "sink",
    "version": "2.5.0"
  },
  {
    "class": "org.apache.kafka.connect.file.FileStreamSourceConnector",
    "type": "source",
    "version": "2.5.0"
  },
  {
    "class": "org.apache.kafka.connect.mirror.MirrorCheckpointConnector",
    "type": "source",
    "version": "1"
  },
  {
    "class": "org.apache.kafka.connect.mirror.MirrorHeartbeatConnector",
    "type": "source",
    "version": "1"
  },
  {
    "class": "org.apache.kafka.connect.mirror.MirrorSourceConnector",
    "type": "source",
    "version": "1"
  }
]

```

Once the KafkaConnect Cluster started it will create topics for its internal operations:
![Docs](./images/KafkaConnectTopics.png)

### Install Debezium SQL Connector

Now we will configure and  install SQLConnector instance. It's typically done using REST api but Strimzi Operator automated it using K8S CRD objects.

Make sure `labels` is pointing to the KafkaConnect cluster we created in the step above

```yaml
apiVersion: kafka.strimzi.io/v1alpha1
kind: KafkaConnector
metadata:
  name: azure-sql-connector
  labels:
    strimzi.io/cluster: kafka-connect-cluster-debezium
spec:
  class: io.debezium.connector.sqlserver.SqlServerConnector
  tasksMax: 1
  config:
    database.hostname: "cdctestsmi.public.144a376e88cf.database.windows.net" 
    database.port: "3342"
    database.dbname: "cdcKafka"
    database.server.name: "cdctestsmi"
    database.user: ${file:/opt/kafka/external-configuration/connector-config/sqlserver-credentials.properties:database.user}
    database.password: ${file:/opt/kafka/external-configuration/connector-config/sqlserver-credentials.properties:database.password}
    table.include.list: "dbo.Persons"
    database.history.kafka.topic: "cdc-updates"
    include.schema.changes: "true" 
    database.history: "io.debezium.relational.history.MemoryDatabaseHistory"
    errors.log.enable: "true"
```

- replace `database.hostname`, `database.dbname` and `database.server.name` with details of your SQL Server

and install and verify the connector is up and running:

```sh
> oc apply -f sqlserver-connector.yaml -n cdc-kafka
> oc get kctr azure-sql-connector -o yaml -n cdc-kafka

apiVersion: kafka.strimzi.io/v1alpha1
kind: KafkaConnector
metadata:
status:
  connectorStatus:
    connector:
      state: RUNNING
      worker_id: 10.129.2.28:8083
    name: azure-sql-connector
    tasks:
    - id: 0
      state: RUNNING
      worker_id: 10.129.2.28:8083
    type: source
  observedGeneration: 1
  tasksMax: 1
```

and verify using Connect API:

```sh
oc exec -i -n cdc-kafka  kafka-connect-cluster-debezium-connect-5d96664b98-tn5j7 -- curl -X GET http://kafka-connect-cluster-debezium-connect-api:8083/c
onnectors | jq .
 
[
  "azure-sql-connector"
]
```

### Test

Debezium SQL Connector creates topics for schema and table updates:

![Docs](./images/KafkaTopicsCDC.png)

For testing we will use `kafkacat` to monitor the Azure Event Hubs.

- configure the connection details for `kafkacat` in `~/.config/kafkacat.conf`

```properties
metadata.broker.list=kafkastore.servicebus.windows.net:9093
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN
sasl.username=$ConnectionString
sasl.password=Endpoint=sb://kafkastore.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=xxxx
socket.timeout.ms=30000
metadata.request.timeout.ms=30000
```

- Listen to topic for events from Azure Event Hubs, topic name is in pattern `servername.dbtable`

```sh
kafkacat -C -b kafkastore.servicebus.windows.net:9093 -t cdctestsmi.dbo.Persons -o beginning
```

- insert the data into the `Persons` table
  
```sql
INSERT INTO Persons (PersonID,Name, Age) VALUES (7, 'Targarien', 125);
```

And see the event apper in the topic:

```json
{"schema":{"type":"struct","fields":[{"type":"struct","fields":[{"type":"int32","optional":false,"field":"PersonID"},{"type":"string","optional":true,"field":"Name"},{"type":"int32","optional":true,"field":"Age"}],"optional":true,"name":"cdctestsmi.dbo.Persons.Value","field":"before"},{"type":"struct","fields":[{"type":"int32","optional":false,"field":"PersonID"},{"type":"string","optional":true,"field":"Name"},{"type":"int32","optional":true,"field":"Age"}],"optional":true,"name":"cdctestsmi.dbo.Persons.Value","field":"after"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"version"},{"type":"string","optional":false,"field":"connector"},{"type":"string","optional":false,"field":"name"},{"type":"int64","optional":false,"field":"ts_ms"},{"type":"string","optional":true,"name":"io.debezium.data.Enum","version":1,"parameters":{"allowed":"true,last,false"},"default":"false","field":"snapshot"},{"type":"string","optional":false,"field":"db"},{"type":"string","optional":false,"field":"schema"},{"type":"string","optional":false,"field":"table"},{"type":"string","optional":true,"field":"change_lsn"},{"type":"string","optional":true,"field":"commit_lsn"},{"type":"int64","optional":true,"field":"event_serial_no"}],"optional":false,"name":"io.debezium.connector.sqlserver.Source","field":"source"},{"type":"string","optional":false,"field":"op"},{"type":"int64","optional":true,"field":"ts_ms"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"id"},{"type":"int64","optional":false,"field":"total_order"},{"type":"int64","optional":false,"field":"data_collection_order"}],"optional":true,"field":"transaction"}],"optional":false,"name":"cdctestsmi.dbo.Persons.Envelope"},"payload":{
    "before":null,
    "after":{"PersonID":7,"Name":"Targarien","Age":125},
    "source":{"version":"1.3.0.Final","connector":"sqlserver","name":"cdctestsmi","ts_ms":1603986207443,"snapshot":"false","db":"cdcKafka","schema":"dbo","table":"Persons","change_lsn":"0000002b:000004f8:0004","commit_lsn":"0000002b:000004f8:0005","event_serial_no":1},"op":"c","ts_ms":1603986211338,"transaction":null}}
```

### Troubleshooting

To see the output of the SQL Connector and KafkaConnect monitor the logs:

```sh
 oc logs kafka-connect-cluster-debezium-connect-5d96664b98-tn5j7 -n cdc-kafka --tail 200 -f
```

You could dynamically change verbosity for the various components as described in this article: [Changing KafkaConnect logging dynamically](https://rmoff.net/2020/01/16/changing-the-logging-level-for-kafka-connect-dynamically/).

The Openshift logs will show as connections as made. Security and TLS settings used by the connector can also be seen:

```log
2021-02-01 23:46:36,177 INFO Kafka startTimeMs: 1612223196177 (org.apache.kafka.common.utils.AppInfoParser) [DistributedHerder-connect-1-1]
2021-02-01 23:46:36,598 INFO ProducerConfig values: 
...
ssl.cipher.suites = null
ssl.enabled.protocols = [TLSv1.2]
ssl.endpoint.identification.algorithm = https
ssl.key.password = null
ssl.keymanager.algorithm = SunX509
ssl.keystore.location = null
sl.keystore.password = null
ssl.keystore.type = JKS
ssl.protocol = TLSv1.2
ssl.provider = null
ssl.secure.random.implementation = null
ssl.trustmanager.algorithm = PKIX
...
 (org.apache.kafka.clients.producer.ProducerConfig) [DistributedHerder-connect-1-1]
```

```sh
# exec into the pod
oc exec -it -n cdc-kafka kafka-connect-cluster-debezium-connect-6668b7d974-wcgnf -- sh

#change log level
curl -s -X PUT -H "Content-Type:application/json"  http://kafka-connect-cluster-debezium-connect-api:8083/admin/loggers/io.debezium -d '{"level": "TRACE"}'
curl -s -X PUT -H "Content-Type:application/json"  http://kafka-connect-cluster-debezium-connect-api:8083/admin/loggers/org.apache.kafka.connect.runtime.WorkerSourceTask -d '{"level": "TRACE"}'
curl -s -X PUT -H "Content-Type:application/json"  http://kafka-connect-cluster-debezium-connect-api:8083/admin/loggers/org.apache.kafka.clients.NetworkClient -d '{"level": "DEBUG"}'
```

Known bugs with history table and workaround:

- [Debezium CDC Connector to send Events to Kafka-Enabled Event Hub #53](https://github.com/Azure/azure-event-hubs-for-kafka/issues/53)
- [Error "The broker does not support DESCRIBE_CONFIGS" #61](https://github.com/Azure/azure-event-hubs-for-kafka/issues/61)

## Uninstall

For a clean uninstall, these are high level steps

1. Remove the pod / set replicas to 0
2. Delete secrets applied
3. Delete Strimzi connectors and kafka connect deployments
4. Remove Strimzi operator

## Appendix Example Openshift Settings

Configuration and Environment details for a Openshift deployment

- Pod scaling: 1
- Burst quota: 2 cores and 8 GB memory
- One endpoint: connect-cluster-debezium-connect-api

```yaml
Selectors:
    strimzi.io/cluster=connect-cluster-debezium
    strimzi.io/kind=KafkaConnect
    strimzi.io/name=connect-cluster-debezium-connect
Replicas:
    1 replica
Strategy:
    Rolling update
Max Unavailable:
    0 
Max Surge:
    1 
Min Ready:
    0 sec 
Revision History Limit:
    10 
Progress Deadline:
    600 sec 

Template
Containers
connect-cluster-debezium-connect
Image: justintungonline/strimzi-kafka-connect-debezium:latest
Command: /opt/kafka/kafka_connect_run.sh
Ports: 8083/TCP (rest-api)
Mount: kafka-metrics-and-logging → /opt/kafka/custom-config/ read-write
Mount: deveventhubssecret → /opt/kafka/connect-password/deveventhubssecret read-write
Mount: ext-conf-connector-config → /opt/kafka/external-configuration/connector-config read-write
CPU: 1 core to 2 cores
Memory: 2 GiB to 2 GiB
Readiness Probe: GET / on port rest-api (HTTP) 15s delay, 5s timeout
Liveness Probe: GET / on port rest-api (HTTP) 15s delay, 5s timeout
Volumes

kafka-metrics-and-logging 
Type:
    config map (populated by a config map) 
Config Map:
    connect-cluster-debezium-connect-config

deveventhubssecret 
Type:
    secret (populated by a secret when the pod is created) 
Secret:
    deveventhubssecret 

ext-conf-connector-config 
Type:
    secret (populated by a secret when the pod is created) 
Secret:
    sql-credentials 
```

### Environment Settings

```log
- KAFKA_CONNECT_CONFIGURATION = offset.storage.topic=connect-cluster-offsetsvalue.converter=org.apache.kafka.connect.json.JsonConverterconfig.storage.topic=connect-cluster-configskey.converter=org.apache.kafka.connect.json.JsonConvertergroup.id=connect-clusterstatus.storage.topic=connect-cluster-statusconfig.providers=fileconfig.providers.file.class=org.apache.kafka.common.config.provider.FileConfigProviderconfig.storage.replication.factor=1key.converter.schemas.enable=falseoffset.storage.replication.factor=1status.storage.replication.factor=1value.converter.schemas.enable=false
- KAFKA_CONNECT_METRICS_ENABLED = false
- KAFKA_CONNECT_BOOTSTRAP_SERVERS = <set to Event Hub address
- STRIMZI_KAFKA_GC_LOG_ENABLED = false
- KAFKA_HEAP_OPTS = -Xms1g -Xmx1g
- KAFKA_CONNECT_TLS = true
- KAFKA_CONNECT_SASL_USERNAME = $ConnectionString
- KAFKA_CONNECT_SASL_MECHANISM = plain
- KAFKA_CONNECT_SASL_PASSWORD_FILE = <set to Kubernetes secret and variable in secret>
```

- About [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

Sample YAML configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: '1'
  creationTimestamp: '2021-28-19T19:29:33Z'
  generation: 1
  labels:
    app.kubernetes.io/instance: connect-cluster-debezium
    app.kubernetes.io/managed-by: strimzi-cluster-operator
    app.kubernetes.io/name: kafka-connect
    app.kubernetes.io/part-of: strimzi-connect-cluster-debezium
    strimzi.io/cluster: connect-cluster-debezium
    strimzi.io/kind: KafkaConnect
    strimzi.io/name: connect-cluster-debezium-connect
  name: connect-cluster-debezium-connect
  namespace: cdc-kafka
  ownerReferences:
    - apiVersion: kafka.strimzi.io/v1beta1
      blockOwnerDeletion: false
      controller: false
      kind: KafkaConnect
      name: connect-cluster-debezium
      uid: ...
  resourceVersion: '...'
  selfLink: >-
    /apis/apps/v1/namespaces/cdc-kafka/deployments/connect-cluster-debezium-connect
  uid: ....
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      strimzi.io/cluster: connect-cluster-debezium
      strimzi.io/kind: KafkaConnect
      strimzi.io/name: connect-cluster-debezium-connect
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      annotations:
        strimzi.io/logging-appenders-hash: ....
      creationTimestamp: null
      labels:
        app.kubernetes.io/instance: connect-cluster-debezium
        app.kubernetes.io/managed-by: strimzi-cluster-operator
        app.kubernetes.io/name: kafka-connect
        app.kubernetes.io/part-of: strimzi-connect-cluster-debezium
        strimzi.io/cluster: connect-cluster-debezium
        strimzi.io/kind: KafkaConnect
        strimzi.io/name: connect-cluster-debezium-connect
    spec:
      affinity: {}
      containers:
        - command:
            - /opt/kafka/kafka_connect_run.sh
          env:
            - name: KAFKA_CONNECT_CONFIGURATION
              value: >
                offset.storage.topic=connect-cluster-offsets

                value.converter=org.apache.kafka.connect.json.JsonConverter

                config.storage.topic=connect-cluster-configs

                key.converter=org.apache.kafka.connect.json.JsonConverter

                group.id=connect-cluster

                status.storage.topic=connect-cluster-status

                config.providers=file

                config.providers.file.class=org.apache.kafka.common.config.provider.FileConfigProvider

                config.storage.replication.factor=1

                key.converter.schemas.enable=false

                offset.storage.replication.factor=1

                producer.connections.max.idle.ms=180000

                status.storage.replication.factor=1

                value.converter.schemas.enable=false
            - name: KAFKA_CONNECT_METRICS_ENABLED
              value: 'false'
            - name: KAFKA_CONNECT_BOOTSTRAP_SERVERS
              value: 'eventhub-dev.servicebus.windows.net:9093'
            - name: STRIMZI_KAFKA_GC_LOG_ENABLED
              value: 'false'
            - name: KAFKA_HEAP_OPTS
              value: '-Xms1g -Xmx1g'
            - name: KAFKA_CONNECT_TLS
              value: 'true'
            - name: KAFKA_CONNECT_SASL_USERNAME
              value: $ConnectionString
            - name: KAFKA_CONNECT_SASL_MECHANISM
              value: plain
            - name: KAFKA_CONNECT_SASL_PASSWORD_FILE
              value: deveventhubssecret/eventhubspassword
          image: 'justintungonline/strimzi-kafka-connect-debezium:latest'
          imagePullPolicy: IfNotPresent
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /
              port: rest-api
              scheme: HTTP
            initialDelaySeconds: 15
            periodSecconds: 10
            successThreshold: 1
            timeoutSeconds: 5
          name: connect-cluster-debezium-connect
          ports:
            - containerPort: 8080
              name: rest-api
              protocol: TCP
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /
              port: rest-api
              scheme: HTTP
            initialDelaySeconds: 15
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5
          resources:
            limits:
              cpu: '2'
              memory: 2Gi
            requests:
              cpu: '1'
              memory: 2Gi
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            - mountPath: /opt/kafka/custom-config/
              name: kafka-metrics-and-logging
            - mountPath: /opt/kafka/connect-password/deveventhubssecret
              name: deveventhubssecret
            - mountPath: /opt/kafka/external-configuration/connector-config
              name: ext-conf-connector-config
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: connect-cluster-debezium-connect
      serviceAccountName: connect-cluster-debezium-connect
      terminationGracePeriodSeconds: 30
      volumes:
        - configMap:
            defaultMode: 420
            name: connect-cluster-debezium-connect-config
          name: kafka-metrics-and-logging
        - name: deveventhubssecret
          secret:
            defaultMode: 288
            secretName: deveventhubssecret
        - name: ext-conf-connector-config
          secret:
            defaultMode: 288
            secretName: sql-credentials
status:
  availableReplicas: 1
  conditions:
    - lastTransitionTime: '....'
      lastUpdateTime: '....'
      message: Deployment has minimum availability.
      reason: MinimumReplicasAvailable
      status: 'True'
      type: Available
    - lastTransitionTime: '....'
      lastUpdateTime: '....'
      message: >-
        ReplicaSet "connect-cluster-debezium-connect-..." has
        successfully progressed.
      reason: NewReplicaSetAvailable
      status: 'True'
      type: Progressing
  observedGeneration: 1
  readyReplicas: 1
  replicas: 1
  updatedReplicas: 1
```

## Sample Performance Data

- With CDC for 3 SQL development databases with low change activity and send updates to 1 Event Hubs
- Openshift single pod performance monitor results over 1 week:
  - Requests 2048 mb memory and uses ~1000 mb (1 GB) on average
  - Requests 1 cpu (1000 milicores) and only using 6-7 milicores on average
  - On network receives 6.5 KiB/s and sends 8.8 KiB/s on average
  - Usage is steady with no spikes for memory, cpu, and network

## Openshift Monitoring for User Projects

Openshift manual references:

1. [Description of the monitoring stack](https://docs.openshift.com/container-platform/4.7/monitoring/understanding-the-monitoring-stack.html)
2. [Configure prerequisites of the monitoring](https://docs.openshift.com/container-platform/4.7/monitoring/configuring-the-monitoring-stack.html)
3. [Enable monitoring of the project](https://docs.openshift.com/container-platform/4.7/monitoring/enabling-monitoring-for-user-defined-projects.html) hosting the connector. From there, manage the metrics, alerts, and dashboards.

Note steps requires `cluster-admin` role and configuration changes.

## Upgrading Strimzi and Debezium Kafka Connector

Follow steps in the [Strimzi's upgrade documentation](https://strimzi.io/docs/operators/latest/deploying.html#assembly-upgrading-kafka-versions-str).
This section summarizes steps and provides examples.

### Kafka Versions

Set the version property for Kafka Connect as the new version of Kafka:

For Kafka Connect, update `KafkaConnect.spec.version`. In this example, use the latest Kafka supported by Strimzi 0.23. For example:

```yaml
spec:
  replicas: 1
  ...
  version: 2.8.0
  ...
```

Upgrade the `dockerfile` base image used for the Debezium Kafka Connect to use the target Strimzi version if applicable. For example:

```dockerfile
FROM quay.io/strimzi/kafka:0.23.0-kafka-2.8.0
...
```

and apply changes with configuration file changes explained listed below.

### Custom Resource Changes

Follow steps in [Strimzi custom resource upgrades](https://strimzi.io/docs/operators/latest/deploying.html#assembly-upgrade-resources-str)

"After you have upgraded Strimzi to 0.23.0, you must ensure that your custom resources are using API version `v1beta2`. You can do this any time after upgrading to 0.23.0, but the upgrades must be completed before the next Strimzi minor version update."

Upgrade steps:

1. Choose whether to convert custom resources via configuration files or change the resources directly. Both methods can be done using a [command line API conversion tool on GitHub](https://github.com/strimzi/strimzi-kafka-operator/releases) under the latest Strimzi release. The custom resources can also be [manually updated](https://strimzi.io/docs/operators/latest/deploying.html#proc-upgrade-kafka-connect-resources-str) which describe the changes in detail.
   1. Converting custom resources [configuration files using API conversion tool](https://strimzi.io/docs/operators/latest/deploying.html#proc-upgrade-cli-tool-files-str)
   2. Converting custom resources [directly using the API conversion tool](https://strimzi.io/docs/operators/latest/deploying.html#proc-upgrade-cli-tool-direct-str)
2. [Upgrade Custom Resource Definitions (CRD)s](https://strimzi.io/docs/operators/latest/deploying.html#proc-upgrade-cli-tool-crds-str) to `v1beta2` using the API conversion tool.

## Appendix: Check Log4J Versions related to Vulnerabilities

In December 2021, several [Log4J vulnerabilities](https://logging.apache.org/log4j/2.x/security.html) were found. The container set up in this demo is not vulnerable to these vulnerabilities for these reasons:

- [CVE-2021-45105](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-45105) (Denial of service) - Debezium and Apache Kafka use version 1.x which is not vulnerable
- [CVE-2021-45046](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-45046) (remote code execution) - Debezium and Apache Kafka use version 1.x which is not vulnerable
- [CVE-2021-4104](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-4104) (Remote code execution) - Log4J and Apache Kafka's default configurations do not use JMSAppender

These steps were used to verify the log4j versions in the container used for this demo.

```sh
# Log into Openshift
oc login ...

# Get the pod running Debezium
oc get pods 

# Log into the shell of the container
oc rsh  --shell=/bin/sh <name of container>

# Navigate to the root of the container
# Verify all instances of log4j properties files and JARs
cd /
find | grep log4j
```

With the listing outputted in the last command, verify all JARs are log4j 1.x. Check each of the properties files. Each property file will show no JMSAppenders are used.
