#!/bin/bash

function labusage() {
	USER_ACCOUNTS=($(sacctmgr -n show associations user=$(whoami) format=account))
	for USER_ACCOUNT in ${USER_ACCOUNTS[@]};
	do
		if [ -f /tmp/.account_usage_${USER_ACCOUNT} ]; then
			echo "Note: Results reflect disk usage as of: $(stat -c %y /tmp/.account_usage_${USER_ACCOUNT})"
			cat /tmp/.account_usage_${USER_ACCOUNT}
		elif [ -f /tmp/.account_usage_${USER_ACCOUNT}.tmp ]; then
			echo "Account usage cache is currently rebuilding.  Please try again in a few minutes."
		fi
		echo
	done
}
