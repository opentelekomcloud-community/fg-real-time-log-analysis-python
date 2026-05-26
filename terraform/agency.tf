
resource "opentelekomcloud_identity_role_v3" "role" {
  display_name  = format("%s-%s-role", var.prefix, var.function_name)
  description   = "Role for FunctionGraph to access OBS"
  display_layer = "project"

  statement {
    effect = "Allow"
    action = [
      "obs:*:*",
    ]
    resource = [
      "OBS:*:*:object:*",
      format("OBS:*:*:bucket:%s", opentelekomcloud_s3_bucket.logbucket.bucket),      
    ]
  }

}

resource "opentelekomcloud_identity_agency_v3" "agency" {
  delegated_domain_name = "op_svc_cff"

  name        = format("%s-%s-agency", var.prefix, var.function_name)
  description = format("Agency for FunctionGraph function %s", var.function_name)
  # domain_roles = [
  #   "OBS OperateAccess",
  #   "LTS FullAccess"
  # ]

  project_role {
    all_projects = true
    #project      = var.OTC_SDK_PROJECTNAME
    roles = [
      "LTS FullAccess",
      "SMN FullAccess",
      opentelekomcloud_identity_role_v3.role.display_name
    ]
  }

}
