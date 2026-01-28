output "ssm_document_name" {
  description = "Name of the SSM Automation document for lifecycle handling."
  value       = aws_ssm_document.handler.name
}

output "lifecycle_event_rule" {
  description = "EventBridge rule for ASG lifecycle termination events."
  value       = aws_cloudwatch_event_rule.terminate.name
}
output "asg_name" {
  description = "The name of the ASG created. Use this to find it in the EC2 Console."
  value       = aws_autoscaling_group.asg.name
}

output "instance_ips" {
  description = "Public IPs of the demo instances (useful for SSH/Log tailing)."
  value       = "You can find these in the EC2 console under the prefix: ${var.prefix}"
}

output "configurator_lambda_name" {
  description = "Name of the Lambda that adds the hook. Check CloudWatch Logs for this function."
  value       = aws_lambda_function.configurator.function_name
}

output "configurator_event_rule" {
  description = "The EventBridge rule monitoring for ASG creation."
  value       = aws_cloudwatch_event_rule.asg_create.name
}

output "ssm_automation_document" {
  description = "The 'Brain' of the draining logic. Check 'SSM > Automation' to see this running during scale-in."
  value       = aws_ssm_document.handler.name
}

output "lifecycle_rule_arn" {
  description = "The EventBridge rule that triggers the SSM draining handler."
  value       = aws_cloudwatch_event_rule.terminate.arn
}

output "demo_ssh_command" {
  description = "Run this on an instance during the 4-minute drain to prove it is alive."
  value       = "tail -f /tmp/sigterm.log"
}

output "demo_systemd_check" {
  description = "Run this to see the 'deactivating (stop-sigterm)' state and the override."
  value       = "systemctl status ${var.service_name}.service"
}

output "manual_trigger_scale_in" {
  description = "Command to trigger the demo (Shrink the ASG to 1)."
  value       = "aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${aws_autoscaling_group.asg.name} --desired-capacity 1"
}
