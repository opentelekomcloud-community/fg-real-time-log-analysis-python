##########################################################
# Create python event function
##########################################################
resource "opentelekomcloud_fgs_function_v2" "FG_ANALYSE" {

  name = format("%s_%s", var.prefix, var.function_name)
  app  = "default"

  agency = opentelekomcloud_identity_agency_v3.agency.name

  handler = "src/index.handler"

  initializer_handler = null
  initializer_timeout = null

  runtime = "Python3.10"

  code_type     = "zip"
  func_code     = filebase64(format("${path.module}/../%s", var.zip_file_name))
  code_filename = basename(var.zip_file_name)

  description      = "Sample for real time log analysis in python"
  memory_size      = 128
  timeout          = 120
  max_instance_num = 10

  log_group_id   = opentelekomcloud_lts_group_v2.AuditLogGroup.id
  log_group_name = opentelekomcloud_lts_group_v2.AuditLogGroup.group_name

  log_topic_id   = opentelekomcloud_lts_stream_v2.OutputLogStream.id
  log_topic_name = opentelekomcloud_lts_stream_v2.OutputLogStream.stream_name

  # set some environment variables
  user_data = jsonencode({
    "RUNTIME_LOG_LEVEL" : "DEBUG",
    "obs_store_bucket" : opentelekomcloud_s3_bucket.logbucket.bucket,
    "obs_store_bucket_endpoint" : "https://${opentelekomcloud_s3_bucket.logbucket.bucket_domain_name}",
    "obs_address" : "obs.otc.t-systems.com",
    "smn_urn" : opentelekomcloud_smn_topic_v2.topic_1.topic_urn,
    "smn_endpoint" : "smn.eu-de.otc.t-systems.com",
  })

  tags = {
    "app_group" = var.tag_app_group
  }

}

resource "opentelekomcloud_fgs_event_v2" "FG_ANALYSE_test_wrn" {
  function_urn = opentelekomcloud_fgs_function_v2.FG_ANALYSE.urn
  name         = "LTS_WRN"
  content = base64encode(jsonencode({
    "lts" : {
      "data" : base64encode(jsonencode({
        "logs" : [
          "{\"hostId\":\"\",\"message\":\"2026-05-26T07:19:42Z 17ea9752-a166-420c-9efa-8a3e9427d50e WARNING {'key': 'This is a WARNING message from producer!'}\",\"time\":1779779982990,\"host_name\":\"\",\"ip\":\"\",\"path\":\"\",\"log_uid\":\"\",\"line_no\":1779779982990921258,\"customLabels\":{\"function\":\"${opentelekomcloud_fgs_function_v2.FG_ANALYSE.name}\"}}"
        ],
        "owner" : var.OTC_SDK_PROJECTID,
        "log_group_id" : opentelekomcloud_lts_group_v2.AuditLogGroup.id,
        "log_topic_id" : opentelekomcloud_lts_stream_v2.AuditLogStream.id
      }))
  } }))
}

resource "opentelekomcloud_fgs_event_v2" "FG_ANALYSE_test_err" {
  function_urn = opentelekomcloud_fgs_function_v2.FG_ANALYSE.urn
  name         = "LTS_ERR"
  content = base64encode(jsonencode({
    "lts" : {
      "data" : base64encode(jsonencode({
        "logs" : [
          "{\"hostId\":\"\",\"message\":\"2026-05-26T07:19:42Z 17ea9752-a166-420c-9efa-8a3e9427d50e ERROR {'key': 'This is a ERROR message from producer!'}\",\"time\":1779779982990,\"host_name\":\"\",\"ip\":\"\",\"path\":\"\",\"log_uid\":\"\",\"line_no\":1779779982990921258,\"customLabels\":{\"function\":\"${opentelekomcloud_fgs_function_v2.FG_ANALYSE.name}\"}}"
        ],
        "owner" : var.OTC_SDK_PROJECTID,
        "log_group_id" : opentelekomcloud_lts_group_v2.AuditLogGroup.id,
        "log_topic_id" : opentelekomcloud_lts_stream_v2.AuditLogStream.id
      }))
  } }))
}

