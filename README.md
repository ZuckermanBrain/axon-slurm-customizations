# SLURM Customizations for Axon

This repository contains a set of miscellaneous scripts and Ansible roles that customize the researcher experience on [Axon](https://confluence.columbia.edu/confluence/display/zmbbi/Axon%3A+GPU+Cluster), the GPU cluster maintained by Zuckerman Research Computing.

It includes:

 * `ansible-slurm-scratchspace`: An Ansible role that implements scratch space logic for SLURM using XFS-formatted locally-attached storage.
 * `MLFQ`: A script that is intended to be run as a cron.  Uses QoS levels, the [priority/multifactor](https://slurm.schedmd.com/priority_multifactor.html) plugin, and SLURM's `sched/builtin` priority queue scheduler to approximate / be somewhat conceptually similar to a [MLFQ scheduling algorithm](http://pages.cs.wisc.edu/~remzi/OSTEP/cpu-sched-mlfq.pdf).
 * `disk-usage`: Scripts that allow researchers to check disk usage in either their home directories or at the lab/account level.
 * `sfree`: Bash function that shows what resources are available on Axon.

All roles/scripts are licensed under the Revised 3-Clause BSD License unless otherwise specified.
