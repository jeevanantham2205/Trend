terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------
# VPC
# -----------------------------

resource "aws_vpc" "trend_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "trend-vpc"
    Environment = "devops"
    Project     = "Trend"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id

  tags = {
    Name    = "trend-igw"
    Project = "Trend"
  }
}

# -----------------------------
# Public Subnet
# -----------------------------

resource "aws_subnet" "trend_public_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "trend-public-subnet"
    Project = "Trend"
  }
}

# -----------------------------
# Public Route Table
# -----------------------------

resource "aws_route_table" "trend_public_rt" {
  vpc_id = aws_vpc.trend_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.trend_igw.id
  }

  tags = {
    Name    = "trend-public-rt"
    Project = "Trend"
  }
}

resource "aws_route_table_association" "trend_public_rta" {
  subnet_id      = aws_subnet.trend_public_subnet.id
  route_table_id = aws_route_table.trend_public_rt.id
}

# -----------------------------
# Jenkins Security Group
# -----------------------------

resource "aws_security_group" "jenkins_sg" {
  name        = "trend-jenkins-sg"
  description = "Security group for Trend Jenkins server"
  vpc_id      = aws_vpc.trend_vpc.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "trend-jenkins-sg"
    Project = "Trend"
  }
}

# -----------------------------
# Jenkins IAM Role
# -----------------------------

resource "aws_iam_role" "jenkins_role" {
  name = "TrendJenkinsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "Trend"
  }
}

# -----------------------------
# Jenkins EC2 Permissions
# -----------------------------

resource "aws_iam_role_policy_attachment" "jenkins_ec2_admin" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# -----------------------------
# Jenkins ECR Permissions
# -----------------------------

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# -----------------------------
# Jenkins EKS Permissions
# -----------------------------

resource "aws_iam_role_policy_attachment" "jenkins_eks" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Additional permissions required by Jenkins
# to discover and describe EKS clusters.

resource "aws_iam_role_policy" "jenkins_eks_access" {
  name = "TrendJenkinsEKSAccess"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "eks:ListClusters",
          "eks:DescribeCluster",
          "eks:AccessKubernetesApi"
        ]

        Resource = "*"
      }
    ]
  })
}

# -----------------------------
# Jenkins Instance Profile
# -----------------------------

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "TrendJenkinsInstanceProfile"
  role = aws_iam_role.jenkins_role.name
}

# -----------------------------
# Jenkins EC2
# -----------------------------

resource "aws_instance" "jenkins" {
  ami                    = var.jenkins_ami
  instance_type          = var.jenkins_instance_type
  subnet_id              = aws_subnet.trend_public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  key_name = "trend-jenkins-key"

  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "trend-jenkins"
    Environment = "devops"
    Project     = "Trend"
  }
}