resource "opentelekomcloud_fgs_event_v2" "FG_ANALYSE_test_inf" {
  function_urn = opentelekomcloud_fgs_function_v2.FG_ANALYSE.urn
  name         = "LTS_INF"
  content = base64encode(jsonencode({
    "lts" : {
      "data" : base64encode(jsonencode({
        "logs" : [
          "{\"hostId\":\"\",\"message\":\"2026-05-26T07:19:42Z 17ea9752-a166-420c-9efa-8a3e9427d50e INFO {'key': 'This is a INFO message from producer!'}\",\"time\":1779779982990,\"host_name\":\"\",\"ip\":\"\",\"path\":\"\",\"log_uid\":\"\",\"line_no\":1779779982990921258,\"customLabels\":{\"function\":\"${opentelekomcloud_fgs_function_v2.FG_ANALYSE.name}\"}}"
        ],
        "owner" : var.OTC_SDK_PROJECTID,
        "log_group_id" : opentelekomcloud_lts_group_v2.AuditLogGroup.id,
        "log_topic_id" : opentelekomcloud_lts_stream_v2.AuditLogStream.id
      }))
  } }))
}

resource "opentelekomcloud_fgs_event_v2" "FG_ANALYSE_test_multiple" {
  function_urn = opentelekomcloud_fgs_function_v2.FG_ANALYSE.urn
  name         = "LTS_MULTIPLE"
  content = base64encode(jsonencode({
    "lts" : {
      "data" : base64encode(jsonencode({
        "logs" : [
          "{\"hostId\":\"\",\"message\":\"2026-05-26T07:19:42Z 17ea9752-a166-420c-9efa-8a3e9427d50e INFO {'key': 'This is a INFO message from producer!'}\",\"time\":1779779982990,\"host_name\":\"\",\"ip\":\"\",\"path\":\"\",\"log_uid\":\"\",\"line_no\":1779779982990921258,\"customLabels\":{\"function\":\"${opentelekomcloud_fgs_function_v2.FG_ANALYSE.name}\"}}",
          "{\"hostId\":\"\",\"message\":\"2026-05-26T07:19:42Z 17ea9752-a166-420c-9efa-8a3e9427d50e WARNING {'key': 'This is a WARNING message from producer!'}\",\"time\":1779779982990,\"host_name\":\"\",\"ip\":\"\",\"path\":\"\",\"log_uid\":\"\",\"line_no\":1779779982990921258,\"customLabels\":{\"function\":\"${opentelekomcloud_fgs_function_v2.FG_ANALYSE.name}\"}}",
          "{\"hostId\":\"\",\"message\":\"2026-05-26T07:19:42Z 17ea9752-a166-420c-9efa-8a3e9427d50e ERROR {'key': 'This is a ERROR message from producer!'}\",\"time\":1779779982990,\"host_name\":\"\",\"ip\":\"\",\"path\":\"\",\"log_uid\":\"\",\"line_no\":1779779982990921258,\"customLabels\":{\"function\":\"${opentelekomcloud_fgs_function_v2.FG_ANALYSE.name}\"}}"
        ],
        "owner"        = var.OTC_SDK_PROJECTID,
        "log_group_id" = opentelekomcloud_lts_group_v2.AuditLogGroup.id,
        "log_topic_id" = opentelekomcloud_lts_stream_v2.AuditLogStream.id
      }))
  } }))
}


output "ANALYSIS_FUNCTION_URN" {
  value = opentelekomcloud_fgs_function_v2.FG_ANALYSE.urn
}

output "ANALYSIS_FUNCTION_VERSION" {
  value = opentelekomcloud_fgs_function_v2.FG_ANALYSE.version
}
