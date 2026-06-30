#!/usr/bin/env bash

RUN_TAG=""
PUB_MESSAGES_QOS0=unset
PUB_MESSAGES_QOS1=unset
PUB_MESSAGES_QOS2=unset
SUB_MESSAGES=unset
CLIENTS_QOS0=unset
CLIENTS_QOS1=unset
CLIENTS_QOS2=unset
SIZE_QOS0=unset
SIZE_QOS1=unset
SIZE_QOS2=unset
DELAY_QOS0=unset
DELAY_QOS1=unset
DELAY_QOS2=unset
NAME=unset
TOPIC="client-"
NUM_BROKERS=5
DATE=$(date +"%m-%d")
FILE_NAME="_"
BROKER_TYPE="JORAMMQ"
SCENARIO=0
CONNECT_RPS=1

usage()
{
  echo "Usage:  start_clients [ --clients-qos0 CLIENTS_QOS0 ]
                [ --clients-qos1 CLIENTS_QOS1 ]
                [ --clients-qos2 CLIENTS_QOS2 ]
                [ --messages-qos0 MESSAGES_QOS0 ]
                [ --messages-qos1 MESSAGES_QOS1 ]
                [ --messages-qos2 MESSAGES_QOS2 ]
                [ -n | --name NAME]
                [ --size-qos0 SIZE_QOS0 ]
                [ --size-qos1 SIZE_QOS1 ]
                [ --size-qos2 SIZE_QOS2 ]
                [ --delay-qos0 DELAY_QOS0 ]
                [ --delay-qos1 DELAY_QOS1 ]
                [ --delay-qos2 DELAY_QOS2 ]
                [ --scenario SCENARIO ]
                [ --connect-rps CONNECT_RPS ]
                [ -b | --brokers NUM_BROKERS]
                [ -s | --run-tag RUN_TAG ]
                [ --type BROKER_TYPE ]"
  exit 2
}

PARSED_ARGUMENTS=$(getopt -a -n start_clients -o n:b:s: --long clients-qos0:,clients-qos1:,clients-qos2:,messages-qos0:,messages-qos1:,messages-qos2:,name:,size-qos0:,size-qos1:,size-qos2:,delay-qos0:,delay-qos1:,delay-qos2:,scenario:,connect-rps:,brokers:,run-tag:,type: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi

echo "PARSED_ARGUMENTS are $PARSED_ARGUMENTS"
eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    --clients-qos0)  CLIENTS_QOS0="$2" ; shift 2 ;;
    --clients-qos1)  CLIENTS_QOS1="$2" ; shift 2 ;;
    --clients-qos2)  CLIENTS_QOS2="$2" ; shift 2 ;;
    --messages-qos0) PUB_MESSAGES_QOS0="$2" ; shift 2 ;;
    --messages-qos1) PUB_MESSAGES_QOS1="$2" ; shift 2 ;;
    --messages-qos2) PUB_MESSAGES_QOS2="$2" ; shift 2 ;;
    -n | --name)     NAME="$2" ; shift 2 ;;
    --size-qos0)     SIZE_QOS0="$2" ; shift 2 ;;
    --size-qos1)     SIZE_QOS1="$2" ; shift 2 ;;
    --size-qos2)     SIZE_QOS2="$2" ; shift 2 ;;
    --delay-qos0)    DELAY_QOS0="$2" ; shift 2 ;;
    --delay-qos1)    DELAY_QOS1="$2" ; shift 2 ;;
    --delay-qos2)    DELAY_QOS2="$2" ; shift 2 ;;
    --scenario)      SCENARIO="$2" ; shift 2 ;;
    --connect-rps)   CONNECT_RPS="$2" ; shift 2 ;;
    -b | --brokers)      NUM_BROKERS="$2"          ; shift 2 ;;
    -s | --run-tag)   RUN_TAG="$2" ; shift 2 ;;
    --type)          BROKER_TYPE="$2" ; shift 2 ;;
    --) shift; break ;;

    *) echo "Unexpected option: $1 - this should not happen."
       usage ;;
  esac
