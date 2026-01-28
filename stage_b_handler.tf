resource "aws_ssm_document" "handler" {
  name            = "${var.prefix}-drain-handler"
  document_type   = "Automation"
  document_format = "YAML"
  content = <<EOF
schemaVersion: '0.3'
assumeRole: "{{ AutomationAssumeRole }}"
parameters:
  InstanceId: { type: String }
  AutoScalingGroupName: { type: String }
  LifecycleHookName: { type: String }
  LifecycleActionToken: { type: String }
  ServiceName: { type: String }
  AutomationAssumeRole: { type: String }
mainSteps:
  - name: DrainAndStop
    action: aws:runCommand
    inputs:
      DocumentName: AWS-RunShellScript
      InstanceIds: ["{{ InstanceId }}"]
      Parameters:
        commands:
          - |
            UNIT="{{ ServiceName }}.service"
            sudo mkdir -p "/etc/systemd/system/$UNIT.d"
            echo -e "[Service]\nTimeoutStopSec=300s" | sudo tee "/etc/systemd/system/$UNIT.d/override.conf"
            sudo systemctl daemon-reload
            sudo systemctl stop "$UNIT" || true
            # Wait for service to stop (up to 10 mins)
            for i in {1..60}; do systemctl is-active --quiet "$UNIT" || exit 0; sleep 10; done
            exit 1
  - name: CompleteLifecycle
    action: aws:executeAwsApi
    inputs:
      Service: autoscaling
      Api: CompleteLifecycleAction
      AutoScalingGroupName: "{{ AutoScalingGroupName }}"
      LifecycleHookName: "{{ LifecycleHookName }}"
      LifecycleActionToken: "{{ LifecycleActionToken }}"
      InstanceId: "{{ InstanceId }}"
      LifecycleActionResult: CONTINUE
EOF
}

resource "aws_cloudwatch_event_rule" "terminate" {
  name = "${var.prefix}-terminate-rule"
  event_pattern = jsonencode({
    "source": ["aws.autoscaling"],
    "detail-type": ["EC2 Instance-terminate Lifecycle Action"],
    "detail": {
      "AutoScalingGroupName": [{
        "prefix": var.prefix
      }]
    }
  })
}

resource "aws_cloudwatch_event_target" "ssm_target" {
  rule     = aws_cloudwatch_event_rule.terminate.name
  arn      = aws_ssm_document.handler.arn
  role_arn = aws_iam_role.ssm_role.arn
  
  input_transformer {
    input_paths = { 
      asg_val  = "$.detail.AutoScalingGroupName", 
      hook_val = "$.detail.LifecycleHookName", 
      id_val   = "$.detail.EC2InstanceId", 
      tok_val  = "$.detail.LifecycleActionToken" 
    }
    input_template = <<EOF
{
  "InstanceId": ["<id_val>"],
  "AutoScalingGroupName": ["<asg_val>"],
  "LifecycleHookName": ["<hook_val>"],
  "LifecycleActionToken": ["<tok_val>"],
  "ServiceName": ["${var.service_name}"],
  "AutomationAssumeRole": ["${aws_iam_role.ssm_role.arn}"]
}
EOF
  }
}