RUN_TAG=""
CLIENTS_QOS0=""
CLIENTS_QOS1=""
CLIENTS_QOS2=""
DELAY_QOS0=""
DELAY_QOS1=""
DELAY_QOS2=""
MESSAGES_QOS0=""
MESSAGES_QOS1=""
MESSAGES_QOS2=""
SIZE_QOS0=""
SIZE_QOS1=""
SIZE_QOS2=""
CPU="1"
RAM_LIMIT="1g"
BROKER_TYPE="RABBITMQ"
RUN_TESTS="false"
SCENARIO="0"
CONNECT_RPS="1"
WAIT_TIME_CLUSTER_LAUNCH_SECONDS=300
WAIT_TIME_EXPERIMENT_SECONDS=$((WAIT_TIME_CLUSTER_LAUNCH_SECONDS+600))

configure_docker_default_ulimits() {
    echo "Configuring Docker default nofile ulimits"

    local temp_json
    temp_json="$(mktemp)"

    if sudo test -s /etc/docker/daemon.json; then
        if ! command -v jq >/dev/null 2>&1; then
            echo "jq not found. Attempting to install jq..."
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y jq
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y jq
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y jq
            elif command -v apk >/dev/null 2>&1; then
                sudo apk add --no-cache jq
            else
                echo "Could not auto-install jq: unsupported package manager."
                echo "Install jq manually or clear /etc/docker/daemon.json, then rerun."
                rm -f "$temp_json"
                return 1
            fi

            if ! command -v jq >/dev/null 2>&1; then
                echo "jq installation failed. Install jq manually, then rerun."
                rm -f "$temp_json"
                return 1
            fi
        fi

        sudo jq '."default-ulimits" = {"nofile": {"Name": "nofile", "Soft": 262144, "Hard": 262144}}' \
            /etc/docker/daemon.json > "$temp_json"
    else
        cat > "$temp_json" <<'JSON'
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Soft": 262144,
      "Hard": 262144
    }
  }
}
JSON
    fi

    sudo install -m 644 "$temp_json" /etc/docker/daemon.json
    rm -f "$temp_json"

    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl restart docker
    else
        sudo service docker restart
    fi
}

usage() {
    echo "Usage: $0 --run-tag <RUN_TAG> --clients-qos0 <N> --clients-qos1 <N> --clients-qos2 <N> --delay-qos0 <N> --delay-qos1 <N> --delay-qos2 <N> --messages-qos0 <N> --messages-qos1 <N> --messages-qos2 <N> --size-qos0 <BYTES> --size-qos1 <BYTES> --size-qos2 <BYTES> [--scenario <N>] [--connect-rps <N>] [--cpu <N>] [--ram-limit <VALUE>] [--broker-type <TYPE>] [--run-tests <true|false>]"
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --run-tag)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --run-tag"
                usage
            fi
            RUN_TAG="$2"
            shift 2
            ;;
        --clients-qos0)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --clients-qos0"
                usage
            fi
            CLIENTS_QOS0="$2"
            shift 2
            ;;
        --clients-qos1)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --clients-qos1"
                usage
            fi
            CLIENTS_QOS1="$2"
            shift 2
            ;;
        --clients-qos2)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --clients-qos2"
                usage
            fi
            CLIENTS_QOS2="$2"
            shift 2
            ;;
        --delay-qos0)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --delay-qos0"
                usage
            fi
            DELAY_QOS0="$2"
            shift 2
            ;;
        --delay-qos1)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --delay-qos1"
                usage
            fi
            DELAY_QOS1="$2"
            shift 2
            ;;
        --delay-qos2)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --delay-qos2"
                usage
            fi
            DELAY_QOS2="$2"
            shift 2
            ;;
        --messages-qos0)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --messages-qos0"
                usage
            fi
            MESSAGES_QOS0="$2"
            shift 2
            ;;
        --messages-qos1)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --messages-qos1"
                usage
            fi
            MESSAGES_QOS1="$2"
            shift 2
            ;;
        --messages-qos2)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --messages-qos2"
                usage
            fi
            MESSAGES_QOS2="$2"
            shift 2
            ;;
        --size-qos0)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --size-qos0"
                usage
            fi
            SIZE_QOS0="$2"
            shift 2
            ;;
        --size-qos1)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --size-qos1"
                usage
            fi
            SIZE_QOS1="$2"
            shift 2
            ;;
        --size-qos2)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --size-qos2"
                usage
            fi
            SIZE_QOS2="$2"
            shift 2
            ;;
        --cpu)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --cpu"
                usage
            fi
            CPU="$2"
            shift 2
            ;;
        --ram-limit)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --ram-limit"
                usage
            fi
            RAM_LIMIT="$2"
            shift 2
            ;;
        --broker-type)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --broker-type"
                usage
            fi
            BROKER_TYPE="$2"
            shift 2
            ;;
        --run-tests)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --run-tests"
                usage
            fi
            case "$2" in
                true|false) RUN_TESTS="$2" ;;
                *)
                    echo "Invalid value for --run-tests: $2 (expected true or false)"
                    usage
                    ;;
            esac
            shift 2
            ;;
        --scenario)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --scenario"
                usage
            fi
            SCENARIO="$2"
            shift 2
            ;;
        --connect-rps)
            if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                echo "Missing value for --connect-rps"
                usage
            fi
            CONNECT_RPS="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            ;;
    esac
