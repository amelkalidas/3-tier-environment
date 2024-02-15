# Create the IAM role
resource "aws_iam_role" "ec2ssmrole_dev" {
  name = "ec2ssmrole_dev"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the policies to the role
resource "aws_iam_role_policy_attachment" "s3_read_access_attach" {
  role       = aws_iam_role.ec2ssmrole_dev.name
  policy_arn = data.aws_iam_policy.s3.arn
}

resource "aws_iam_role_policy_attachment" "ssm_managed_attach" {
  role       = aws_iam_role.ec2ssmrole_dev.name
  policy_arn = data.aws_iam_policy.ssm.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name    = "ssmands3role"
    role    = aws_iam_role.ec2ssmrole_dev.name
  
}
