provider "aws" {
    region = "us-east-2"
}

variable "cidr_blocks" {
    description = "vpc cidr block"
    type = list(object({
        cidr_block = string
        name = string
    }))
}
variable "my_public_key" {
}

resource "aws_vpc" "development-vpc" {
    cidr_block = var.cidr_blocks[0].cidr_block
    tags = {
        Name = var.cidr_blocks[0].name
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id     = aws_vpc.development-vpc.id
    cidr_block = var.cidr_blocks[1].cidr_block
    availability_zone = "us-east-2a"
    tags = {
        Name = var.cidr_blocks[1].name
    }
}

data "aws_vpc" "existing_vpc" {
    #"query existing resources"
    id = aws_vpc.development-vpc.id
}

resource "aws_subnet" "dev-subnet-2" {
    vpc_id     = data.aws_vpc.existing_vpc.id
    cidr_block = var.cidr_blocks[2].cidr_block
    availability_zone = "us-east-2a"
    tags = {
        Name = var.cidr_blocks[2].name
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.development-vpc.id
  tags = {
    Name = "IG"
  }
}

resource "aws_route_table" "app-route-table" {
  vpc_id = aws_vpc.development-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "vpc-route-table"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.dev-subnet-1.id
  route_table_id = aws_route_table.app-route-table.id
}

resource "aws_security_group" "my_app_sg" {
  name        = "my_app_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.development-vpc.id

  ingress {
    description = "SSH for VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]       #Who will access your machine
  }

  ingress {
    description = "HTTP for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]       #Who will access your machine
  }

  ingress {
    description = "HTTPS for VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]       #Who will access your machine
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my_app_sg"
  }
}

resource "aws_security_group" "my_db_sg" {
  name        = "my_db_sg"
  description = "Allow Port"
  vpc_id      = aws_vpc.development-vpc.id

  ingress {
    description = "Port for DB VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]       #Who will access your machine
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my_db_sg"
  }
}


data "aws_ami" "latest_amazon_linux_img" {
  most_recent      = true
  owners           = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key-pair"
  public_key = file(var.my_public_key)
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.latest_amazon_linux_img.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.dev-subnet-1.id
  vpc_security_group_ids  = [aws_security_group.my_app_sg.id]
  availability_zone = "us-east-2a"
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  tags = {
    Name = "Dev EC2 App Instance"
  }
  user_data = file("entrypoint-app.sh")
}

resource "aws_instance" "db" {
  ami           = data.aws_ami.latest_amazon_linux_img.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.dev-subnet-2.id
  vpc_security_group_ids  = [aws_security_group.my_db_sg.id]
  availability_zone = "us-east-2a"
  associate_public_ip_address = false
  key_name = aws_key_pair.ssh-key.key_name
  tags = {
    Name = "Dev EC2 DB Instance"
  }
  user_data = file("entrypoint-db.sh")
}

output "dev-vpc-id" {
    value = aws_vpc.development-vpc.id
}
output "dev-subnet1-id" {
    value = aws_subnet.dev-subnet-1.id
}
output "dev-subnet2-id" {
    value = aws_subnet.dev-subnet-2.id
}
output "app-ec2-instance" {
    value = aws_instance.web.id
}
output "db-ec2-instance" {
    value = aws_instance.db.id
}
output "ec2-public-ip" {
    value = aws_instance.web.public_ip
}