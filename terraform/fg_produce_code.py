# -*- coding:utf-8 -*-
import json

def initializer(context):
    logger = context.getLogger()
    logger.info("init")


def handler (event, context):
    logger = context.getLogger()
    
    event_str = json.dumps(event)
    
    if "WARN" in event_str or "WRN" in event_str:
      logger.warn(event)
      
    if "ERROR" in event_str or "ERR" in event_str:
      logger.error(event)

    if "INFO" in event_str or "INF" in event_str:
      logger.info(event)
      
    return {
        "statusCode": 200,
        "isBase64Encoded": False,
        "body": json.dumps(event),
        "headers": {
            "Content-Type": "application/json"
        }
    }
