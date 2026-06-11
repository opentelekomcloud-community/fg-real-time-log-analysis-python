# ----------------------------------------------------------------------------
# Secret variables to be injected as envvar (capital letters for Windows systems)
# - no defaults
# - Declared as sensitive --> Not printed in console or log if used in resources
# ----------------------------------------------------------------------------


# set by environment variable TF_VAR_OTC_SDK_AK
variable "OTC_SDK_AK" {
  description = "Personal access key"
  type        = string
  sensitive   = true
}

# set by environment variable TF_VAR_OTC_SDK_SK
variable "OTC_SDK_SK" {
  description = "Personal secret key"
  type        = string
  sensitive   = true
}

# set by environment variable TF_VAR_OTC_SDK_DOMAIN_NAME
variable "OTC_SDK_DOMAIN_NAME" {
  description = "Domain Name, eg. OTC-EU-DE-000000000010000XXXXX"
  type        = string
}

# set by environment variable TF_VAR_OTC_SDK_PROJECTID
variable "OTC_SDK_PROJECTID" {
  description = "Project Id"
  type        = string
}

# set by environment variable TF_VAR_OTC_SDK_PROJECTNAME
variable "OTC_SDK_PROJECTNAME" {
  description = "Project Name, eg. eu-de_MYPROJECT"
  type        = string
}

# set by environment variable TF_VAR_OTC_IAM_ENDPOINT
variable "OTC_IAM_ENDPOINT" {
  description = "IAM Endpoint"
  type        = string
  default     = "https://iam.eu-de.otc.t-systems.com/v3"
}


terraform {
  required_providers {
    
    # specifies required provider, source and version
    # see https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest

    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = ">= 1.36.68"
    }
  }
  backend "s3" {
    # See: https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/guides/backends

    # (Required) Specifies the endpoint for OpenTelekomCloud OBS.
    # The value is https://obs.{{region}}.otc.t-systems.com.
    # This can also be sourced from the AWS_S3_ENDPOINT environment variable
    endpoints = {
      s3 = "https://obs.eu-de.otc.t-systems.com"
    }

    # (Required) Specifies the bucket name where to store the state.
    # Make sure to create it before.
    bucket = "<your-bucket-name>"

    # (Required) Specifies the path to the state file inside the bucket.
    key = "<path/to/your/terraform.tfstate>"

    # (Required) Specifies the region where the bucket is located.
    # This can also be sourced from the AWS_DEFAULT_REGION and 
    # AWS_REGION environment variables.
    region = "<your-region>"

    # (Required) Skip credentials validation via the STS API.
    # It's mandatory for OpenTelekomCloud.
    skip_credentials_validation = true

    # (Required) Skip validation of provided region name. 
    # It's mandatory for OpenTelekomCloud.
    skip_region_validation = true

    skip_requesting_account_id = true

    # (Required) Skip usage of EC2 Metadata API.
    # It's mandatory for OpenTelekomCloud.
    skip_metadata_api_check = true

    # (Optional) Do not include checksum when uploading S3 Objects.
    # Useful for some S3-Compatible APIs.
    skip_s3_checksum = true

    # Although the terraform block does not accept variables or locals and
    # all backend configuration values must be hardcoded, you can provide 
    # the credentials via the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY 
    # environment variables to access OBS, respectively:
    #
    # export AWS_ACCESS_KEY_ID="your accesskey"
    # export AWS_SECRET_ACCESS_KEY="your secretkey"
    #
    # secret_key                  set env var: AWS_ACCESS_KEY_ID
    # access_key                  set env var: AWS_SECRET_ACCESS_KEY

  }

}

# ----------------------------------------------------------------------------
# Providers settings --> OTC
# We use the AKSK auth scheme
# See https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs
# ----------------------------------------------------------------------------
#

provider "opentelekomcloud" {
  auth_url = var.OTC_IAM_ENDPOINT

  access_key = var.OTC_SDK_AK
  secret_key = var.OTC_SDK_SK

  domain_name = var.OTC_SDK_DOMAIN_NAME
  tenant_name = var.OTC_SDK_PROJECTNAME

}
