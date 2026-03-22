provider "aws" {
  region = var.region
}

# -------------------
# Default VPC + Subnet
# -------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "az_a" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.region}a"
}

# -------------------
# AMI
# -------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

# -------------------
# Security Groups
# -------------------

# FE SG
resource "aws_security_group" "fe_sg" {
  name   = "fe-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
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
}

# App SG
resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = data.aws_vpc.default.id

  # Allow VPC CIDR for NLB Health Checks & Inter-node communication
  ingress {
    from_port   = 8081
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------
# EC2 Instances
# -------------------

# App2
resource "aws_instance" "app2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id = data.aws_subnet.az_a.id

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data              = file("userdata/app2.sh")

  tags = { Name = "app2" }
}

# App1
resource "aws_instance" "app1" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id = data.aws_subnet.az_a.id

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data = templatefile("userdata/app1.sh", {
    app2_ip = aws_instance.app2.private_ip
  })

  tags = { Name = "app1" }
}

# FE
resource "aws_instance" "fe" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id = data.aws_subnet.az_a.id

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.fe_sg.id]

  user_data = templatefile("userdata/fe.sh", {
    nlb_dns = aws_lb.internal_nlb.dns_name
  })

  # Explicit dependency (Optional but good practice to prevent race conditions)
  depends_on = [aws_lb.internal_nlb]

  tags = { Name = "fe" }
}

# -------------------
# Elastic IP (FE)
# -------------------
resource "aws_eip" "fe_eip" {
  instance = aws_instance.fe.id
}

# -------------------
# Internal NLB
# -------------------
resource "aws_lb" "internal_nlb" {
  name               = "poc-nlb"   # ✅ FIXED
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-8081"
  port     = 8081
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id

  # Explicit Health Check (Best Practice)
  health_check {
    protocol            = "TCP"
    port                = "8081"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }
}

resource "aws_lb_target_group_attachment" "app1_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.app1.id
  port             = 8081
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 8081
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# -------------------
# Route53
# -------------------
resource "aws_route53_record" "dns" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.fe_eip.public_ip]
}