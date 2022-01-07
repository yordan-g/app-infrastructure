resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id    = aws_vpc.vpc.id

  tags      = {
    Name        = "${var.env}-internet-gateway"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# Create 1 public subnets for each AZ within the regional VPC
resource "aws_subnet" "public" {
  for_each = var.public_subnet_numbers

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key

  # 2,048 IP addresses each
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, each.value)

  tags = {
    Name        = "${var.env}-public-subnet"
    Role        = "public"
    Environment = var.env
    ManagedBy   = "terraform"
    Subnet      = "${each.key}-${each.value}"
  }
}

# Custom route table to replace the default main route table
resource "aws_route_table" "public_route_table" {
  vpc_id       = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags       = {
    Name        = "${var.env}-route-table"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_main_route_table_association" "main_route_table" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_1_main_route_table" {
  subnet_id      = aws_subnet.public["eu-west-3a"].id
  route_table_id = aws_route_table.public_route_table.id
}