#!/bin/bash
# This script, when run as a cron job, allows you to approximate
# a multilevel feedback queue scheduling algorithm when using
# SLURM's priority queue algorithm. 
# This can increase responsiveness substantially.

# Constants
EVAL_MAX_QUANTA=2
OWNERS_MAX_QUANTA=4
RENTERS_MAX_QUANTA=4
RENTERS_LIST="/etc/slurm/axon-renters.conf"

# Allows you to have quanta at sub-minute resolution.
COUNT=${1}
SLEEP_PERIOD=${2}
if [ -z ${COUNT} ]; then
	COUNT=6
fi
if [ -z ${SLEEP_PERIOD} ]; then
	SLEEP_PERIOD=10
fi

while [ ${COUNT} -ne 0 ];
do
	# Info about the head job / highest priority item in queue
	HEAD_INFO=$(squeue -h -t PD -o "%i,%Q,%q,%y,%a"  | head -1)
	HEAD_JOB_ID=$(echo ${HEAD_INFO} | cut -d, -f1)
	HEAD_PRIORITY=$(echo ${HEAD_INFO} | cut -d, -f2)
	HEAD_QUEUE=$(echo ${HEAD_INFO} | cut -d, -f3)
	HEAD_QUANTUM=$(echo ${HEAD_INFO} | cut -d, -f4)
	HEAD_ACCOUNT=$(echo ${HEAD_INFO} | cut -d, -f5)

	# Freshly submitted jobs and jobs that have been refreshed from the expired
	# queue get evaluated first.
	if [ ${HEAD_QUEUE} = "eval" ]; then
		# Move it to the owner or renter queues if the quantum limit is used up.
		if [ ${HEAD_QUANTUM} -ge ${EVAL_MAX_QUANTA} ]; then
			# Determine if the job is submitted by an owner or a renter.
			RENT_ACCOUNTS=($( cat ${RENTERS_LIST}))
			OWNER_FLAG=1
			for RENT_ACCOUNT in ${RENT_ACCOUNTS[@]};
			do
				if [ ${HEAD_ACCOUNT} = ${RENT_ACCOUNT} ];
				then
					OWNER_FLAG=0
				fi
			done
			if [ ${OWNER_FLAG} -eq 1 ]; then
				scontrol update job ${HEAD_JOB_ID} nice=0 qos=owners
				sleep ${SLEEP_PERIOD}
				COUNT=$(( ${COUNT} - 1 ))
				continue
			elif [ ${OWNER_FLAG} -eq 0 ]; then
				scontrol update job ${HEAD_JOB_ID} nice=0 qos=renters
				sleep ${SLEEP_PERIOD}
				COUNT=$(( ${COUNT} - 1 ))
				continue
			# This shouldn't happen, but if it does send jobs that are somehow ambiguous
			# to the expired queue.
			else
				scontrol update job ${HEAD_JOB_ID} nice=0 qos=expired
				sleep ${SLEEP_PERIOD}
				COUNT=$(( ${COUNT} - 1 ))
				continue
			fi
		fi
		NEW_QUANTUM=$(( ${HEAD_QUANTUM} + 1 ))
		scontrol update job ${HEAD_JOB_ID} nice=${NEW_QUANTUM}
	# Go through owner jobs until the quanta limit is reached.
	elif [ ${HEAD_QUEUE} = "owners" ]; then
		if [ ${HEAD_QUANTUM} -ge ${OWNERS_MAX_QUANTA} ]; then
			scontrol update job ${HEAD_JOB_ID} nice=0 qos=expired
			sleep ${SLEEP_PERIOD}
			COUNT=$(( ${COUNT} - 1 ))
			continue
		fi
		NEW_QUANTUM=$(( ${HEAD_QUANTUM} + 1 ))
		scontrol update job ${HEAD_JOB_ID} nice=${NEW_QUANTUM}
	# Go through renter jobs until the quanta limit is reached.
	elif [ ${HEAD_QUEUE} = "renters" ]; then
		if [ ${HEAD_QUANTUM} -ge ${OWNERS_MAX_QUANTA} ]; then
			scontrol update job ${HEAD_JOB_ID} nice=0 qos=expired
			sleep ${SLEEP_PERIOD}
			COUNT=$(( ${COUNT} - 1 ))
			continue
		fi
		NEW_QUANTUM=$(( ${HEAD_QUANTUM} + 1 ))
		scontrol update job ${HEAD_JOB_ID} nice=${NEW_QUANTUM}
	# Once all jobs reach the expired QoS, send them back to eval to trickle
	# down again.
	elif [ ${HEAD_QUEUE} = "expired" ]; then
		for JOB_ID in $(squeue -h -t PD -o "%A");
		do
			scontrol update job ${JOB_ID} nice=0 qos=eval
		done
	# If, for some reason, the job is in a QoS other than the ones for MLFQ.
	# Switch it to eval and increment the quantum by 1.
	else
		scontrol update job ${HEAD_JOB_ID} nice=$(( ${HEAD_QUANTUM} + 1 )) qos=eval
	fi
	sleep ${SLEEP_PERIOD}
	COUNT=$(( ${COUNT} - 1 ))
done
