import os
import json
import boto3

autoscaling = boto3.client("autoscaling")

def lambda_handler(event, context):
    print("DEBUG - Event received:", json.dumps(event))
    
    asg_name = (
        event.get("detail", {}).get("requestParameters", {}).get("autoScalingGroupName") or
        event.get("detail", {}).get("responseElements", {}).get("autoScalingGroupName") or
        event.get("asgName")
    )

    if not asg_name:
        return {"statusCode": 400, "body": "No ASG Name found in event"}

    # Restrict to allowed ASGs by prefix or name
    allowed_prefixes = os.getenv("ALLOWED_ASG_PREFIXES", "tf-demo-draining").split(",")
    allowed_asgs = os.getenv("ALLOWED_ASGS", "").split(",")
    allowed_asgs = [a for a in allowed_asgs if a]

    allowed = False
    for prefix in allowed_prefixes:
        if asg_name.startswith(prefix):
            allowed = True
            break
    if asg_name in allowed_asgs:
        allowed = True

    if not allowed:
        return {"statusCode": 403, "body": f"ASG {asg_name} is not allowed for lifecycle configuration"}

    autoscaling.put_lifecycle_hook(
        AutoScalingGroupName=asg_name,
        LifecycleHookName="graceful-terminate",
        LifecycleTransition="autoscaling:EC2_INSTANCE_TERMINATING",
        HeartbeatTimeout=int(os.getenv("HEARTBEAT_TIMEOUT", "900")),
        DefaultResult="CONTINUE",
    )
    print(f"SUCCESS: Hook applied to {asg_name}")
    return {"statusCode": 200, "body": f"Hook applied to {asg_name}"}
