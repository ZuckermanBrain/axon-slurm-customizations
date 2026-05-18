#!/bin/bash
# Streamlined SLURM-MLFQ Scheduler (Renters QOS Removed)

# Constants
EVAL_MAX_QUANTA=2
OWNERS_MAX_QUANTA=4

# Allows you to have quanta at sub-minute resolution.
COUNT=${1:-6}
SLEEP_PERIOD=${2:-10}

while [ ${COUNT} -ne 0 ];
do
	# Info about the head job / highest priority item in queue
	HEAD_INFO=$(squeue -h -t PD -o "%F,%Q,%q,%y,%a" | head -1)
	
	if [ -z "${HEAD_INFO}" ]; then
		# No pending jobs, sleep and continue
		sleep ${SLEEP_PERIOD}
		COUNT=$(( ${COUNT} - 1 ))
		continue
	fi

	HEAD_JOB_ID=$(echo ${HEAD_INFO} | cut -d, -f1)
	HEAD_QUEUE=$(echo ${HEAD_INFO} | cut -d, -f3)
	HEAD_QUANTUM=$(echo ${HEAD_INFO} | cut -d, -f4)

	# Freshly submitted or evaluated jobs
	if [ "${HEAD_QUEUE}" = "eval" ]; then
		if [ ${HEAD_QUANTUM} -ge ${EVAL_MAX_QUANTA} ]; then
			# If it hit the limit, push it to owners to run out its lifespan
			scontrol update job ${HEAD_JOB_ID} nice=0 qos=owners
			sleep ${SLEEP_PERIOD}
			COUNT=$(( ${COUNT} - 1 ))
			continue
		fi
		NEW_QUANTUM=$(( ${HEAD_QUANTUM} + 1 ))
		scontrol update job ${HEAD_JOB_ID} nice=${NEW_QUANTUM}

	# Go through owner jobs until the quanta limit is reached.
	elif [ "${HEAD_QUEUE}" = "owners" ]; then
		if [ "${HEAD_QUANTUM}" -ge ${OWNERS_MAX_QUANTA} ]; then
			scontrol update job ${HEAD_JOB_ID} nice=0 qos=expired
			sleep ${SLEEP_PERIOD}
			COUNT=$(( ${COUNT} - 1 ))
			continue
		fi
		NEW_QUANTUM=$(( ${HEAD_QUANTUM} + 1 ))
		scontrol update job ${HEAD_JOB_ID} nice=${NEW_QUANTUM}

	# Cycle individual expired jobs back into eval to trickle down again
	elif [ "${HEAD_QUEUE}" = "expired" ]; then
		scontrol update job "${HEAD_JOB_ID}" nice=0 qos=eval
		sleep ${SLEEP_PERIOD}
		COUNT=$(( ${COUNT} - 1 ))
		continue

	# Catch-all for unmanaged QOS states
	else
		scontrol update job "${HEAD_JOB_ID}" nice=0 qos=eval
	fi

	sleep ${SLEEP_PERIOD}
	COUNT=$(( ${COUNT} - 1 ))
done
