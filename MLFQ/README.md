# SLURM MLFQ
==============

 * Runs every minute as root on a login node (or any node where `scontrol` will work; might make sense to have it running on the same node as `slurmctld`).
 * Assumes the existence of 4 QoS levels (`expired`, `renters`, `owners`, and `eval`).  `eval` approximates the highest priority queue and is where jobs go immediately after they are submitted. After the max quanta for `eval` have been consumed, a job is sent to either the `renters` queue or the `owners` queue.  `owners` is higher priority than `renters`, and is for labs that have purchased an entire node on Axon.  `renters` is for labs that are renting capacity on the node owned by Zuckerman Research Computing (`ax08`).  In either of these queues, once 4 quanta have been used up a job will be demoted to the `expired` queue.  Once all jobs are in the `expired` queue, their state resets / all jobs are promoted back to the `eval` queue.  Some example code to set up the required QoS levels:

```
sacctmgr add qos expired
sacctmgr add qos renters
sacctmgr add qos owners
sacctmgr add qos eval
sacctmgr modify qos expired set priority=0
sacctmgr modify qos renters set priority=10
sacctmgr modify qos owners set priority=100
sacctmgr modify qos eval set priority=1000
```

 * As a caveat, because we're using QoS / not actually using a queue data structure with protective measures in place, it's possible that there could be overflow (i.e., if there are >= 90 jobs within the `owner` queue that haven't used up their 4 quanta, using the above code as an example).

## Why did we do this?

The latest iteration of the explanation for why we implemented this can be found [here](https://confluence.columbia.edu/confluence/display/zmbbi/Slurm+Overview#SlurmOverview-SchedulingAlgorithm) in Axon's documentation.  However, we'll copy the text from that link here as well for convenience / in case that link disappears at some point in the future:

By default, the SLURM scheduler can use one of two algorithms to schedule jobs on the cluster:

The [backfill algorithm](https://slurm.schedmd.com/SUG14/sched_tutorial.pdf), which is the default on many other SLURM clusters, attempts to schedule low priority jobs if they do not prevent higher priority jobs from starting at an expected start time.  One problem with this algorithm is that it is highly dependent upon how diligent other cluster users are in setting the *--time=* parameter in their submission scripts.  Essentially, it focuses on optimizing start and end times, but it assumes that everyone is accurately estimating the time their jobs will take and programming this estimate into their job scripts.  Another problem with this algorithm is that when a job is scheduled to execute on a node the job is allocated an entire node (even if it's not using all the resources on the node).  Basically, although this algorithm can be an ideal optimization for scheduling jobs under certain circumstances, the granularity it uses when considering resources is very coarse and it makes many assumptions about how job scripts are programmed that may not hold true.

The [priority queue algorithm](http://www.cs.columbia.edu/~bauer/cs3134-f15/slides/w3134-1-lecture13.pdf) uses a global queue of all jobs that have been submitted to the cluster.  This queue is ordered by the priority score assigned to each job with higher priority jobs in front.  For each job at the front of the queue, Slurm makes a decision about how to assign resources to the job before removing the job from the queue and placing it on a server.  This means that occasionally, under circumstances where the highest priority job cannot be allocated resources, the job at the front of the queue can block Slurm from trying to find enough resources for lower priority jobs.  This can cause Slurm to not be very responsive.

On our cluster, we use a priority queue algorithm, but have added some custom modifications that cause this algorithm to behave like a [multi-level feedback queue algorithm](http://pages.cs.wisc.edu/~remzi/OSTEP/cpu-sched-mlfq.pdf).  This means that any given unscheduled job cannot block other unscheduled jobs from being evaluated for resource allocation, making the cluster more responsive.  Because our setup is ultimately based upon Slurm's built-in priority queue algorithm, Slurm also does not allocate an entire node to jobs and is capable of dealing with resources at a more fine-grained level.  With this configuration, Slurm also makes no assumptions about job start and end times.  In brief, our setup gives us fine-grained allocation of resources (i.e., the ability to request discrete CPU cores and GPUs), responsiveness, and is robust to inaccurate job time estimates.
