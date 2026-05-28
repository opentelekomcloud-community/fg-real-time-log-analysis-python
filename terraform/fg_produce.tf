##########################################################
# Create python event function
##########################################################
resource "opentelekomcloud_fgs_function_v2" "FG_PRODUCE" {

  name = format("%s_%s_producer", var.prefix, var.function_name)
  app  = "default"

  handler = "index.handler"

  runtime = "Python3.10"

  code_type     = "inline"
  func_code     = filebase64(format("${path.module}/fg_produce_code.py"))
  code_filename = "index.py"

  description      = "Test producer function for FunctionGraph"
  memory_size      = 128
  timeout          = 120
  max_instance_num = 10

  log_group_id   = opentelekomcloud_lts_group_v2.AuditLogGroup.id
  log_group_name = opentelekomcloud_lts_group_v2.AuditLogGroup.group_name

  log_topic_id   = opentelekomcloud_lts_stream_v2.AuditLogStream.id
  log_topic_name = opentelekomcloud_lts_stream_v2.AuditLogStream.stream_name

  tags = {
    "app_group" = var.tag_app_group
  }

}


output "FG_PRODUCE_URN" {
  value = opentelekomcloud_fgs_function_v2.FG_PRODUCE.urn
}

output "FG_PRODUCE_VERSION" {
  value = opentelekomcloud_fgs_function_v2.FG_PRODUCE.version
}

resource "opentelekomcloud_fgs_event_v2" "test_info" {
  function_urn = opentelekomcloud_fgs_function_v2.FG_PRODUCE.urn
  name         = "Test_INFO"
  content = base64encode(jsonencode({
    "key" = "This is a INFO message from producer!"
  }))
}

resource "opentelekomcloud_fgs_event_v2" "test_warn" {
  function_urn = opentelekomcloud_fgs_function_v2.FG_PRODUCE.urn
  name         = "Test_WARN"
  content = base64encode(jsonencode({
    "key" = "This is a WARNING message from producer!"
  }))
}

resource "opentelekomcloud_fgs_event_v2" "test_error" {
  function_urn = opentelekomcloud_fgs_function_v2.FG_PRODUCE.urn
  name         = "Test_ERROR"
  content = base64encode(jsonencode({
    "key" = "This is a ERROR message from producer!"
  }))
}
