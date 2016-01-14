#!/bin/bash

for VAR in `env`
do
  if [[ $VAR =~ ^SECOR_PROD_ || $VAR =~ ^SECOR_COMMON_ ]]; then
    if [[ $VAR =~ ^SECOR_PROD_ ]]; then
      secor_name=`echo "$VAR" | sed -r "s/SECOR_PROD_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
      filename=$SECOR_HOME/secor.prod.properties
    elif [[ $VAR =~ ^SECOR_COMMON_ ]]; then
      secor_name=`echo "$VAR" | sed -r "s/SECOR_COMMON_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
      filename=$SECOR_HOME/secor.common.properties
    fi

    env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$secor_name=" $filename; then
        sed -r -i "s@(^|^#)($secor_name)=(.*)@\2=${!env_var}@g" $filename #note that no config values may contain an '@' char
    else
        echo "$secor_name=${!env_var}" >> $filename
    fi
    echo "$secor_name=$env_var"
  fi
done

# Run Secor
cd $SECOR_HOME
java -ea -Dsecor_group=secor_backup -Dlog4j.configuration=log4j.prod.properties -Dconfig=secor.prod.backup.properties -cp secor-0.12-SNAPSHOT.jar:lib/* com.pinterest.secor.main.ConsumerMain
