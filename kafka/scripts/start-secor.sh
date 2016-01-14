#!/bin/sh

# Optional ENV variables:
# * SECOR_KAFKA_SEED_BROKER_LIST
# * SECOR_ZOOKEEPER_QUORUM
# * SECOR_S3_BUCKET
# * SECOR_MAX_FILE_AGE_SEC
# * SECOR_MAX_FILE_SIZE_BYTES
# * SECOR_AWS_ACCESS_KEY
# * SECOR_AWS_SECRET_KEY

# Name of one (random) Kafka broker host that is used to retrieve metadata.
if [ ! -z "$SECOR_KAFKA_SEED_BROKER_LIST" ]; then
    echo "kafka seed broker list: $SECOR_KAFKA_SEED_BROKER_LIST"
    sed -r -i "s/(kafka.seed.broker.host)=(.*)/\1=$SECOR_KAFKA_SEED_BROKER_LIST/g" $SECOR_HOME/secor.prod.properties
fi

# List of Kafka Zookeeper servers.
if [ ! -z "$SECOR_ZOOKEEPER_QUORUM" ]; then
    echo "zookeeper quorum: $SECOR_ZOOKEEPER_QUORUM"
    sed -r -i "s/(zookeeper.quorum)=(.*)/\1=$SECOR_ZOOKEEPER_QUORUM/g" $SECOR_HOME/secor.prod.properties
fi

# Name of the s3 bucket where log files are stored.
if [ ! -z "$SECOR_S3_BUCKET" ]; then
    echo "secor S3 bucket: $SECOR_S3_BUCKET"
    sed -r -i "s/(secor.s3.bucket)=(.*)/\1=$SECOR_S3_BUCKET/g" $SECOR_HOME/secor.prod.properties
fi

if [ ! -z "$SECOR_MAX_FILE_AGE_SEC" ]; then
    echo "secor max file age sec: $SECOR_MAX_FILE_AGE_SEC"
    sed -r -i "s/(secor.max.file.age.seconds)=(.*)/\1=$SECOR_MAX_FILE_AGE_SEC/g" $SECOR_HOME/secor.prod.properties
fi

if [ ! -z "$SECOR_MAX_FILE_SIZE_BYTES" ]; then
    echo "secor max file size bytes: $SECOR_MAX_FILE_SIZE_BYTES"
    sed -r -i "s/(secor.max.file.size.bytes)=(.*)/\1=$SECOR_MAX_FILE_SIZE_BYTES/g" $SECOR_HOME/secor.prod.properties
fi

sed -r -i "s/(aws.access.key)=(.*)/\1=$SECOR_AWS_ACCESS_KEY/g" $SECOR_HOME/secor.common.properties
sed -r -i "s/(aws.secret.key)=(.*)/\1=$SECOR_AWS_SECRET_KEY/g" $SECOR_HOME/secor.common.properties

# Run Secor
cd $SECOR_HOME
java -ea -Dsecor_group=secor_backup -Dlog4j.configuration=log4j.prod.properties -Dconfig=secor.prod.backup.properties -cp secor-0.12-SNAPSHOT.jar:lib/* com.pinterest.secor.main.ConsumerMain
