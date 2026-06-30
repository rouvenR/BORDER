#!/usr/bin/env bash

set -euo pipefail

WALLTIME="1:00:00"
BASE_START_TIME="$(date +"%Y%m%d%H%M%S")"

# Columns: clients_qos0 delay_qos0 messages_qos0 size_qos0 clients_qos1 delay_qos1 messages_qos1 size_qos1 clients_qos2 delay_qos2 messages_qos2 size_qos2 cpu ram_limit scenario connect_rps
# Example configuration for 10 experiments with step-sized message size QoS 1
# VARIABLE_COLUMN="message_size_qos1"
CONFIGS=(
	"1 20 0 100 100 500 600 100 1 20 0 100 2 1g 0 1"
)
	# "1 20 0 1000 100 500 600 2000 1 20 0 1000 2 1g 0 1"
	# "1 20 0 5000 100 500 600 4000 1 20 0 5000 2 1g 0 1"
	# "1 20 0 10000 100 500 600 6000 1 20 0 10000 2 1g 0 1"
	# "1 20 0 20000 100 500 600 8000 1 20 0 20000 2 1g 0 1"
	# "1 20 0 30000 100 500 600 10000 1 20 0 30000 2 1g 0 1"
	# "1 20 0 40000 100 500 600 12000 1 20 0 40000 2 1g 0 1"
	# "1 20 0 50000 100 500 600 14000 1 20 0 50000 2 1g 0 1"
	# "1 20 0 50000 100 500 600 16000 1 20 0 50000 2 1g 0 1"
	# "1 20 0 50000 100 500 600 18000 1 20 0 50000 2 1g 0 1"



for i in "${!CONFIGS[@]}"; do
	config="${CONFIGS[$i]}"
	read -r clients_qos0 delay_qos0 messages_qos0 size_qos0 clients_qos1 delay_qos1 messages_qos1 size_qos1 clients_qos2 delay_qos2 messages_qos2 size_qos2 cpu ram_limit scenario connect_rps <<< "$config"
	run_tag="${BASE_START_TIME}_${i}__C0${clients_qos0}_D0${delay_qos0}_M0${messages_qos0}_S0${size_qos0}_C1${clients_qos1}_D1${delay_qos1}_M1${messages_qos1}_S1${size_qos1}_C2${clients_qos2}_D2${delay_qos2}_M2${messages_qos2}_S2${size_qos2}_CPU${cpu}_RAM${ram_limit}" # _SC${scenario}_CR${connect_rps}
	echo ram_limit: ${ram_limit}
	oarsub -t deploy -p "host IN (dahu-4,dahu-5,dahu-6,dahu-7,dahu-8,dahu-9,dahu-10,dahu-11,dahu-12,dahu-13,dahu-14,dahu-15,dahu-16,dahu-17,dahu-19,dahu-20,dahu-21,dahu-22,dahu-23,dahu-24,dahu-25)" -l "walltime=01:00:00" "
        kadeploy3 -a border-custom-environment.yaml -o /tmp/${run_tag}.txt;
		./launch_border_via_ssh.sh --run-tag ${run_tag} --clients-qos0 ${clients_qos0} --clients-qos1 ${clients_qos1} --clients-qos2 ${clients_qos2} --delay-qos0 ${delay_qos0} --delay-qos1 ${delay_qos1} --delay-qos2 ${delay_qos2} --messages-qos0 ${messages_qos0} --messages-qos1 ${messages_qos1} --messages-qos2 ${messages_qos2} --size-qos0 ${size_qos0} --size-qos1 ${size_qos1} --size-qos2 ${size_qos2} --scenario ${scenario} --connect-rps ${connect_rps} --cpu ${cpu} --ram-limit ${ram_limit} --broker-type JORAMMQ --run-tests true
        " > "/home/randerer/logs/${run_tag}_oarsub_id.log"
done


# === Data Pipeline ===
# NOTE: adjust -r flag to correct date

# run_tag="${BASE_START_TIME}_data_pipeline"
# oarsub -t deploy -r '2026-05-28 04:30:00' -p "host IN (dahu-4,dahu-5,dahu-6,dahu-7,dahu-8,dahu-9,dahu-10,dahu-11,dahu-12,dahu-13,dahu-14,dahu-15,dahu-16,dahu-17,dahu-19,dahu-20,dahu-21,dahu-22,dahu-23,dahu-24,dahu-25)" -l "walltime=01:30:00" "
# 	kadeploy3 -a border-custom-environment.yaml -o /tmp/${run_tag}.txt;
# 	./automated_data_pipeline.sh --timestamp ${BASE_START_TIME} --variable-column ${VARIABLE_COLUMN}
# 	" > "/home/randerer/logs/${run_tag}_oarsub_id.log"