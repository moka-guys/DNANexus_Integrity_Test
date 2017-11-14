# DNANexus Integrity Test v1.0

## What does this script do?
This script is designed to test the integrity of the DNANexus platform. It runs a single sample through a DNANexus workflow and checks that all the expected output files are present (by comparing to a truth set). The script is intended to be run regularly as a cron job. Results of the test are recorded in the syslog so that an alert can be issued via logentries if the test fails.

The data and workflow required to run the script are located in DNANexus project `003_DNANexus_Integrity_Check`. The workflow is a copy of the GATK_v2.8 workflow, with all inputs hardcoded and the final 'submit to IVA' step removed (see `GATK3.5_DNANexus_Integrity_Test_description.txt` for the dx-describe). The truth set files were generated by running the workflow manually through the web interface. Each time this script runs, the output will be stored in a timestamped folder in the aforementioned project.

## How to use this script
3 files are required. These should all be located in the same directory:
* DNANexus_Integrity_Check.sh
* config.sh
* api_key.sh

The first two can be found in this repository. The settings for the script are stored in the config.sh file so that they can be easily updated. The `api_key.sh` file must be created and should contain the following line:
`API_KEY=<DNANexus API key>`

To perform the test, set a cron job to run the DNANexus_Integrity_Check.sh at set intervals. Each time the script runs it takes approximately 1hr15mins to complete and costs approximately $1.30.

The results of the test will be written to /var/log/syslog with the tag `DNANexus-integrity-test` and a message starting with either `PASS` or `FAIL` depending on the outcome of the test.

## This script was made by Viapath Genome Informatics
