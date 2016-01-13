#!/bin/bash

# Optional ENV variables:
#
# Any variable prefixed with KAFKA will be transformed to name of parameter for example
# KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'false' will set auto.create.topic to false
#
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * TOPICS: List of topics to create after bootstrap e.g. "kafka:1:1" <name>:<partitions>:<replication_factor>

# Configure advertised host/port if we run in helios
if [ ! -z "$HELIOS_PORT_kafka" ]; then
    ADVERTISED_HOST=`echo $HELIOS_PORT_kafka | cut -d':' -f 1 | xargs -n 1 dig +short | tail -n 1`
    ADVERTISED_PORT=`echo $HELIOS_PORT_kafka | cut -d':' -f 2`
fi

# Set the external host and port
if [ ! -z "$ADVERTISED_HOST" ]; then
    echo "advertised host: $ADVERTISED_HOST"
    sed -r -i "s/#(advertised.host.name)=(.*)/\1=$ADVERTISED_HOST/g" $KAFKA_HOME/config/server.properties
fi
if [ ! -z "$ADVERTISED_PORT" ]; then
    echo "advertised port: $ADVERTISED_PORT"
    sed -r -i "s/#(advertised.port)=(.*)/\1=$ADVERTISED_PORT/g" $KAFKA_HOME/config/server.properties
fi

# Set the zookeeper chroot
if [ ! -z "$ZK_CHROOT" ]; then
    # wait for zookeeper to start up
    until /usr/share/zookeeper/bin/zkServer.sh status; do
      sleep 0.1
    done

    # create the chroot node
    echo "create /$ZK_CHROOT \"\"" | /usr/share/zookeeper/bin/zkCli.sh || {
        echo "can't create chroot in zookeeper, exit"
        exit 1
    }

    # configure kafka
    sed -r -i "s/(zookeeper.connect)=(.*)/\1=localhost:2181\/$ZK_CHROOT/g" $KAFKA_HOME/config/server.properties
fi

### START LICENSED CODE ###
# The following is copied from https://github.com/wurstmeister/kafka-docker/blob/master/start-kafka.sh
# under ASL v2 license

for VAR in `env`
do
  if [[ $VAR =~ ^KAFKA_ && ! $VAR =~ ^KAFKA_HOME ]]; then
    kafka_name=`echo "$VAR" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$kafka_name=" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s@(^|^#)($kafka_name)=(.*)@\2=${!env_var}@g" $KAFKA_HOME/config/server.properties #note that no config values may contain an '@' char
    else
        echo "$kafka_name=${!env_var}" >> $KAFKA_HOME/config/server.properties
    fi
    echo "$kafka_name=$env_var"
  fi
done

### END LICENSED CODE ###

if [ -e /tmp/kafka-custom.sh ]; then
  sh /tmp/kafka-custom.sh
fi

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties &
KAFKA_SERVER_PID=$!

while netstat -lnt | awk '$4 ~ /:9092$/ {exit 1}'; do echo "waiting"; sleep 1; done

# Create topics as configured
if [[ -n $TOPICS ]]; then
    IFS=','; for topicToCreate in $TOPICS; do
        echo $topicToCreate
        IFS=':' read -a topicConfig <<< "$topicToCreate"
        $KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor ${topicConfig[2]} --partition ${topicConfig[1]} --topic "${topicConfig[0]}"
    done
fi

wait $KAFKA_SERVER_PID