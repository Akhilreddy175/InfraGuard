terraform {
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 5.0" }
    local = { source = "hashicorp/local" }
  }
}

provider "aws" { region = var.region }

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "sg" {
  name = "int333-sg"
  dynamic "ingress" {
    for_each = [22, 80]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  tags                   = { Name = "web" }
}

resource "aws_instance" "monitor" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  tags                   = { Name = "monitor" }
  depends_on             = [aws_instance.web]
}

resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<-EOT
    [web]
    ${aws_instance.web.public_ip}
    [monitor]
    ${aws_instance.monitor.public_ip}
    [all:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${abspath("${path.module}/../int333-key.pem")}
    web_private_ip=${aws_instance.web.private_ip}
  EOT
}
