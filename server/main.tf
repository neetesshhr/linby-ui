provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.deployregion
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer_key"
  public_key = file(var.public_key_path)  # Point to your public key
}

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow ports 22, 80"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ServerMaker" {
  ami           = var.ami_id  
  instance_type = var.instancetype
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    Name = var.ServerName
  }

  provisioner "local-exec" {
    command = "echo The instance is created with IP: ${self.public_ip} > instance_info.txt"
  }
}
