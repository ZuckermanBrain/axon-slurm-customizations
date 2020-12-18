#!/bin/bash

function homeusage() {
	if [ -f /tmp/.ncdu_home_$(whoami).gz ] && [ ! -f /tmp/.ncdu_home_$(whoami).gz.tmp ]; then
		echo "Note: Results reflect disk usage as of: $(stat -c %y /tmp/.ncdu_home_$(whoami).gz)"
		sleep 2
		zcat /tmp/.ncdu_home_$(whoami).gz | ncdu -rr -f-
	elif [ -f /tmp/.ncdu_home_$(whoami).gz.tmp ]; then
		echo "Home usage cache is currently rebuilding.  Please try again in a few minutes."
	fi
}