done

echo $RUN_TAG

if [ -z "$RUN_TAG" ]; then
  echo "Missing required argument: --run-tag <RUN_TAG>"
  usage
fi

echo "Experiment start time: $RUN_TAG"

if [ "$CLIENTS_QOS0" = "unset" ] || [ "$CLIENTS_QOS1" = "unset" ] || [ "$CLIENTS_QOS2" = "unset" ] || [ "$PUB_MESSAGES_QOS0" = "unset" ] || [ "$PUB_MESSAGES_QOS1" = "unset" ] || [ "$PUB_MESSAGES_QOS2" = "unset" ] || [ "$DELAY_QOS0" = "unset" ] || [ "$DELAY_QOS1" = "unset" ] || [ "$DELAY_QOS2" = "unset" ] || [ "$SIZE_QOS0" = "unset" ] || [ "$SIZE_QOS1" = "unset" ] || [ "$SIZE_QOS2" = "unset" ]; then
  echo "Missing required arguments. Provide per-QoS clients, delay, messages, and size values."
  usage
fi

if [ "$CLIENTS_QOS0" -le 0 ] || [ "$CLIENTS_QOS1" -le 0 ] || [ "$CLIENTS_QOS2" -le 0 ]; then
  echo "Clients must be > 0 for all QoS levels."
  exit 2
fi

if [ "$DELAY_QOS0" -le 0 ] || [ "$DELAY_QOS1" -le 0 ] || [ "$DELAY_QOS2" -le 0 ]; then
  echo "Delays must be > 0 milliseconds for all QoS levels."
  exit 2
fi

if [ "$CONNECT_RPS" -le 0 ]; then
  echo "connect-rps must be > 0."
  exit 2
fi

FULL_FOLDER=$NAME

echo "MAIN FOLDER  : $FULL_FOLDER"
echo "FILE NAME    : $NAME"

echo "CLIENTS QoS0 : $CLIENTS_QOS0"
echo "CLIENTS QoS1 : $CLIENTS_QOS1"
echo "CLIENTS QoS2 : $CLIENTS_QOS2"
echo "DELAY QoS0   : $DELAY_QOS0"
echo "DELAY QoS1   : $DELAY_QOS1"
echo "DELAY QoS2   : $DELAY_QOS2"
echo "MESSAGES QoS0: $PUB_MESSAGES_QOS0"
echo "MESSAGES QoS1: $PUB_MESSAGES_QOS1"
echo "MESSAGES QoS2: $PUB_MESSAGES_QOS2"
echo "SIZE QoS0    : $SIZE_QOS0"
echo "SIZE QoS1    : $SIZE_QOS1"
echo "SIZE QoS2    : $SIZE_QOS2"
echo "SCENARIO     : $SCENARIO"
echo "CONNECT_RPS  : $CONNECT_RPS"
echo "TOPIC        : $TOPIC"
echo "Parameters remaining are: $*"

mkdir -p "$FULL_FOLDER"
echo "Using folder: $FULL_FOLDER"

echo "Starting stats and tcp dump"

current_date_time="`date +%Y%m%d%H%M%S`"

docker stats --format "table {{.Container}};{{ .Name }};{{.CPUPerc}};{{.MemUsage}};{{ .MemPerc }};{{.NetIO}}" | ts "\"%F-%H:%M:%S\";" > "$FULL_FOLDER"/"${RUN_TAG}_stats.txt" &
FILE_PID=$!

for ((i=0; i<NUM_BROKERS; i++)); do
  tcpdump -i "s${i}-eth1" src "10.0.${i}.100" -w "$FULL_FOLDER/tcp${i}.pcap" -q 2>/dev/null &
done

sleep 1

TOTAL_PUB_MESSAGES=$((PUB_MESSAGES_QOS0 * CLIENTS_QOS0 + PUB_MESSAGES_QOS1 * CLIENTS_QOS1 + PUB_MESSAGES_QOS2 * CLIENTS_QOS2))
TOTAL_MESSAGES_QOS0=$((PUB_MESSAGES_QOS0 * CLIENTS_QOS0))
TOTAL_MESSAGES_QOS1=$((PUB_MESSAGES_QOS1 * CLIENTS_QOS1))
TOTAL_MESSAGES_QOS2=$((PUB_MESSAGES_QOS2 * CLIENTS_QOS2))

