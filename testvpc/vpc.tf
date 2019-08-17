module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "test"
  cidr = "10.0.0.0/22"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  private_subnets = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24","10.0.6.0/24", "10.0.7.0/24"]

  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  ## create vpc endpoints
  enable_s3_endpoint = false
  enable_dynamo_db_endpoint = false

  public_subnet_tags = {
    Layer = "loadbalancer"
  }

  private_subnet_tags = {
    Layer = "app"
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  ingress {
    protocol    = "-1"
    cidr_blocks = [var.net_cidr]
    from_port   = 0
    to_port     = 0
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
