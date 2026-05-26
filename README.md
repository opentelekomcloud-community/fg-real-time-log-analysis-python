# Solution Introduction

This solution helps you with serverless architecture to collect, analyze, alert, and archive logs. It collects log data in real time based on the Log Tank Service (LTS), automatically retrieves log data through LTS triggers in the function workflow, analyzes alert information in the logs, pushes alert information to users through the Simple Message Notification Service (SMN), and stores it in an Object Storage Service (OBS) bucket for archiving.

## Architecture diagram

![Overview](document/overview.drawio.svg)

## Architecture Description
This solution will deploy the following resources:

- Create an OBS bucket in Object Storage Service (OBS) to store alarm logs;
- Function workflows allow users to run in a flexible, maintenance-free, and highly reliable manner simply by writing business function code and setting the running conditions.
- Create a topic in the SMN message notification service to push alarm information from the logs;
- Create Cloud Log Service (LTS) log groups and log streams to manage the collected logs.


## Prerequisites

- Python 3.10 installed
- Terraform installed
- 


### Check out code

```bash
git clone https://github.com/opentelekomcloud-community/fg-real-time-log-analysis-python.git
```

In folder  ```fg-real-time-log-analysis-python``` create a virtual environment using:

```bash
python3 -m venv .venv
```

## Deployment

This solution can be deployed using Terraform

### Prerequisites


#### Define Environment variables

Following variables ate used to configure the terraform provider [see provider.tf](terraform/provider.tf)

| Environment Variable        |                             |
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

| Environment Variable        |                             |
| --------------------------- | --------------------------- |
| TF_VAR_SMN_EMAIL_ADDRESS    | email address for smn       |

#### Create bucket to store tf state

Create state bucket either using OBS console or 
using the CLI with command [s3cmd](https://s3tools.org/s3cmd) 

```bash
s3cmd \
  --access_key=${TF_VAR_OTC_SDK_AK} \
  --secret_key=${TF_VAR_OTC_SDK_SK} \
  --no-ssl \
  mb s3://<bucket_name>
```

#### Adapt Makefile

Adapt [Makefile](./Makefile)

| Variable                 | default                                                  | Description 
| ------------------------ | -------------------------------------------------------- | ------------
| BACKEND_CONFIG_BUCKET    | "doc-samples-tf-backend"                                 | see <bucket_name>
| BACKEND_CONFIG_KEY       | "terraform_state/python/real-time-log-analysis.tf"       | path/file name
| BACKEND_CONFIG_REGION    | "eu-de"                                                  | REGION
| BACKEND_CONFIG_ENDPOINTS | "endpoints={s3=\"https://obs.eu-de.otc.t-systems.com\"}" | OBS Endpoint

#### Adapt variables.tfvars

Adapt [terraform/variables.tfvars](./terraform/variables.tfvars) if needed.

#### Adapt function.tf

Adapt [terraform/function.tf](./terraform/function.tf) if needed.

in 
```
resource "opentelekomcloud_fgs_function_v2" "FG_ANALYSE" {

  user_data = jsonencode({
    "RUNTIME_LOG_LEVEL" : "DEBUG",
    "obs_store_bucket" : opentelekomcloud_s3_bucket.logbucket.bucket,
    "obs_address" : "https://obs.otc.t-systems.com",
    "smn_urn" : opentelekomcloud_smn_topic_v2.topic_1.topic_urn,
    "iam_address" : "https://iam.otc.t-systems.com",
    "smn_address" : "https://smn.eu-de.otc.t-systems.com",
  })

}
```

### Terraform deployment

To deploy run

```bash
make tf_apply
```

to destroy afterwards

```bash
make tf_destroy
```