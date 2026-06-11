resource "opentelekomcloud_smn_topic_v2" "topic_1" {
  name         = format("%s_%s_topic_1", var.prefix, var.function_name)
  display_name = format("Message from FG function: %s", var.function_name)

  tags = {
    "app_group" = var.tag_app_group
  }
}

resource "opentelekomcloud_smn_subscription_v2" "subscription_1" {
  topic_urn = opentelekomcloud_smn_topic_v2.topic_1.id
  protocol  = "email"
  endpoint  = var.SMN_EMAIL_ADDRESS
  remark = format("Subscription for %s", var.function_name)
  
}