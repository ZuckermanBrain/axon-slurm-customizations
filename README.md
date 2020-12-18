# SLURM Customizations for Axon

This repository contains a set of miscellaneous scripts and Ansible roles that customize the researcher experience on [Axon](https://confluence.columbia.edu/confluence/display/zmbbi/Axon%3A+GPU+Cluster), the GPU cluster maintained by Zuckerman Research Computing.

It includes:

 * `ansible-slurm-scratchspace`: An Ansible role that implements scratch space logic for SLURM using XFS-formatted locally-attached storage.
 * `MLFQ`: A script that is intended to be run as a cron.  Uses QoS levels, the [priority/multifactor](https://slurm.schedmd.com/priority_multifactor.html) plugin, and SLURM's `sched/builtin` priority queue scheduler to approximate / be somewhat conceptually similar to a [MLFQ scheduling algorithm](http://pages.cs.wisc.edu/~remzi/OSTEP/cpu-sched-mlfq.pdf).
 * `disk-usage`: Scripts that allow researchers to check disk usage in either their home directories or at the lab/account level.
 * `sfree`: Bash function that shows what resources are available on Axon.
 * `sscript`: Gives researchers the ability to look at job scripts that have been archived with [sarchive](https://github.com/itkovian/sarchive).
 * `sjupyter`: Wrapper script for launching Jupyter notebooks under SLURM.

All roles/scripts are licensed under the Revised 3-Clause BSD License unless otherwise specified.

The `dehumanise` bash function that is used occasionally to translate human-readable file sizes to bytes is from [here](https://stackoverflow.com/a/31625253) and is licensed under the [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/) license.
