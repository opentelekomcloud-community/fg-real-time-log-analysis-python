##########################################################
# Create Log Group
##########################################################
resource "opentelekomcloud_lts_group_v2" "AuditLogGroup" {
  group_name  = format("%s_%s_%s", var.prefix, var.function_name, "audit_log_group")
  ttl_in_days = 1

  tags = {
    "app_group" = var.tag_app_group
  }
}

##########################################################
# Create Log Stream
##########################################################
resource "opentelekomcloud_lts_stream_v2" "OutputLogStream" {
  group_id    = opentelekomcloud_lts_group_v2.AuditLogGroup.id
  stream_name = format("%s_%s_%s", var.prefix, var.function_name, "log_stream")

  tags = {
    "app_group" = var.tag_app_group
  }
}

resource "opentelekomcloud_lts_stream_v2" "AuditLogStream" {
  group_id    = opentelekomcloud_lts_group_v2.AuditLogGroup.id
  stream_name = format("%s_%s_%s", var.prefix, var.function_name, "audit_log_stream")

  tags = {
    "app_group" = var.tag_app_group
  }
}