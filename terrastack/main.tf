variable "owner" {
  default = ""
}

data "aws_security_group" "transit-default-sg" {
  name   = "default"
  vpc_id = module.transit-vpc.vpc_id
}

data "aws_security_group" "tenant-a-default-sg" {
  name   = "default"
  vpc_id = module.tenant-vpc-a.vpc_id
}

data "aws_security_group" "tenant-b-default-sg" {
  name   = "default"
  vpc_id = module.tenant-vpc-b.vpc_id
}

# Security Groups, because Security comes first
## and security is everybody's business

resource "aws_default_security_group" "transit-default-sg" {
  vpc_id = module.transit-vpc.vpc_id

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  ingress {
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
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

resource "aws_default_security_group" "tenant-a-default-sg" {
  vpc_id = module.tenant-vpc-a.vpc_id
  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  ingress {
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
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

resource "aws_default_security_group" "tenant-b-default-sg" {
  vpc_id = module.tenant-vpc-b.vpc_id
  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  ingress {
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
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

# VPC Section
## Creates three VPCs

module "transit-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "transit-vpc"
  cidr = "10.0.0.0/21"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24"]

  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # ## create vpc endpoints
  # enable_s3_endpoint = true

  public_subnet_tags = {
    Layer = "loadbalancer"
  }

  private_subnet_tags = {
    Layer = "proxy"
  }

  tags = {
    Terraform   = "true"
    Environment = "nonprod"
    Owner       = var.owner
  }

}

module "tenant-vpc-a" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tenant-vpc-a"
  cidr = "10.1.0.0/22"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
  intra_subnets   = ["10.1.3.0/25", "10.1.3.128/25"]


  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = false

  # ## create vpc endpoints
  # enable_s3_endpoint = true

  private_subnet_tags = {
    Layer = "app"
  }

  intra_subnet_tags = {
    Layer = "data"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Owner       = var.owner
  }
}

module "tenant-vpc-b" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tenant-vpc-b"
  cidr = "10.2.0.0/22"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
  intra_subnets   = ["10.2.3.0/25", "10.2.3.128/25"]


  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = false

  # ## create vpc endpoints
  # enable_s3_endpoint = true

  private_subnet_tags = {
    Layer = "app"
  }

  intra_subnet_tags = {
    Layer = "data"
  }

  tags = {
    Terraform   = "true"
    Environment = "itg"
    Owner       = var.owner
  }
}

###########################
# Transit Gateway Section #
###########################

# Transit Gateway
## Default association and propagation are disabled since our scenario involves
## a more elaborated setup where
## - Dev VPCs can reach themselves and the Shared VPC
## - the Shared VPC can reach all VPCs
## - the Prod VPC can only reach the Shared VPC
## The default setup being a full mesh scenario where all VPCs can see every other
resource "aws_ec2_transit_gateway" "web-tgw" {
  description                     = "web transit gateway"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "web-tgw"
  }
}

# VPC attachment

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-transit-vpc" {
  subnet_ids                                      = [module.transit-vpc.private_subnets[0], module.transit-vpc.private_subnets[1], module.transit-vpc.private_subnets[2]]
  transit_gateway_id                              = "${aws_ec2_transit_gateway.web-tgw.id}"
  vpc_id                                          = module.transit-vpc.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "tgw-att-transit-vpc"
  }
  depends_on = ["aws_ec2_transit_gateway.web-tgw"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-tenant-vpc-a" {
  subnet_ids                                      = [module.tenant-vpc-a.private_subnets[0], module.tenant-vpc-a.private_subnets[1], module.tenant-vpc-a.private_subnets[2]]
  transit_gateway_id                              = "${aws_ec2_transit_gateway.web-tgw.id}"
  vpc_id                                          = module.tenant-vpc-a.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "tgw-att-tenant-vpc-a"
  }
  depends_on = ["aws_ec2_transit_gateway.web-tgw"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-tenant-vpc-b" {
  subnet_ids                                      = [module.tenant-vpc-b.private_subnets[0], module.tenant-vpc-b.private_subnets[1], module.tenant-vpc-b.private_subnets[2]]
  transit_gateway_id                              = "${aws_ec2_transit_gateway.web-tgw.id}"
  vpc_id                                          = module.tenant-vpc-b.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "tgw-att-tenant-vpc-b"
  }
  depends_on = ["aws_ec2_transit_gateway.web-tgw"]
}