MZBENCH_NUMBER_OF_MESSAGES=$TOTAL_PUB_MESSAGES # Include all QoS streams with per-QoS client counts.

SUB_CLIENT_CONCURRENCY="1"
if [ "$SCENARIO" -eq 0 ]; then
  SUB_CLIENT_CONCURRENCY="5"
fi

echo "Starting subs"
if [ "$SCENARIO" -eq 0 ] || [ "$SCENARIO" -eq 1 ]; then {
  for ((i=0; i<NUM_BROKERS; i++)); do
    for ((j=1; j<=CLIENTS_QOS0; j++)); do
      docker exec -t "mn.sub${i}" python sub_thread.py -h "10.0.${i}.100" -t "root/qos0_client-${j}" -q 0 -m "$MZBENCH_NUMBER_OF_MESSAGES" -c "$SUB_CLIENT_CONCURRENCY" --folder "experiments" --file-name "${RUN_TAG}_SUB_${i}_qos0_client-${j}" &
      if [ $((j % 25)) -eq 0 ]; then
        sleep 1
      fi
    done
    for ((j=1; j<=CLIENTS_QOS1; j++)); do
      docker exec -t "mn.sub${i}" python sub_thread.py -h "10.0.${i}.100" -t "root/qos1_client-${j}" -q 1 -m "$MZBENCH_NUMBER_OF_MESSAGES" -c "$SUB_CLIENT_CONCURRENCY" --folder "experiments" --file-name "${RUN_TAG}_SUB_${i}_qos1_client-${j}" &
      if [ $((j % 25)) -eq 0 ]; then
        sleep 1
      fi
    done
    for ((j=1; j<=CLIENTS_QOS2; j++)); do
      docker exec -t "mn.sub${i}" python sub_thread.py -h "10.0.${i}.100" -t "root/qos2_client-${j}" -q 2 -m "$MZBENCH_NUMBER_OF_MESSAGES" -c "$SUB_CLIENT_CONCURRENCY" --folder "experiments" --file-name "${RUN_TAG}_SUB_${i}_qos2_client-${j}" &
      if [ $((j % 25)) -eq 0 ]; then
        sleep 1
      fi
    done
  done
}
fi

# # Clients
# docker exec -t "mn.sub0" python sub_thread.py -h "10.0.0.100" -t "root/#" -q 0 -m "$MZBENCH_NUMBER_OF_MESSAGES" -c "1" --folder "experiments" --file-name "${RUN_TAG}_SUB_0_qos0_client-1" &

# === Scenario 1 ===
# Datalake:
if [ "$SCENARIO" -eq 1 ]; then {
  for ((j=201; j<=250; j++)); do
    docker exec -t "mn.sub0" python sub_thread.py -h "10.0.0.100" -t "\$share/datalake/root/#" -q 2 -m "600000" -c "1" --folder "experiments" --file-name "${RUN_TAG}_SUB_0_qos2_client-${j}" &
  done
}
fi

# === Scenario 2 ===
# Smart Meter Gateways:
if [ "$SCENARIO" -eq 2 ]; then {
  # Smart Meter Gateways subscriptions (top right in diagram):
  for ((i=0; i<NUM_BROKERS; i++)); do
    for ((j=1; j<=CLIENTS_QOS1; j++)); do
      docker exec -t "mn.sub${i}" python sub_thread.py -h "10.0.${i}.100" -t "root/request/qos1_client-${j}" -q 1 -m "$MZBENCH_NUMBER_OF_MESSAGES" -c "1" --folder "experiments" --file-name "${RUN_TAG}_SUB_${i}_qos1_client-${j}" &
      if [ $((j % 25)) -eq 0 ]; then
        sleep 1
      fi
    done
  done

  # Backoffice Subscription (bottom left in diagram):
  for ((j=3001; j<=3005; j++)); do
    # 24000 messages because 400msg/s * 300 seconds / 5 shared subscription clients
    docker exec -t "mn.sub0" python sub_thread.py -h "10.0.0.100" -t "\$share/backoffice/response/#" -q 1 -m "24000" -c "1" --folder "experiments" --file-name "${RUN_TAG}_SUB_0_qos1_client-${j}" &
  done
}
fi


