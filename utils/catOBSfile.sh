#!/bin/bash
# Script to read the content of an OBS file and print it to stdout.
# The script uses s3cmd to download the file to a temporary location and then prints it.

LOG_FILE=$1

if [ -z "${LOG_FILE}" ]; then
  echo "Usage: $0 <obs_file_path>" >&2
  exit 1
fi

TEMP_FILE="/tmp/$(basename $0).$$.tmp"
# Ensure the temporary file is removed on exit
trap 'rm -f -- "$TEMP_FILE"' EXIT

# get file content from OBS using s3cmd
s3cmd \
	--access_key=${OTC_SDK_AK} \
	--secret_key=${OTC_SDK_SK} \
	--no-ssl \
  --quiet \
	get ${LOG_FILE} ${TEMP_FILE}

if ! command -v "jq" >/dev/null 2>&1; then
    # jq is not available, print raw content
    printf "\n"
    cat ${TEMP_FILE}
else
    if jq -e . >/dev/null 2>&1 < ${TEMP_FILE}; then
        # pretty print JSON content if valid JSON
        jq --color-output . ${TEMP_FILE}
    else
        # print raw content if not valid JSON
        printf "\n"
        cat ${TEMP_FILE}
    fi
fi