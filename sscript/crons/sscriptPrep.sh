#!/bin/bash
SARCHIVEDIR=/share/sarchive/

for JOBDIR in $(find ${SARCHIVEDIR} -mindepth 1 -maxdepth 1 -type d -mtime -1);
do
	chmod o+rx ${JOBDIR}
	for JOBENV in $(find ${JOBDIR} -name "*_environment" -mmin -2);
	do
		JOBUSER=$(sed 's/\x0/\n/g' ${JOBENV} | grep "^USER=" | cut -d= -f2)
		if [ -z ${JOBUSER} ]; then
			continue
		fi
		JOBSCRIPT=${JOBENV/environment/script}
		chown ${JOBUSER} ${JOBENV}
		chmod a-w ${JOBENV}
		chown ${JOBUSER} ${JOBSCRIPT}
		chmod a-w ${JOBSCRIPT}
	done
done