# === Scenario 3 ===
# if [ "$SCENARIO" -eq 3 ]; then {
  # S:
  # for ((i=0; i<NUM_BROKERS; i++)); do
  #   for ((j=1; j<=CLIENTS_QOS1; j++)); do
  #     docker exec -t "mn.sub${i}" python sub_thread.py -h "10.0.${i}.100" -t "root/response/qos1_client-${j}" -q 1 -m "$MZBENCH_NUMBER_OF_MESSAGES" -c "5" --folder "experiments" --file-name "${RUN_TAG}_SUB_${i}_qos1_client-${j}" &
  #   done
  # done

  # Backoffice:
  # docker exec -t "mn.sub0" python sub_thread.py -h "10.0.0.100" -t "root/#" -q 2 -m "120000000" -c "1" --folder "experiments" --file-name "${RUN_TAG}_SUB_0_datalake" &
  # Smart Meter Gateways:
  # for ((i=0; i<NUM_BROKERS; i++)); do
  #   for ((j=1; j<=CLIENTS_QOS1; j++)); do
  #     docker exec -t "mn.sub${i}" python sub_thread.py -h "10.0.${i}.100" -t "root/request/qos1_client/worker-${j%50}" -q 1 -m "$MZBENCH_NUMBER_OF_MESSAGES" -c "5" --folder "experiments" --file-name "${RUN_TAG}_SUB_${i}_qos1_client-${j}" &
  #   done
  # done
# }
# fi

# === Changing Clients ===
if [ "$SCENARIO" -eq 4 ]; then {
  for ((j=1; j<=10; j++)); do
    MESSAGES=$((CLIENTS_QOS0+CLIENTS_QOS1+CLIENTS_QOS2))
    docker exec -t "mn.sub0" python sub_thread.py -h "10.0.0.100" -t "\$share/shared/root/#" -q 2 -m "$MESSAGES" -c "1" --folder "experiments" --file-name "${RUN_TAG}_SUB_0_qos2_client-${j}" &
  done
}
fi

sleep 10

echo "Starting pubs"

RATE_QOS0_PER_MINUTE=$(((1000*60)/DELAY_QOS0)) # messages per second per client
RATE_QOS1_PER_MINUTE=$(((1000*60)/DELAY_QOS1)) # messages per second per client
RATE_QOS2_PER_MINUTE=$(((1000*60)/DELAY_QOS2)) # messages per second per client

DURATION_QOS0_MS=$((PUB_MESSAGES_QOS0*DELAY_QOS0))
DURATION_QOS1_MS=$((PUB_MESSAGES_QOS1*DELAY_QOS1))
DURATION_QOS2_MS=$((PUB_MESSAGES_QOS2*DELAY_QOS2))
DURATION_MS=$DURATION_QOS0_MS
if [ "$DURATION_QOS1_MS" -gt "$DURATION_MS" ]; then DURATION_MS=$DURATION_QOS1_MS; fi
if [ "$DURATION_QOS2_MS" -gt "$DURATION_MS" ]; then DURATION_MS=$DURATION_QOS2_MS; fi
DURATION=$(((DURATION_MS + 999)/1000)) # shared scenario duration in seconds (ceil)
DURATION_QOS0=$(((DURATION_QOS0_MS + 999)/1000))
DURATION_QOS1=$(((DURATION_QOS1_MS + 999)/1000))
DURATION_QOS2=$(((DURATION_QOS2_MS + 999)/1000))