done

if [ -z "$RUN_TAG" ]; then
    usage
fi

if [ -z "$CLIENTS_QOS0" ] || [ -z "$CLIENTS_QOS1" ] || [ -z "$CLIENTS_QOS2" ] || [ -z "$DELAY_QOS0" ] || [ -z "$DELAY_QOS1" ] || [ -z "$DELAY_QOS2" ] || [ -z "$MESSAGES_QOS0" ] || [ -z "$MESSAGES_QOS1" ] || [ -z "$MESSAGES_QOS2" ] || [ -z "$SIZE_QOS0" ] || [ -z "$SIZE_QOS1" ] || [ -z "$SIZE_QOS2" ]; then
    echo "Missing required per-QoS clients, delay, messages, or size arguments"
    usage
fi

# PREREQUESITE: Built image for MZBench Publisher
cd ./mzbench-docker-deployment
chmod +x build.sh
./build.sh
cd ..

cd ./jorammq-deployment
chmod +x build.sh
./build.sh
cd ..

cd ./border/containernet/BORDER/clients/alpine_container/
chmod +x build.sh
./build.sh
cd /home/randerer/



cp -r /home/randerer/border/containernet/BORDER /border-project/containernet

cp /home/randerer/jorammq-deployment/joram_1.22.0 /border-project/joram_1.22.0

cd /border-project/containernet/BORDER

configure_docker_default_ulimits
sleep 30 # Wait for Docker Restart to complete before proceeding

echo "Running BORDER in parallel"
# BORDER example

if [ "$RUN_TESTS" = "true" ]; then
    ( sleep $WAIT_TIME_CLUSTER_LAUNCH_SECONDS; sudo ./start_clients.sh --run-tag "$RUN_TAG" --clients-qos0 "$CLIENTS_QOS0" --clients-qos1 "$CLIENTS_QOS1" --clients-qos2 "$CLIENTS_QOS2" --delay-qos0 "$DELAY_QOS0" --delay-qos1 "$DELAY_QOS1" --delay-qos2 "$DELAY_QOS2" --messages-qos0 "$MESSAGES_QOS0" --messages-qos1 "$MESSAGES_QOS1" --messages-qos2 "$MESSAGES_QOS2" --size-qos0 "$SIZE_QOS0" --size-qos1 "$SIZE_QOS1" --size-qos2 "$SIZE_QOS2" --scenario "$SCENARIO" --connect-rps "$CONNECT_RPS" --name /home/randerer/results/single_broker_results --brokers 1 ) &
fi

sudo ../venv/bin/python3 flexible_router.py --brokers 1 --cpu "$CPU" --ram-limit "$RAM_LIMIT" --type "$BROKER_TYPE"
# sudo ../venv/bin/python3 flexible_router.py --brokers 1 --cpu 1 --ram-limit "1g" --type RABBITMQ
# sleep $WAIT_TIME_EXPERIMENT_SECONDS
# exit 0

# echo "Running clients"
# BORDER benchmarking in second terminal
