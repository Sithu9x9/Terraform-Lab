terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_vpc" "Lab_VPC" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC"
  }
}

resource "aws_subnet" "Lab_Public_Subnet" {
  vpc_id     = aws_vpc.Lab_VPC.id
  cidr_block = "192.168.100.0/24"

  tags = {
    Name = "Public_Subnet"
  }
}

resource "aws_subnet" "Lab_Private_Subnet" {
  vpc_id     = aws_vpc.Lab_VPC.id
  cidr_block = "192.168.200.0/24"

  tags = {
    Name = "Private_Subnet"
  }
}

resource "aws_internet_gateway" "Lab_Internet_Gateway" {
  vpc_id = aws_vpc.Lab_VPC.id

  tags = {
    Name = "Internet_Gateway"
  }
}

resource "aws_route_table" "Lab_Public_RT" {
  vpc_id = aws_vpc.Lab_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Lab_Internet_Gateway.id
  }
}


resource "aws_route_table_association" "Public_Subnet_Asso" {
  subnet_id      = aws_subnet.Lab_Public_Subnet.id
  route_table_id = aws_route_table.Lab_Public_RT.id
}

resource "aws_eip" "Elastic_IP" {
  vpc      = true
  tags = {
    Name = "ElasticIP"
  }
}

resource "aws_nat_gateway" "Lab_NAT_GW" {
  allocation_id = aws_eip.Elastic_IP.id
  subnet_id     = aws_subnet.Lab_Public_Subnet.id

  tags = {
    Name = "NAT_GW"
  }
}

resource "aws_route_table" "Lab_Private_RT" {
  vpc_id = aws_vpc.Lab_VPC.id

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.Lab_NAT_GW.id
  }
}

resource "aws_route_table_association" "Private_Subnet_Asso" {
  subnet_id      = aws_subnet.Lab_Private_Subnet.id
  route_table_id = aws_route_table.Lab_Private_RT.id
}

resource "aws_instance" "web" {
  ami                    = "ami-0c7217cdde317cfec"
  subnet_id              = aws_subnet.Lab_Public_Subnet.id
  key_name               = "james"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Terraform_Security.id]
  tags = {
    Name = "Web"
  }
}

resource "aws_instance" "web1" {
  ami                    = "ami-0c7217cdde317cfec"
  subnet_id              = aws_subnet.Lab_Private_Subnet.id
  key_name               = "james"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Terraform_Security.id]
  tags = {
    Name = "Web1"
  }
}

resource "aws_eip" "Terraform_ip" {
  instance = aws_instance.web.id
  domain   = "vpc"
}

resource "aws_security_group" "Terraform_Security" {
  name        = "Terraform_Security"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.Lab_VPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}