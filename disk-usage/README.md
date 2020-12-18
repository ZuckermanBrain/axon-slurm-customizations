# Disk Usage Scripts on Axon

These scripts operate within the environment described [here](https://confluence.columbia.edu/confluence/display/zmbbi/Managing+Files+and+Data#ManagingFilesandData-ClusterDiskSpace).

 * The scripts under `crons` run once daily.  They're intended as `anacron` jobs and should be placed under `/etc/cron.daily` (if your distro is set up to look for daily `anacron` jobs there).  
 * `ncduCacheHome.sh` runs on Axon's login node. It gets a list of all researchers using the cluster from the SLURM accounting daemon and then runs `ncdu` on their home directories, storing the results as a compressed file under `/tmp`.  A wrapper function (`homeusage`) is sourced from `/etc/profile.d` for login shells and is used to read out the cached `ncdu` results.  Additionally, it gives the time of when the results were saved.
 * `dufindCacheLabAccount.sh` runs on Axon's login node. It generates a list of the amount of space used by individual users within a lab account.  It counts all storage used under a researcher's home directory as storage used by that researcher (as a simplifying assumption).  For non-home directories / project directories, it uses `find` to identify files owned by individual researchers.  The `labusage` wrapper function is used to display the output of this job.
