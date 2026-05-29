resource "opentelekomcloud_s3_bucket" "logbucket" {
  bucket        = lower(format("%s-%s-%s", var.prefix, var.function_name, "logbucket"))
  acl           = "private"

  # Warning: force_destroy will delete bucket on 
  # terraform destroy even if it contains objects
  force_destroy = true

  tags = {
    "app_group" = var.tag_app_group
  }

}

output "logbucket_name" {
  value = opentelekomcloud_s3_bucket.logbucket.bucket
}
