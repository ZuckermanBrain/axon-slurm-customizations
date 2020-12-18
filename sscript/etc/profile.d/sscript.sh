#!/bin/bash
function sscript() {
	SARCHIVEDIR=/share/sarchive
	JOBID=${1}
	if [ -z ${JOBID} ]; then
		return
	fi
	JOBDATE=$(sacct -n -j ${JOBID} -o Submit | head -1 | cut -dT -f1 | sed 's/-//g')
	JOBSCRIPT=${SARCHIVEDIR}/${JOBDATE}/job.${JOBID}_script
	if [ ! -f ${JOBSCRIPT} ]; then
		echo "Could not find an archived job script for job ID ${JOBID}."
		echo "Exiting now."
		return
	fi
	if [ ! -r ${JOBSCRIPT} ]; then
		echo "The archived job script for job ID ${JOBID} is not readable."
		echo "This could be because it was not submitted by you or because it has not yet been updated for read access in the script archive."
		echo "If the latter, please try again in a minute."
		echo "Exiting now."
		return
	fi
	less ${JOBSCRIPT}
}
