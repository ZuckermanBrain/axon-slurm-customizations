#!/bin/bash

> /tmp/.ncduCache.log
# Get a list of all active Axon users.
AXONUSERS=($(sshare -n -a --format=user | sort | uniq))
for AXONUSER in ${AXONUSERS[@]};
do
	# Only run if the user can be found in passwd database / sssd
	if getent passwd ${AXONUSER} > /dev/null 2>&1;
	then
		# Store cache in /tmp in case Engram volume fills up.
		echo Running: sudo -u ${AXONUSER} /bin/bash -c 'umask 0077; ncdu -0xo- ${HOME} | gzip > /tmp/.ncdu_home_$(whoami).gz.tmp' >> /tmp/.ncduCache.log
		sudo -u ${AXONUSER} /bin/bash -c 'umask 0077; ncdu -0xo- ${HOME} | gzip > /tmp/.ncdu_home_$(whoami).gz.tmp' 2>> /tmp/.ncduCache.log
		sudo -u ${AXONUSER} /bin/bash -c 'mv /tmp/.ncdu_home_$(whoami).gz.tmp /tmp/.ncdu_home_$(whoami).gz' 2>> /tmp/.ncduCache.log
	fi	
done
