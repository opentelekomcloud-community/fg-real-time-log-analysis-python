# prefix will be prepended to all resource names
variable "prefix" {
  type    = string
  default = "set in variables.tfvars"
}


# FunctionGraph: Function name
variable "function_name" {
  type    = string
  default = "set in variables.tfvars"
}

# name of zip file to deploy
variable "zip_file_name" {
  type    = string
  default = "set in variables.tfvars"
}

# Resource tag:
variable "tag_app_group" {
  type    = string
  default = "set in variables.tfvars"
}

variable "SMN_EMAIL_ADDRESS" {
  type    = string
  default = "set as environment variable TF_VAR_SMN_EMAIL_ADDRESS"
}
