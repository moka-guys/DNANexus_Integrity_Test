# DNANexus Integrity Test v1.2

## What does this script do?
This script is designed to test the integrity of the DNANexus platform. It runs a single sample through a DNANexus workflow and checks that all the expected output files are present (by comparing to a truth set). The script is intended to be run regularly as a cron job. Results of the test are recorded in the syslog so that an alert can be issued via logentries if the test fails.

The workflow, `GATK3.5_DNAnexus_platform_integrity_test`, is stored in `001_ToolsReferenceData/Workflows` (and version controlled in [GitHub](https://github.com/moka-guys/dnanexus_platform_integrity_test_workflow)). The workflow is run in `001_DNAnexus_Platform_Integrity_Test`.

## How to use this script
To perform the test, set a cron job to run `DNANexus_Integrity_Check.sh` at set intervals, redirecting `STDOUT` and `STDERR` to a logfile.  *Each time the script runs it takes approximately 1hr40mins to complete and costs around $2.*

The results of the test are written to /var/log/syslog with the tag `DNANexus-integrity-test` and a message starting with either `PASS` or `FAIL` depending on the outcome of the test.

## Results and Alerts
DNANexus usually push updates overnight on Tuesdays (https://twitter.com/dnanexus_status), therefore a cron job has been set up on the workstation to run `DNANexus_Integrity_Check.sh` every Wednesday morning.

Logentries alerts have been set up to send an alert to Slack if the string `DNANexus-integrity-test: FAIL` is detected in the syslog at any point, or if no `DNANexus-integrity-test` entries have been detected in the syslog for 8 days (indicating the script has stopped running or is misbehaving).

`STDOUT` and `STDERR` from each run is written to a timestamped log file in: `~/Documents/apps/DNANexus_Integrity_Test/logs`.

## This script was made by Viapath Genome Informatics
