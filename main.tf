provider "aws" {
  region = "eu-west-3"
}

variable "ssh_key_path" {}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = file(var.ssh_key_path)
}

variable "availability_zone" {}

module "vpc" {
 source = "terraform-aws-modules/vpc/aws"
 name = "vpc-ejercicio2"
 cidr = "10.0.0.0/16"
 azs = [var.availability_zone]
 private_subnets = ["10.0.0.0/24", "10.0.1.0/24"]
 public_subnets = ["10.0.100.0/24", "10.0.101.0/24"]
 enable_dns_hostnames = true
 enable_dns_support = true
 enable_nat_gateway = false
 enable_vpn_gateway = false
 tags = { Terraform = "true", Environment = "dev" }
}

resource "aws_security_group" "allow_ssh_http_https" {
 name = "allow_ssh_http_https"
 description = "Allow SSH,HTTP and HTTPS inbound traffic"
 vpc_id = module.vpc.vpc_id
 #ingress
  ingress {
    description = "SSH from VPC"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from VPC"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 # egress
 egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
 tags = {
  Name = "allow_ssh_http_https"
 }
}

data "template_file" "userdata" {
  template = file("${path.module}/userdata.sh")
}

resource "aws_instance" "web" {
  # ami a instalar
  ami = "ami-0b589b2819c2045c3" #Ubuntu22.04
  # tipo de instancia
  instance_type = "t2.micro"
  # clave ssh asociada por defecto
  key_name = aws_key_pair.deployer.key_name
  # zona de disponibilidad
  user_data              = data.template_file.userdata.rendered
  availability_zone = var.availability_zone
  vpc_security_group_ids = [aws_security_group.allow_ssh_http_https.id]
  subnet_id = element(module.vpc.public_subnets,1)
  tags = {
    Name = "Ejercicio2"
  }
}

resource "aws_ebs_volume" "web" {
  availability_zone = var.availability_zone
  size              = 4
  type = "gp3"
  encrypted =   true
  tags = {
    Name = "web-ebs"
  }
}

resource "aws_volume_attachment" "web" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web.id
  instance_id = aws_instance.web.id
}

resource "aws_eip" "eip" {
  instance      = aws_instance.web.id
  vpc           = true
  tags          = {
    Name        = "web-epi"
  }
}

output "ip_instance" {
  value = aws_instance.web.public_ip
}

output "eip_ip" {
  description = "The eip ip for ssh access"
  value       = aws_eip.eip.public_ip
}

output "ssh" {
  value = "ssh -l ubuntu ${aws_instance.web.public_ip}"
}

output "ssh_eip" {
  value = "ssh -l ubuntu ${aws_eip.eip.public_ip}"
}