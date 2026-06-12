# Solution Introduction

This solution helps you with serverless architecture to collect, analyze, alert, and archive logs. It collects log data in real time based on the Log Tank Service (LTS), automatically retrieves log data through LTS triggers in the function workflow, analyzes alert information in the logs, pushes alert information to users through the Simple Message Notification Service (SMN), and stores it in an Object Storage Service (OBS) bucket for archiving.

## Architecture diagram

![Overview](doc/overview.drawio.svg)

## Architecture Description
This solution will deploy the following resources:

- LTS Log Group and two log streams, one for auditing and one for protocol
- FunctionGraph (with test events) writing logs to auditing log stream 
- FunctionGraph with LTS trigger listening on auditing log stream
- OBS bucket in Object Storage Service (OBS) to store alarm logs in OBS object;
- SMN Topic and Subscription in the  Simple Message Notification service (SMN) to push alarm information from the logs as email;
- IAM Agency with permissions for OBS and SMN
- some test events for the FunctionGraph functions.
  

## Prerequisites

This sample assumes you are using a linux environment, like

- Ubuntu
- Windows Subsystem for Linux (wsl2) with Ubuntu

Following tools should be installed:

- Python 3.10
- Terraform (recommended: >= 1.5)
- `make`
- `zip`
- `curl` (if proxy needed add ```proxy=<YOUR_PROXY>``` to file ~/.curlrc)
- [s3cmd](s3tools.org) with following configuration in file ~/.s3cfg
  (here sample for region eu-de):
  ```ini
  [default]
  host_base = obs.eu-de.otc.t-systems.com
  use_https = True
  bucket_location = eu-de
  ```
