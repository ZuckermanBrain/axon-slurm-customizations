#!/bin/bash
dehumanise() {
	for v in "${@:-$(</dev/stdin)}"
	do  
		echo $v | awk \
		'BEGIN{IGNORECASE = 1}
		function printpower(n,b,p) {printf "%u\n", n*b^p; next}
		/[0-9]$/{print $1;next};
		/K(iB)?$/{printpower($1,  2, 10)};
		/M(iB)?$/{printpower($1,  2, 20)};
		/G(iB)?$/{printpower($1,  2, 30)};
		/T(iB)?$/{printpower($1,  2, 40)};
		/KB$/{    printpower($1, 10,  3)};
		/MB$/{    printpower($1, 10,  6)};
		/GB$/{    printpower($1, 10,  9)};
		/TB$/{    printpower($1, 10, 12)}'
	done
}

function sfree {
	# Get allocated/idle/other/total CPUs, total GPUs, free memory, total memory, total scratch space.
	SINFO_OUT=($(sinfo -h -N -O "nodelist,cpusstate,gres,allocmem,memory,disk" | sort | uniq | awk '{$1=$1}1' OFS=","))

	# Get allocated GPUs, allocated scratch space.
	# Since the output of "scontrol show job" doesn't update in real time / has some log,
	# we fetch the job IDs for currently active jobs from squeue and then iterate through them.
	ALLOC_GPUS=($(for JOBID in $(squeue -t R -h -o %i | sort | uniq); do scontrol show job ${JOBID} | grep -e NodeList -e TresPerNode=gpu | grep -v ReqNodeList| grep -B 1 TresPerNode; done))
	ALLOC_SCRATCHDISKS=($(for JOBID in $(squeue -t R -h -o %i | sort | uniq); do scontrol show job ${JOBID} | grep -e NodeList -e MinTmpDiskNode | grep -v ReqNodeList; done))

	# Print out header.
	printf "%s\t%s\t%s\t%s\t\t%s\n" "Node Name" "CPUs Free" "GPUs Free" "Memory Free"  "Scratch Space Free"
	# https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash
	printf "%0.s-" {1..90}
	printf "\n"
	# Print out results
	# Display memory / disk space in gigabytes.
	for LINE in ${SINFO_OUT[@]};
	do
		NODE=$(echo ${LINE} | cut -d, -f1)
		#ALLOC_CPU=$(echo ${LINE} | cut -d, -f2 | cut -d/ -f1)
		FREE_CPU=$(echo ${LINE} | cut -d, -f2 | cut -d/ -f2)
		TOTAL_CPU=$(echo ${LINE} | cut -d, -f2 | cut -d/ -f4)
		ALLOC_GPU=$(for L in ${ALLOC_GPUS[@]}; do echo ${L}; done | grep -A 1 ${NODE} | grep -io TresPerNode=.* | cut -d= -f2 | rev | cut -d: -f1 | rev | awk '{s+=$0}END{print s}')
		if [ -z ${ALLOC_GPU} ];
		then
			ALLOC_GPU=0
		fi
		TOTAL_GPU=$(echo ${LINE} | cut -d, -f3 | cut -d: -f3)
		FREE_GPU=$(( ${TOTAL_GPU} - ${ALLOC_GPU} ))
		ALLOC_MEM=$(( $(echo ${LINE} | cut -d, -f4) / 1024 ))
		TOTAL_MEM=$(( $(echo ${LINE} | cut -d, -f5) / 1024 ))
		FREE_MEM=$(( ${TOTAL_MEM} - ${ALLOC_MEM} ))
		# Need more lines after in grep due to space delimiter in scontrol output.
		ALLOC_SCRATCHDISK=($(for L in ${ALLOC_SCRATCHDISKS[@]}; do echo ${L}; done | grep -A 3 ${NODE} | grep -io MinTmpDiskNode=.* | cut -d= -f2))
		ALLOC_SCRATCHDISK=$(echo $(for L in ${ALLOC_SCRATCHDISK[@]}; do echo $(( $(echo ${L} | dehumanise) / 1048576 )); done ) | awk '{s+=$0}END{print s}' RS=' ')
		if [ -z ${ALLOC_SCRATCHDISK} ];
		then
			ALLOC_SCRATCHDISK=0
		else
			ALLOC_SCRATCHDISK=$(( ${ALLOC_SCRATCHDISK} / 1024 ))
		fi
		TOTAL_SCRATCHDISK=$(( $(echo ${LINE} | cut -d, -f6) / 1024 ))
		FREE_SCRATCHDISK=$(( ${TOTAL_SCRATCHDISK} - ${ALLOC_SCRATCHDISK} ))
		printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\n" "${NODE}" "${FREE_CPU} / ${TOTAL_CPU}" "${FREE_GPU} / ${TOTAL_GPU}" "${FREE_MEM} / ${TOTAL_MEM}" "${FREE_SCRATCHDISK} / ${TOTAL_SCRATCHDISK}"
	done 
}
