provider "aws" {
  region = var.aws-region
}

resource "aws_vpc" "main" {
  cidr_block       = var.vpc-cidr
  instance_tenancy = var.instance-tenancy
  tags = {
    Name = "ninja-vpc-01"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public-subnet-cidr
  availability_zone       = var.subnets-azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "ninja-pub-sub-01"
  }
}

resource "aws_subnet" "private-subnets" {
  count = length(var.private-subnets-cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private-subnets-cidr[count.index]
  availability_zone       = var.subnets-azs[count.index]

  tags = {
    Name = "ninja-priv-sub-0${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ninja-igw-01"
  }
}

resource "aws_eip" "elastic-ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id     = aws_subnet.public-subnet.id 

  tags = {
    Name = "ninja-nat-01"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-rt-01"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt-01"
  }
}

resource "aws_route" "public-route" {
  route_table_id        = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id            = aws_internet_gateway.igw.id
}

resource "aws_route" "private-route" {
  route_table_id        = aws_route_table.private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public-subnet-association" {
  subnet_id        = aws_subnet.public-subnet.id
  route_table_id   = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private-subnet-association" {
  count           = length(aws_subnet.private-subnets)
  subnet_id       = aws_subnet.private-subnets[count.index].id
  route_table_id  = aws_route_table.private-rt.id
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg-01"
  }
}

resource "aws_security_group" "private_instance_sg" {
  name        = "private-instance-sg"
  description = "Security group for private instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port          = 0
    to_port            = 0
    protocol           = "-1"
    security_groups  = [aws_security_group.bastion_sg.id]  # Allow traffic from bastion SG
  }

  ingress {
    from_port          = 5432
    to_port            = 5432
    protocol           = "tcp"
    security_groups  = [aws_security_group.bastion_sg.id]  # Allow traffic from bastion SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-instance-sg"
  }
}
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = aws_iam_role.ec2_role.name
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_instance" "bastion" {
  ami           = var.ami-id
  instance_type = var.instance-type
  subnet_id     = aws_subnet.public-subnet.id
  key_name      = var.key-name

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name  # Attach IAM role to the instance

  tags = {
    Name = "bastion-instance-01"
  }
}
resource "aws_instance" "private_instance" {
  count = length(aws_subnet.private-subnets)

  ami           = var.ami-id
  instance_type = var.instance-type
  subnet_id     = aws_subnet.private-subnets[count.index].id
  key_name      = var.key-name

  vpc_security_group_ids = [aws_security_group.private_instance_sg.id]

  tags = {
    Name = "postgres-server-0${count.index + 1}"
  }
}