# # Route Tables

resource "aws_ec2_transit_gateway_route_table" "tgw-transit-vpc-rt" {
  transit_gateway_id = "${aws_ec2_transit_gateway.web-tgw.id}"
  tags = {
    Name = "tgw-transit-vpc-rt"
  }
  depends_on = ["aws_ec2_transit_gateway.web-tgw"]
}

resource "aws_ec2_transit_gateway_route_table" "tgw-dev-rt" {
  transit_gateway_id = "${aws_ec2_transit_gateway.web-tgw.id}"
  tags = {
    Name = "tgw-dev-rt"
  }
  depends_on = ["aws_ec2_transit_gateway.web-tgw"]
}

resource "aws_ec2_transit_gateway_route_table" "tgw-itg-rt" {
  transit_gateway_id = "${aws_ec2_transit_gateway.web-tgw.id}"
  tags = {
    Name = "tgw-itg-rt"
  }
  depends_on = ["aws_ec2_transit_gateway.web-tgw"]
}

# Route Tables Associations
## This is the link between a VPC (already symbolized with its attachment to the Transit Gateway)
##  and the Route Table the VPC's packet will hit when they arrive into the Transit Gateway.
## The Route Tables Associations do not represent the actual routes the packets are routed to.
## These are defined in the Route Tables Propagations section below.

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-transit-vpc-assoc" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-transit-vpc.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-transit-vpc-rt.id}"
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-tenant-vpc-a-assoc" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-tenant-vpc-a.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-dev-rt.id}"
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-tenant-vpc-b-assoc" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-tenant-vpc-b.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-itg-rt.id}"
}

# Route Tables Propagations
## This section defines which VPCs will be routed from each Route Table created in the Transit Gateway

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-dev-to-transit-vpc" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-tenant-vpc-a.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-transit-vpc-rt.id}"
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-itg-to-transit-vpc" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-tenant-vpc-b.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-transit-vpc-rt.id}"
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-transit-vpc-to-dev" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-transit-vpc.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-dev-rt.id}"
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-transit-vpc-to-itg" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-transit-vpc.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-itg-rt.id}"
}

# Transit Gateway Routes Section
## Creates default routes for attached dev and itg environments to reach the Internet

resource "aws_ec2_transit_gateway_route" "dev" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-transit-vpc.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-dev-rt.id}"
}

resource "aws_ec2_transit_gateway_route" "itg" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.tgw-att-transit-vpc.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.tgw-itg-rt.id}"
}

# Subnet Route Section
## Updates subnet route tables to point at Transit Gateway

resource "aws_route" "transit-a-route" {
  route_table_id         = module.transit-vpc.private_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}

resource "aws_route" "transit-b-route" {
  route_table_id         = module.transit-vpc.private_route_table_ids[1]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}

resource "aws_route" "transit-c-route" {
  route_table_id         = module.transit-vpc.private_route_table_ids[2]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}

resource "aws_route" "transit-public-route" {
  route_table_id         = module.transit-vpc.public_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}

resource "aws_route" "dev-a-route" {
  route_table_id         = module.tenant-vpc-a.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}

resource "aws_route" "dev-b-route" {
  route_table_id         = module.tenant-vpc-a.private_route_table_ids[1]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}
resource "aws_route" "dev-c-route" {
  route_table_id         = module.tenant-vpc-a.private_route_table_ids[2]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}

resource "aws_route" "itg-a-route" {
  route_table_id         = module.tenant-vpc-b.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}

resource "aws_route" "itg-b-route" {
  route_table_id         = module.tenant-vpc-b.private_route_table_ids[1]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}
resource "aws_route" "itg-c-route" {
  route_table_id         = module.tenant-vpc-b.private_route_table_ids[2]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = "${aws_ec2_transit_gateway.web-tgw.id}"
}
