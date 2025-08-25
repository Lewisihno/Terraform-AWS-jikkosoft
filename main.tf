# Technical Assessment for AWS Cloud Middle Administrator
# Lewis Jonathan Muñoz Perez
# 1. VPC Setup & Security Groups

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
  }
      tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
}
  }

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# 1.1 Create a new VPC with two public subnets and two private subnets.

# VPC
resource "aws_vpc" "vpc_jikkosoft" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_jikkosoft"
  }
}

# Subredes públicas
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc_jikkosoft.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc_jikkosoft.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-2"
  }
}

# Subredes privadas
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc_jikkosoft.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private-Subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc_jikkosoft.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Private-Subnet-2"
  }
}

# 1.2 Configure routing between public and private subnets.

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_jikkosoft.id
  tags = {
    Name = "IGW_jikkosoft"
  }
}

# Tabla de rutas para subredes públicas
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_jikkosoft.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Ruta-Publica"
  }
}

# Asociar subredes públicas a la tabla de rutas pública
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "EIP-NAT"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id  # Debe estar en subred pública

  tags = {
    Name = "NAT-Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Tabla de rutas para subredes privadas
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc_jikkosoft.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Ruta-Privada"
  }
}

# Asociar subredes privadas a la tabla de rutas privada
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# 1.3 Create two Security Groups:

# 1.3.1 Security Group para instancia EC2 en subred pública
resource "aws_security_group" "sg_public_ec2" {
  name        = "public-ec2-sg"
  description = "Permitir SSH y HTTP desde cualquier lugar"
  vpc_id      = aws_vpc.vpc_jikkosoft.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "SG-Public-EC2"
  }
}

# 1.3.2 Security Group para instancia EC2 en subred privada
resource "aws_security_group" "sg_private_ec2" {
  name        = "private-ec2-sg"
  description = "Permitir SSH solo desde la subred publica"
  vpc_id      = aws_vpc.vpc_jikkosoft.id

  # Regla de entrada: SSH solo desde la subred publica (10.0.1.0/24 y 10.0.2.0/24)
  ingress {
    description = "SSH desde subred publica"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.public_subnet_1.cidr_block,
      aws_subnet.public_subnet_2.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Private-EC2"
  }
}

# 1.4 Launch two EC2 instances (one in each subnet) and verify connectivity between them.

# Creamos primero la key-pair en local y luego la llamamos
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  filename        = "jikkosoft-key.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}

resource "aws_key_pair" "deployer" {
  key_name   = "jikkosoft-key" 
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# --- Instancia EC2 en subred pública ---

resource "aws_instance" "public_instance" {
  ami           = "ami-0c02fb55956c7d316"  # Amazon Linux 2023 en us-east-1
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name
  vpc_security_group_ids = [aws_security_group.sg_public_ec2.id]
  subnet_id     = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y aws-cli
              > /tmp/sample-file.txt
              aws s3 cp /tmp/sample-file.txt s3://${aws_s3_bucket.s3_bucket.bucket}/other-sample-file.txt
              EOF
  tags = {
    Name = "Public-EC2-Bastion"
  }
}
#Copiar llave en instancia publica para conectarse a instancia privada
resource "null_resource" "copy_private_key_to_bastion" {
  depends_on = [
    aws_instance.public_instance
  ]
  connection {
    type        = "ssh"
    host        = aws_instance.public_instance.public_ip
    user        = "ec2-user"
    private_key = file("jikkosoft-key.pem")
  }
  provisioner "file" {
    source      = "jikkosoft-key.pem"
    destination = "/home/ec2-user/.ssh/jikkosoft-key"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ec2-user/.ssh/jikkosoft-key",
      "chown ec2-user:ec2-user /home/ec2-user/.ssh/jikkosoft-key"
    ]
  }
}

# --- Instancia EC2 en subred privada ---

resource "aws_instance" "private_instance" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.sg_private_ec2.id]
  subnet_id     = aws_subnet.private_subnet_1.id

  tags = {
    Name = "Private-EC2"
  }
}

# 2 IAM Roles & Policies:

# 2.1 Create an IAM user with programmatic access.

resource "aws_iam_user" "jikkosoft_user" {
  name = "jikkosoft-user" 
  path = "/system/"
}

resource "aws_iam_access_key" "jikkosoft_user" {
  user = aws_iam_user.jikkosoft_user.name
}

# 2.2 Create an IAM role for an EC2 instance with permissions to access Amazon S3.

resource "aws_iam_role" "ec2_s3_role" {
  name = "jikkosoft-ec2-s3-acces-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-access-profile"
  role = aws_iam_role.ec2_s3_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# 3. S3 & Object Lifecycle Management:
# 3.1 Create an S3 bucket.

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "jikkosoft-s3-bucket-${random_id.suffix.hex}"
  tags = {
    Name = "jikkosoft-s3-bucket"
  }
}
resource "random_id" "suffix" {
  byte_length = 4
}

# 3.3 Configure Object Lifecycle Management to automatically transition objects to infrequent access storage after 30 days.

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    id = "infrequent-access-storage-after-30-days"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    filter {
      prefix = ""
    }
    status = "Enabled"
  }
}

# 4. CloudWatch Alarms & Notifications.
# 4.1 Create a CloudWatch alarm to monitor CPU utilization of an EC2 instance.

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm" {
  alarm_name          = "EC2-CPU-Utilization-public_instance-Alarm"
  alarm_description   = "Alarma si la CPU supera el 80% durante 1 minuto"
  alarm_actions       = [
    aws_sns_topic.alarm_notifications.arn
    ]
  ok_actions          = []
  insufficient_data_actions = []
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions = {
    InstanceId = aws_instance.private_instance.id
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  period              = "300"
  threshold           = "80"
  statistic           = "Average"
  unit                = "Percent"

  tags = {
    Name = "CPU-Alarm"
  }
}

# 4.2 Configure the alarm to trigger an SNS notification to an email address.

resource "aws_sns_topic" "alarm_notifications" {
  name = "cpu-alarm-topic"
}
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = var.email
}
