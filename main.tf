provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Workspace     = "learn-terraform-cloud-drift-detection"
      TTL           = "7/7/2023"
      Environment   = "Demo"
      IAC           = "Managed by Terraform Cloud"
      Name          = "CH Demo"
      Project       = "CH-IAC-1234"
      "Cost Center" = "CH-ITO"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

data "aws_key_pair" "example" {
  key_name = "rkr-key"
  # include_public_key = true

  # filter {
  #   name   = "tag:Component"
  #   values = ["web"]
  # }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
}

resource "aws_security_group" "bastion" {
  name   = "bastion_ssh"
  vpc_id = module.vpc.vpc_id

  # ingress = [
  #   { from_port = 22
  #     to_port   = 22
  #     protocol  = "tcp"
  #     # THIS DOES NOT INCLUDE MY IP ADDRESS
  #     cidr_blocks = ["65.60.165.105/32"]
  #   },
  #   {
  #     from_port = 8000
  #     to_port   = 8000
  #     protocol  = "tcp"
  #     # THIS DOES NOT INCLUDE MY IP ADDRESS
  #     cidr_blocks = ["65.60.165.105/32"]
  #   },
  # ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["65.60.165.105/32"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "ak" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks = ["65.60.165.105/32"]
  security_group_id = aws_security_group.bastion.id
}


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  instance_type = "t2.small"
  ami           = data.aws_ami.amazon_linux.id

  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = data.aws_key_pair.example.key_name
  iam_instance_profile = "rryjewski-test-role"
}
