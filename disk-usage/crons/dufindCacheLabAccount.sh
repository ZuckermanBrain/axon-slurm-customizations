#!/bin/bash

# The directory that contains all the shares for all Axon accounts.
ACCOUNT_DIR=/share
# Gets a list of all accounts.  The root account has no corresponding directory.
ACCOUNTS=($(sacctmgr -n show associations format=account | grep -v "root" | grep -v zrc | sort | uniq))

# Set up permissions so that files can only be accessed by groups.
umask 0007

# Save out the disk usage for all accounts to a text file in /tmp
for ACCOUNT in ${ACCOUNTS[@]}; do
	if [ -d ${ACCOUNT_DIR}/${ACCOUNT} ]; then
		> /tmp/.account_usage_${ACCOUNT}.tmp
		USERS=($(sacctmgr -n show associations format=user where account=${ACCOUNT}))
		for USER in ${USERS[@]}; do
			# We make the following simplifying assumptions here:
			# - All files in a user's home directory is owned by them.
			# - All user-owned files outside the user home directories is in the projects directory for each share.
			# These assumptions mean that there is a slight decrease in accuracy compared to just using "find"
			# across the whole share, but with the advantage that we don't need to iterate over every single file multiple times.
			HOMEUSAGE=$(du -bs ${ACCOUNT_DIR}/${ACCOUNT}/users/${USER} 2> /dev/null | awk '{print $1}')
			PROJECTUSAGE=$(find ${ACCOUNT_DIR}/${ACCOUNT}/projects -user ${USER} -type f -printf "%s\n" 2> /dev/null | awk '{t+=$1}END{print t}')
			if [ -z ${HOMEUSAGE} ]; then
				HOMEUSAGE=0
			fi
			if [ -z ${PROJECTUSAGE} ]; then
				PROJECTUSAGE=0
			fi
			USAGE=$(( ${HOMEUSAGE} + ${PROJECTUSAGE} ))
			echo ${USAGE},${USER} >> /tmp/.account_usage_${ACCOUNT}.tmp
		done
		printf "Showing disk usage for all members of account \"%s\"\n" ${ACCOUNT} > /tmp/.account_usage_${ACCOUNT}
		printf "===================\n" >> /tmp/.account_usage_${ACCOUNT}
		printf "%s\t%s\n" "UNI" "Space Used" >> /tmp/.account_usage_${ACCOUNT}
		printf "===================\n" >> /tmp/.account_usage_${ACCOUNT}
		# Sort the usage by top user.
		sort -nr /tmp/.account_usage_${ACCOUNT}.tmp > /tmp/.account_usage_${ACCOUNT}.tmp.2
		mv /tmp/.account_usage_${ACCOUNT}.tmp.2 /tmp/.account_usage_${ACCOUNT}.tmp
		for LINE in $(cat /tmp/.account_usage_${ACCOUNT}.tmp); do
			USAGE=$(echo ${LINE} | cut -d, -f1 | numfmt --to=iec)
			USER=$(echo ${LINE} | cut -d, -f2)
			printf "%s\t%s\n" ${USER} ${USAGE} >> /tmp/.account_usage_${ACCOUNT}
		done
		# Restrict to members of group.
		chgrp cu.app.adcu.zmbbi.rc-axon-${ACCOUNT} /tmp/.account_usage_${ACCOUNT}
		rm /tmp/.account_usage_${ACCOUNT}.tmp
	fi
done
