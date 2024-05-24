resource "aws_vpc" "demo_eks" {
  cidr_block           = "10.0.0.0/16" # Only used for demo purposes
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-${var.org_code}-demo"
  }
}

resource "aws_subnet" "demo_eks_public" {
  vpc_id                  = aws_vpc.demo_eks.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-public"
  }
}

resource "aws_subnet" "demo_eks_private_b" {
  vpc_id                  = aws_vpc.demo_eks.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-eks-private-b"
  }
}

resource "aws_subnet" "demo_eks_private_c" {
  vpc_id                  = aws_vpc.demo_eks.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-eks-private-c"
  }
}

resource "aws_internet_gateway" "demos_eks_igw" {
  vpc_id = aws_vpc.demo_eks.id

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-eks-igw"
  }
}

resource "aws_eip" "demo_eks_nat" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-eks-nat"
  }
}

resource "aws_nat_gateway" "demo_eks_nat" {
  allocation_id = aws_eip.demo_eks_nat.id
  subnet_id     = aws_subnet.demo_eks_public.id

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-eks-nat"
  }

  depends_on = [aws_internet_gateway.demos_eks_igw]
}

resource "aws_route_table" "demo_eks_public" {
  vpc_id = aws_vpc.demo_eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demos_eks_igw.id
  }

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-eks-public"
  }
}

resource "aws_route_table_association" "demo_eks_public" {
  subnet_id      = aws_subnet.demo_eks_public.id
  route_table_id = aws_route_table.demo_eks_public.id
}

resource "aws_route_table" "demo_eks_private" {
  vpc_id = aws_vpc.demo_eks.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo_eks_nat.id
  }

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-eks-private"
  }
}

resource "aws_route_table_association" "demo_eks_private_b" {
  subnet_id      = aws_subnet.demo_eks_private_b.id
  route_table_id = aws_route_table.demo_eks_private.id
}

resource "aws_route_table_association" "demo_eks_private_c" {
  subnet_id      = aws_subnet.demo_eks_private_c.id
  route_table_id = aws_route_table.demo_eks_private.id
}