- optional: [jq](https://jqlang.org/)  

### Get the code

Clone the code from GitHub:

```bash
git clone https://github.com/opentelekomcloud-community/fg-real-time-log-analysis-python.git
```

From the repository root, install Python dependencies used for packaging:

```bash
# create venv in folder .venv
python3 -m venv .venv

# activate virtual environment
source ./venv/bin/activate

#install requirements
python3 -m pip install -r requirements.txt
```


## Deploy resources using Terraform on T Cloud Public

### Set Required Environment Variables

Following variables ate used to configure the terraform provider [see provider.tf](terraform/provider.tf)

| Environment Variable        | Value                       |
| --------------------------- | --------------------------- | 
| TF_VAR_OTC_SDK_AK           | [Access Key](https://docs.otc.t-systems.com/api-usage/guidelines/calling_apis/ak_sk_authentication/generating_an_ak_and_sk.html)
| TF_VAR_OTC_SDK_SK           | [Secret Key](https://docs.otc.t-systems.com/api-usage/guidelines/calling_apis/ak_sk_authentication/generating_an_ak_and_sk.html)
| TF_VAR_OTC_SDK_DOMAIN_NAME  | [Domain Name](https://docs.otc.t-systems.com/api-usage/guidelines/calling_apis/obtaining_required_information.html)
| TF_VAR_OTC_SDK_PROJECTID    | [Project ID](https://docs.otc.t-systems.com/api-usage/guidelines/calling_apis/obtaining_required_information.html)
| TF_VAR_OTC_SDK_PROJECTNAME  | [Project Name](https://docs.otc.t-systems.com/api-usage/guidelines/calling_apis/obtaining_required_information.html)
| TF_VAR_OTC_IAM_ENDPOINT           | IAM Endpoint, e.g. https://iam.eu-de.otc.t-systems.com
| AWS_ACCESS_KEY_ID                 | same as TF_VAR_OTC_SDK_AK
| AWS_SECRET_ACCESS_KEY             | same as TF_VAR_OTC_SDK_SK
| AWS_REQUEST_CHECKSUM_CALCULATION  | "when_required"
| AWS_SECRET_ACCESS_KEY             | "when_required"

Additional variables:

| Environment Variable        | Value                       |
| --------------------------- | --------------------------- |
| TF_VAR_SMN_EMAIL_ADDRESS    | email address for smn       |


Additional variables for testing in make:
| Environment Variable  | Value                       |
| --------------------- | --------------------------- |        
| OTC_USER_NAME         | your username
| OTC_USER_PASSWORD     | your password
| OTC_SDK_REGION        | e.g. eu-de
| OTC_DOMAIN_NAME       | e.g. OTC000...
| OTC_SDK_PROJECTNAME   | e.g. eu-de_YOURPROJECT
| OTC_SDK_PROJECTID     | id of Project
| OTC_IAM_ENDPOINT      | e.g. https://iam.eu-de.otc.t-systems.com/v3

### Prepare Terraform Remote State Backend (OBS)

The Terraform backend is configured as S3-compatible OBS in `terraform/provider.tf`.
Create state bucket either using OBS console or 
using the CLI with command [s3cmd](https://s3tools.org/s3cmd) 

Example with `s3cmd`:

```bash
s3cmd \
  --access_key=${TF_VAR_OTC_SDK_AK} \
  --secret_key=${TF_VAR_OTC_SDK_SK} \
  --no-ssl \
  mb s3://<bucket_name>
```

### Configure Backend Values in Makefile

Adapt [Makefile](./Makefile)

| Variable                 | default                                                  | Description 
| ------------------------ | -------------------------------------------------------- | ------------
| BACKEND_CONFIG_BUCKET    | "doc-samples-tf-backend"                                 | see <bucket_name>
| BACKEND_CONFIG_KEY       | "terraform_state/python/real-time-log-analysis.tf"       | path/file name
| BACKEND_CONFIG_REGION    | "eu-de"                                                  | REGION
| BACKEND_CONFIG_ENDPOINTS | "endpoints={s3=\"https://obs.eu-de.otc.t-systems.com\"}" | OBS Endpoint

### Adapt variables.tfvars

Adapt [terraform/variables.tfvars](./terraform/variables.tfvars) if needed:

- `prefix`
- `function_name`
- `zip_file_name` (default is `dist/code.zip`)
- `tag_app_group`

### Adapt function.tf

Adapt [terraform/function.tf](./terraform/function.tf) if needed.

```
resource "opentelekomcloud_fgs_function_v2" "FG_ANALYSE" {

  user_data = jsonencode({
    "RUNTIME_LOG_LEVEL" : "DEBUG",
    "obs_store_bucket" : opentelekomcloud_s3_bucket.logbucket.bucket,
    "obs_address" : "obs.otc.t-systems.com",
    "smn_urn" : opentelekomcloud_smn_topic_v2.topic_1.topic_urn,
    "smn_endpoint" : "smn.eu-de.otc.t-systems.com"
  })

}
```

### Deploy with Make Targets (Recommended)

From the repository root:

```bash
# Create deployment package and apply Terraform
make tf_apply

```
What this does:

- Builds the deployment package zip via `createZip.py`
- Runs `terraform init` (if needed) with backend config
- Runs `terraform apply -auto-approve -var-file="variables.tfvars"`


#### Verify Deployment

Following files need execution rights:

```bash
chmod +x ./utils/tokenFromUsername.sh
chmod +x ./utils/catOBSfile.sh
```

The Makefile provides some test targets:

```bash
# create a info message
make test_deployed_info

# create a warning message
make test_deployed_warn

# create a error message
make test_deployed_error

# list all files in bucket
make list_log_objects

# display log from object (use output from list_log_object)
make display_log_object file=s3://py-real-time-log-analysis-logbucket/log/log-20260526153715954004-546709.log
```

## Clean up

When you're finished working with the example function, delete it. 

This can be done using:

```bash
make tf_destroy
```


## Troubleshooting

- `terraform init` fails on backend: verify OBS bucket exists and backend endpoint/region values match your OTC region.
- Authentication errors: verify `TF_VAR_OTC_SDK_AK`/`TF_VAR_OTC_SDK_SK` and IAM endpoint.
- Email alerts not received: verify `TF_VAR_SMN_EMAIL_ADDRESS` and subscription confirmation in SMN.


> Warranty Disclaimer
> -------------------
> THE OPEN SOURCE SOFTWARE IN THIS PRODUCT IS DISTRIBUTED IN THE HOPE THAT IT
> WILL BE USEFUL,BUT WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY
> OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
> 
> SEE THE APPLICABLE LICENSES FOR MORE DETAILS.
