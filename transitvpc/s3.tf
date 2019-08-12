
# S3 buckets for Storage, VPC flow logs, and S3 access logs
resource "aws_s3_bucket" "storage-bucket" {
  bucket = "storage-bucket"
  acl    = "private"
  logging {
    target_bucket = "${aws_s3_bucket.s3-logs-bucket.id}"
    target_prefix = "storage-bucket-logs/"
  }
  tags = {
    Name        = "storage bucket"
    Environment = var.environment
    Owner       = var.owner
  }
}
resource "aws_s3_bucket_public_access_block" "storage-bucket" {
  bucket = "${aws_s3_bucket.storage-bucket.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "flowlogs-bucket" {
  bucket = "flowlogs-bucket"
  acl    = "private"
  logging {
    target_bucket = "${aws_s3_bucket.s3-logs-bucket.id}"
    target_prefix = "flowlogs-bucket-logs/"
  }
  tags = {
    Name        = "vpc flow logs bucket"
    Environment = var.environment
    Owner       = var.owner
  }
}
resource "aws_s3_bucket_public_access_block" "flowlogs-bucket" {
  bucket = "${aws_s3_bucket.flowlogs-bucket.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket" "s3-logs-bucket" {
  bucket = "s3-logs-bucket"
  acl    = "log-delivery-write"

  tags = {
    Name        = "s3 access logs bucket"
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_s3_bucket_public_access_block" "s3-logs-bucket" {
  bucket = "${aws_s3_bucket.s3-logs-bucket.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}