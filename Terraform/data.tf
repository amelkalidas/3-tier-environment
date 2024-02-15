data "http" "ipinfo" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_iam_policy" "ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  
}
data "aws_iam_policy" "s3" {
  arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  
}