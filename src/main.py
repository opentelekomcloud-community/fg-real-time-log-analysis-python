# -*- coding: utf-8 -*-

"""
Analyze the source log, if the log contains keywords, store the log in obs, and send the message to SMN

When the LTS trigger triggers the function, the event structure is as follows:
 If LTS trigger invoke this function, event will be:
    {
        "lts": {
        "data": "xxxxxxxxxxxxx"
        }
    }
 The data is base64 encrypted and needs to be decrypted before use.

 decoded data is as follows:
    {
        "logs": [{log1}, {log2}, ...],
        "owner":"6280e170bd934f60a4d851cf5ca05129",
        "log_group_id":"yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
        "log_topic_id":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }


 If use context to obtain ak sk, note that you should config agency with SMN,OBS permission for this
 function.

"""

import json
import time
import random
import base64
from obs import ObsClient
from datetime import datetime

from huaweicloudsdkcore.auth.credentials import BasicCredentials

from huaweicloudsdksmn.v2 import (
    SmnClient,
    PublishMessageRequestBody,
    PublishMessageRequest,
)

LOGGER_PREFIX = "log"  # The prefix of log file stored in obs, you can change it as you like, for example, "mylog"
ALARM_LOG_KEY = ["WARN", "WRN", "ERROR", "ERR"]  # If the log contains these keywords, it will be considered as an alarm log and stored in obs, you can change it as you like
SMN_SUBJECT = "FunctionGraph Log Analysis Alarm"


def initializer(context):
    log = context.getLogger()
    log.info("Initializer started")


def handler(event, context):
    log = context.getLogger()
    
    log.info("Received event: " + json.dumps(event))

    obs_address = context.getUserData("obs_address")
    obs_bucket = context.getUserData("obs_store_bucket")
    
    bucket_endpoint = context.getUserData("obs_store_bucket_endpoint")

    if not obs_address or not obs_bucket:
        raise Exception("Please configure obs environment variable")

    if not context.getAccessKey() or not context.getSecretKey():
        raise Exception("Can not get accessKey or secretKey. Please check agency")

    if not context.getUserData("smn_urn"):
        raise Exception("Please configure SMN  environment variable")

    
    
    # get the data from lts logs.
    encodingData = event["lts"]["data"]
    data_based = base64.b64decode(encodingData)
    data = json.loads(data_based)
    
    logs = data["logs"]
    
    alarm_logs = analyze_logs(logs)
    if len(alarm_logs) == 0:
        log.info("no need to send alarm")
        return "no alarm"

    obs_client = ObsClient(
        access_key_id=context.getSecurityAccessKey(),
        secret_access_key=context.getSecuritySecretKey(),
        security_token=context.getSecurityToken(),
        server=obs_address,
    )
    
    smn_client = new_smn_client(context)
    
    
    
    for alarm in alarm_logs:        
        object_name = gen_log_name()
        logs_str = json.dumps(alarm)

        res = upload_content_to_obs(obs_client, obs_bucket, logs_str, object_name)

        log.info(
            f"Upload log to obs, bucket: {obs_bucket}, object name: {object_name}, result: {res}"
        )

        send_smn_msg(context, smn_client, logs_str, f"{bucket_endpoint}/{object_name}")

    return "alarm success"

# Analyze logs
# iter logs, if it contain key words store it in list then return
def analyze_logs(logs):
    
    alarm_logs = []
    if not isinstance(logs, list):
        logs = json.loads(logs)
         
    for log in logs:
        log_str = json.dumps(log)    
        for item in ALARM_LOG_KEY:
            if item in log_str:
                alarm_logs.append(log)
                break
    return alarm_logs


def gen_log_name():
    t = datetime.now().strftime("%Y%m%d%H%M%S%f")
    return f"{LOGGER_PREFIX}/log-{t}-{random.randint(100000, 1000000)}.log"


def upload_content_to_obs(client: ObsClient, bucket_name, content, obj_name):
    try:
        resp = client.putContent(bucket_name, obj_name, content=content)
        if (
            resp.status > 300
        ):  # If fail to upload, print source logs if fail to upload, print alarm logs
            print("response:", resp)
            print("errorCode:", resp.errorCode)
            print("errorMessage:", resp.errorMessage)
            print("=========source log============")
            print(content)
            return False
    except:
        import traceback

        print(traceback.format_exc())
        print("=========source log============")
        print(content)
        return False
    return True


def new_smn_client(context):
    credentials = (
        BasicCredentials(
            ak=context.getSecurityAccessKey(),
            sk=context.getSecuritySecretKey(),
            
            project_id=context.getProjectID(),
        )
        .with_iam_endpoint(context.getUserData("iam_address"))
        .with_security_token(context.getSecurityToken())
        
    )

    client = (
        SmnClient.new_builder()
        .with_credentials(credentials)
        .with_endpoint(context.getUserData("smn_address"))
        .build()
    )
    return client


def send_smn_msg(context, client, logs_str, log_obs_path):
    print("start to send")
    request = PublishMessageRequest()
    request.topic_urn = context.getUserData("smn_urn")
    
    
    message = f"{SMN_SUBJECT} <br><br>"
    message += "<table>"
    message += "<thead><tr><th>Log Obs Path</th><th>Alarm Log</th></tr></thead>"
    message += f"<tbody><tr><td>{log_obs_path}</td><td>{logs_str}</td></tr></tbody>"
    message += "</table>"
    
    
    request.body = PublishMessageRequestBody(
        subject=SMN_SUBJECT, message=message
    )
    resp = client.publish_message(request)
    print("smn response :", resp)
