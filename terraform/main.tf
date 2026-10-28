provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "shopnow"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "shopnow" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "shopnow-dev-vpc"
  }
}

resource "aws_internet_gateway" "shopnow" {
  vpc_id = aws_vpc.shopnow.id

  tags = {
    Name = "shopnow-dev-igw"
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.shopnow.id
  cidr_block              = cidrsubnet(aws_vpc.shopnow.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "shopnow-dev-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.shopnow.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shopnow.id
  }

  tags = {
    Name = "shopnow-dev-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}