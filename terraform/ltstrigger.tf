
resource "opentelekomcloud_fgs_trigger_v2" "ltsstrigger" {
  function_urn = opentelekomcloud_fgs_function_v2.FG_ANALYSE.urn
  type         = "LTS"
  status = "ACTIVE" 
  #status = "DISABLED"
  
  event_data = jsonencode({
    # "name" : lower(format("%s-%s-%s", var.prefix, var.function_name, "event")),
    "log_group_id"   = opentelekomcloud_lts_group_v2.AuditLogGroup.id,
    "log_topic_id"   = opentelekomcloud_lts_stream_v2.AuditLogStream.id
  })

}
