resource "aws_flow_log" "cloudwatch-logs" {
  iam_role_arn    = "${aws_iam_role.flowlogs-role.arn}"
  log_destination = "${aws_cloudwatch_log_group.vpc-log-group.arn}"
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "vpc-log-group" {
  name = "vpc-logs"
}

resource "aws_iam_role" "flowlogs-role" {
  name = "flowlogs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flowlogs-policy" {
  name = "flowlogs-policy"
  role = "${aws_iam_role.flowlogs-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_flow_log" "s3-flowlog" {
  log_destination      = "${aws_s3_bucket.flowlogs-bucket.arn}"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
}
