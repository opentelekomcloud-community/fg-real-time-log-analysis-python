#!/bin/bash
# Script to get an authentication token 
# from OTC IAM using username and password
# to be passed as x-auth-token header in API requests.
# Script outputs the token to 
# - stdout
# - and to the environment variable OTC_X_AUTH_TOKEN (if called using current shell "source ...")

# see: https://docs.otc.t-systems.com/identity-access-management/api-ref/calling_apis/authentication.html#iam-02-0510
# see: https://docs.otc.t-systems.com/identity-access-management/api-ref/apis/token_management/obtaining_a_user_token_through_password_authentication.html

# Following environment variables must be set:
# OTC_USER_NAME
# OTC_USER_PASSWORD
# OTC_DOMAIN_NAME
# OTC_SDK_PROJECTNAME
# OTC_SDK_PROJECTID
# OTC_IAM_ENDPOINT e.g. https://iam.eu-de.otc.t-systems.com/v3

# If DEBUG is not set in the environment, it defaults to 0 (off)
DEBUG=${DEBUG:-0}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd "curl"
require_cmd "awk"
require_cmd "grep"
require_cmd "mktemp"

NEEDED_ENV_VARS=(
  "OTC_USER_NAME"
  "OTC_USER_PASSWORD"
  "OTC_DOMAIN_NAME"
  "OTC_SDK_PROJECTID"
  "OTC_IAM_ENDPOINT"
)

for var in "${NEEDED_ENV_VARS[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "Please set environment variable $var"
    exit 1
  fi
done


fail() {
  echo "$1" >&2
  return 1 2>/dev/null || exit 1
}

payload=$(cat <<EOF
{
  "auth": {
    "identity": {
      "methods": [
        "password"
      ],
      "password": {
        "user": {
          "name": "${OTC_USER_NAME}",
          "password": "${OTC_USER_PASSWORD}",
          "domain": { "name": "${OTC_DOMAIN_NAME}" }
        }
      }
    },
    "scope": {
      "project": {
        "id": "${OTC_SDK_PROJECTID}",
        "domain": { "name": "${OTC_DOMAIN_NAME}" }
      }
    }
  }
}
EOF
)

if [ "$DEBUG" -eq 1 ]; then
  # for debugging, print the payload to stderr
  echo "################# Payload for token request: #################" >&2
  echo ${payload} >&2
  echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >&2
fi

# Make the API call 
# and extract the X-Subject-Token from the response headers
headers_file=$(mktemp) || fail "Failed to create temporary file for response headers"

http_code=$(curl -sS \
-H 'Content-Type: application/json' \
-d "${payload}" \
-o /dev/null \
-D "${headers_file}" \
-w '%{http_code}' \
${OTC_IAM_ENDPOINT}/auth/tokens?nocatalog=true)
curl_status=$?

token=$(grep -i '^X-Subject-Token:' "${headers_file}" | awk '{print $2}' | tr -d '\r')
rm -f "${headers_file}"

if [ "${curl_status}" -ne 0 ]; then
  fail "curl failed with exit code ${curl_status}"
fi

if [ "${http_code}" != "201" ]; then
  fail "IAM returned HTTP ${http_code}"
fi

if [ -z "${token}" ]; then
  fail "No X-Subject-Token header found in IAM response"
fi

if [ "$DEBUG" -eq 1 ]; then
  # for debugging, print the token to stderr
  echo "################# Token #################" >&2
  echo "${token}" >&2
  echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >&2
fi

# export the token to environment variable OTC_X_AUTH_TOKEN
export OTC_X_AUTH_TOKEN=${token}

# print the token to stdout
echo ${token}
