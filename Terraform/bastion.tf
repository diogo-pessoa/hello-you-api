resource "aws_security_group" "bastion" {
  count       = var.enable_bastion ? 1 : 0
  name_prefix = "${var.app_name}-${var.environment}-bastion-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for bastion host"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-bastion-sg"
  }
}

resource "aws_instance" "bastion" {
  count                  = var.enable_bastion ? 1 : 0
  ami                    = data.aws_ami.amazon_linux[0].id
  instance_type          = "t3.micro"
  key_name              = var.bastion_key_name
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  subnet_id             = aws_subnet.public[0].id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y postgresql

              # Install Docker for debugging containers
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              EOF

  tags = {
    Name = "${var.app_name}-${var.environment}-bastion"
  }
}