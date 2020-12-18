# sscript

sscript is a convenience wrapper that allows researchers to look at their own job scripts that have been archived with [sarchive](https://github.com/itkovian/sarchive).  A complementary cron job (`sscriptPrep.sh`) runs every minute and is used to update permissions for the job scripts that have been archived.

`playbook-sarchive.yml` is a set of plays that can be used to install `sarchive` on CentOS 7.
