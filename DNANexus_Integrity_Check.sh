#!/bin/bash

# Author: Andy
# Date: 13 Nov 17
# Purpose: This script is designed to test the integrity of the DNANexus platform. It runs a DNANexus workflow and checks that
# all the expected output files are produced by comparing to a truth set. The script is run regularly from a cron job and issues
# an alert via syslog/logentries if the test fails.

# set -x so that each command is printed to stdout to help with debugging
set -x
# Source the public config file containing environment variables.
# $(dirname $0) returns the path to the directory containing this script.
source $(dirname $0)/config.sh
# Read DNAnexus API key from file.
API_KEY=$(<$API_KEY_PATH)
# Source the DNANexus environment.
source $DX_ENV
# Create a timestamp to be used as a unique identifier for the run. Format YYMMDD_HHMMSS.
timestamp=$(date +"%y%m%d_%H%M%S")
# Build the dx run command to run the wokflow in 003_DNANexus_Integrity_Check. Inputs are hardcoded in workflow.
# -y: Do not ask for confirmation of inputs.
# --brief: Turn off verbose output.
# --wait: Wait for job to finish before returning.
# --rerun-stage "*": Force a new analysis to be performed for all stages, rather than reusing the previous analyses in the project. ("*" = all_stages).
# --tag: Add timestamp tag; used to identify analysis later.
# --dest: Output the data to a timestamped subdirectory of the project.
# --auth-token: API token.
dx run ${PROJECT}:${WORKFLOW} -y --wait --brief --rerun-stage "*" \
--tag ${timestamp} --dest=${PROJECT}:${timestamp} --auth-token ${API_KEY}
# Find all analyses matching the timestamp tag. Returns matching analysis IDs (should only be one) separated by spaces.
all_analyses=$(dx find analyses --brief --project ${PROJECT} --tag ${timestamp} --auth-token ${API_KEY})
# Capture total number of analyses with matching tag (using word count)
all_analyses_count=$(echo ${all_analyses} | wc -w)
# Find all analyses with matching tag where the state = done (i.e. completed successfully). Returns analysis IDs (should only be one) separated by spaces.
successful_analyses=$(dx find analyses --brief --project ${PROJECT} --tag ${timestamp} --state done --auth-token ${API_KEY})
# Capture total number of analyses with matching tag that completed successfully (using word count)
successful_analyses_count=$(echo ${successful_analyses} | wc -w)
# Check the number of analyses with matching tag is one. If it isn't log an error in syslog.
# This will catch any situations where the analysis can't be found.
if [[ ${all_analyses_count} = 1 ]]; then
    # If there is one analysis, check to see whether it completed successfully. 
    if [[ ${successful_analyses_count} = 1 ]]; then
        # If job has completed successfully, get sorted list of all output filenames
        # This dx find data command will return a JSON containing information about all files in the specified directory and subdirectories
        test_files_json=$(dx find data --json --path ${PROJECT}:${timestamp} --auth-token ${API_KEY})
        # Use python to retrieve a sorted list of the filenames from the JSON
        test_filenames=$(python -c "print sorted([file['describe']['name'] for file in ${test_files_json}])")
        # Now repeat the above steps to get a sorted list of filenames from the truth set
        # This dx find data command will return a JSON containing information about all files in the specified directory and subdirectories
        truth_files_json=$(dx find data --json --path ${PROJECT}:${TRUTH_SET} --auth-token ${API_KEY})
        # Use python to retrieve a sorted list of the filenames from the JSON
        truth_filenames=$(python -c "print sorted([file['describe']['name'] for file in ${truth_files_json}])")
        # Check that the test and truth set contain exactly the same filenames  
        if [[ "${test_filenames}" = "${truth_filenames}" ]]; then
            # If workflow has completed successfully and all output files match the truth set, write a success message to syslog 
            logger -t DNANexus-integrity-test "PASS - All test and truth set output files match"
        else
            # If workflow has completed successfully but the output files don't match the truth set, write a failure message to syslog
            logger -t DNANexus-integrity-test "FAIL - Test and truth set output files do not match" 
        fi 
    else
        # If workflow has not completed successfully write a failure message to syslog
        logger -t DNANexus-integrity-test "FAIL - Workflow did not complete successfully" 
    fi
else
    # If the number of analyses returned matching the timestamp tag is not one, 
    # write a failure message to syslog including the number of analyses that were returned
    logger -t DNANexus-integrity-test "FAIL - The number of analyses with tag matching ${timestamp} was not 1. (Matching files: ${all_analyses_count})"
fi