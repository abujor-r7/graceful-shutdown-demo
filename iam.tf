# 1. EC2 IDENTITY (For the instances)
resource "aws_iam_role" "ec2_role" {
  name = "${var.prefix}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Allows the EC2 to talk to SSM (Fleet Manager / Run Command)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# 2. SSM AUTOMATION ROLE (The "Orchestrator")
resource "aws_iam_role" "ssm_role" {
  name = "${var.prefix}-ssm-automation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = ["ssm.amazonaws.com", "events.amazonaws.com"]
      }
    }]
  })
}

resource "aws_iam_role_policy" "ssm_policy" {
  role = aws_iam_role.ssm_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution",
          "ssm:DescribeAutomationExecutions",
          "ssm:GetDocument",           
          "ssm:DescribeDocument",     
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:GetCommandInvocation",
          "ssm:DescribeInstanceInformation",
          "autoscaling:CompleteLifecycleAction"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = var.account_id != "" && var.ssm_automation_role_name != "" ? "arn:aws:iam::${var.account_id}:role/${var.ssm_automation_role_name}" : aws_iam_role.ssm_role.arn
      }
    ]
  })
}

# 3. LAMBDA ROLE (The "Configurator")
resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action   = ["autoscaling:PutLifecycleHook"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      }
    ]
  })
}
