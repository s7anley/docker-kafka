# Kafka and Zookeeper

FROM java:openjdk-8-jre

ENV DEBIAN_FRONTEND noninteractive
ENV SCALA_VERSION 2.11
ENV KAFKA_VERSION 0.9.0.0
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV SECOR_HOME /opt/secor

# Install Kafka, Zookeeper and other needed things
RUN apt-get update -y && \
    apt-get install -y zookeeper wget supervisor dnsutils vim net-tools && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    wget -q http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    wget -q https://s3-eu-west-1.amazonaws.com/rsin-executables/secor-0.12-SNAPSHOT-bin.tar.gz -O /tmp/secor-0.12-SNAPSHOT-bin.tar.gz && \
    mkdir -p "$SECOR_HOME" && \
    tar -zxvf /tmp/secor-0.12-SNAPSHOT-bin.tar.gz -C "$SECOR_HOME" && \
    rm /tmp/secor-0.12-SNAPSHOT-bin.tar.gz

ADD scripts/ /usr/bin/

# Supervisor config
ADD supervisor/ /etc/supervisor/conf.d/

# 2181 is zookeeper, 9092 is kafka
EXPOSE 2181 9092

CMD ["supervisord", "-n"]
