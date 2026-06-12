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
import random
import base64
import requests
from datetime import datetime

from obs import ObsClient


LOGGER_PREFIX = "log"  # The prefix of log file stored in obs, you can change it as you like, for example, "mylog"
ALARM_LOG_KEY = ["WARN", "WRN", "ERROR", "ERR"]  # If the log contains these keywords, it will be considered as an alarm log and stored in obs, you can change it as you like
SMN_SUBJECT = "FunctionGraph Log Analysis Alarm"


def handler(event, context):
    log = context.getLogger()
    
    log.info("Received event: " + json.dumps(event))

    obs_address = context.getUserData("obs_address")
    obs_store_bucket = context.getUserData("obs_store_bucket")
    
    bucket_endpoint = context.getUserData("obs_store_bucket_endpoint")

    if not obs_address:
        raise Exception("Please configure obs_address environment variable")
      
    if not obs_store_bucket:
        raise Exception("Please configure obs_store_bucket environment variable")  

    if not context.getSecurityAccessKey():
        raise Exception("Can not get SecurityAccessKey. Please check agency")

    if not context.getSecuritySecretKey():
        raise Exception("Can not get SecuritySecretKey. Please check agency")
    
    if not context.getSecurityToken():
      raise Exception("Can not get SecurityToken. Please check agency")
     
    if not context.getToken():
        raise Exception("Can not get Token. Please check agency")

    if not context.getUserData("smn_urn"):
        raise Exception("Please configure smn_urn  environment variable")

    if not context.getUserData("smn_endpoint"):
        raise Exception("Please configure smn_endpoint  environment variable")
        
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
    
    for alarm in alarm_logs:        
        object_name = gen_log_name()
        logs_str = json.dumps(alarm)

        res = upload_content_to_obs(obs_client, obs_store_bucket, logs_str, object_name)

        log.info(
            f"Upload log to obs, bucket: {obs_store_bucket}, object name: {object_name}, result: {res}"
        )

        send_smn_msg(context, logs_str, f"https://{bucket_endpoint}/{object_name}")

    return {
        "statusCode": 200,
        "isBase64Encoded": False,
        "body": "ok",
        "headers": {
            "Content-Type": "application/json"
        }
    }

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
    except Exception:
        import traceback

        print(traceback.format_exc())
        print("=========source log============")
        print(content)
        return False
    return True


def send_smn_msg(context, logs_str, log_obs_path):
        
    endpoint = context.getUserData("smn_endpoint")
    
    topic_urn = context.getUserData("smn_urn")
    project_id = context.getProjectID()
    
    message = f"{SMN_SUBJECT} <br><br>"
    message += "<table>"
    message += "<thead><tr><th>Log Obs Path</th><th>Alarm Log</th></tr></thead>"
    message += f"<tbody><tr><td>{log_obs_path}</td><td>{logs_str}</td></tr></tbody>"
    message += "</table>"
    
    url = f'https://{endpoint}/v2/{project_id}/notifications/topics/{topic_urn}/publish'
    headers = {
        "x-auth-token": context.getToken(),
        "content-type": 'application/json'
    }
    
    msg = {
        "subject": SMN_SUBJECT,
        "message": message,
        "time_to_live" : "120"
    }
    
    resp = requests.post(url, json=msg, headers=headers)
    if resp.status_code >= 400:
        context.getLogger().error("Send msg failed,status code=" + str(resp.status_code) + ",body=" + str(resp.content))
        return False

    print("smn response :", resp)
    
    return True