case "$SCENARIO" in
  0) SCENARIO_FILE="different_qos.bdl" ;;
  1) SCENARIO_FILE="scenario_1_industrial_sites.bdl" ;;
  2) SCENARIO_FILE="scenario_2_smart_electricity_meter.bdl" ;;
  3) SCENARIO_FILE="scenario_3_mobile_clients.bdl" ;;
  4) SCENARIO_FILE="changing_number_of_clients.bdl" ;;
  *) echo "Unknown SCENARIO: $SCENARIO"; exit 2 ;;
esac

for ((i=0; i<NUM_BROKERS; i++)); do
  docker exec -t -w /vmq_mzbench "mn.pub${i}" /app/mzbench/bin/mzbench run_local "/vmq_mzbench/scenarios/${SCENARIO_FILE}" --env topic="root/${TOPIC}${i}" --env clients_qos0="$CLIENTS_QOS0" --env clients_qos1="$CLIENTS_QOS1" --env clients_qos2="$CLIENTS_QOS2" --env duration_qos0="$DURATION_QOS0" --env duration_qos1="$DURATION_QOS1" --env duration_qos2="$DURATION_QOS2" --env rate_qos0="$RATE_QOS0_PER_MINUTE" --env rate_qos1="$RATE_QOS1_PER_MINUTE" --env rate_qos2="$RATE_QOS2_PER_MINUTE" --env messages="$MZBENCH_NUMBER_OF_MESSAGES" --env broker="10.0.${i}.100" --env size_qos0="$SIZE_QOS0" --env size_qos1="$SIZE_QOS1" --env size_qos2="$SIZE_QOS2" --env connect_rps="$CONNECT_RPS"
#  BACK_PID=$!
done
# wait $BACK_PID


WAIT_TIME_PUBLISHER_SETUP=20
HIGHEST_NUMBER_OF_CLIENTS=$CLIENTS_QOS0
if [ "$CLIENTS_QOS1" -gt "$HIGHEST_NUMBER_OF_CLIENTS" ]; then HIGHEST_NUMBER_OF_CLIENTS=$CLIENTS_QOS1; fi
if [ "$CLIENTS_QOS2" -gt "$HIGHEST_NUMBER_OF_CLIENTS" ]; then HIGHEST_NUMBER_OF_CLIENTS=$CLIENTS_QOS2; fi
CLIENT_CONNECTION_RPS=$CONNECT_RPS
CLIENT_CONNECTION_DURATION=$((HIGHEST_NUMBER_OF_CLIENTS/CLIENT_CONNECTION_RPS + 30)) # Add buffer to ensure all clients are connected before starting measurements
EXPERIMENT_DURAION=$((DURATION+WAIT_TIME_PUBLISHER_SETUP+CLIENT_CONNECTION_DURATION))

if [ "$SCENARIO" -eq 2 ] || [ "$SCENARIO" -eq 4 ]; then
  # For the different_qos scenario, we can end the experiment as soon as all publishers have finished, since they run sequentially and the subs are fast enough to keep up.
  EXPERIMENT_DURAION=$((EXPERIMENT_DURAION + 600)) # Add extra time to ensure all messages are received before ending the experiment
fi

sleep $EXPERIMENT_DURAION

broker_type_lower=$(echo "$BROKER_TYPE" | tr '[:upper:]' '[:lower:]')
docker logs "mn.pub0" > "/home/randerer/logs/${RUN_TAG}_pub0_docker.log"
docker logs "mn.sub0" > "/home/randerer/logs/${RUN_TAG}_sub0_docker.log"
docker logs "mn.${broker_type_lower}0" > "/home/randerer/logs/${RUN_TAG}_${broker_type_lower}0_docker.log"
lscpu > "/home/randerer/logs/${RUN_TAG}_lscpu.log"
free -h > "/home/randerer/logs/${RUN_TAG}_free.log"


if [ "$BROKER_TYPE" = "JORAMMQ" ]; then
    docker cp "mn.jorammq0:/home/jorammq/log/server-0.0.log" "/home/randerer/logs/${RUN_TAG}_jorammq0_internal.log"
fi

kill -9 $FILE_PID
killall -9 tcpdump

exit 1