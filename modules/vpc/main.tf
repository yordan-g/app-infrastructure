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

resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.public["eu-west-3a"].id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "${data.aws_ssm_parameter.home_public_ip_1.value}/32"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name = "main"
  }
}

resource "aws_security_group" "web_server_sg" {
  name        = "${var.env}-web-server-sg"
  description = "Custom security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "Allow inbound HTTP access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    description      = "Allow inbound HTTPS access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    description      = "Allow inbound traffic from other instances associated with this security group"
    from_port        = 0
    to_port          = 0
    # -1 is all protocols
    protocol         = "-1"
    self             = true
  }

  ingress {
    description      = "Allow inbound SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${data.aws_ssm_parameter.home_public_ip_1.value}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "home_public_ip_1" {
  name = "home-public-ip-1"
}