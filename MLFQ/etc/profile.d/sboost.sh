function sboost {
	JOB_ID=${1}
	if [ -z ${JOB_ID} ]; then
		echo "No job ID was provided."
		return
	fi
	scontrol update job ${JOB_ID} qos=eval
}
