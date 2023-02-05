provider "aws" {
  region = "eu-central-1"
  access_key = " "
  secret_key = " "
}

#VPC BLOCK
resource "aws_vpc" "project_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "project_vpc"
  }
}

#Internet Gateway Block

resource "aws_internet_gateway" "project_internet_gateway" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "project_internet_gateway"
  }
}

#Public Route Table Block

resource "aws_route_table" "project-route-table-public" {
  vpc_id = aws_vpc.project_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_internet_gateway.id
  }
  tags = {
    Name = "project-route-table-public"
  }
}

#Linking Public Subnet-1 with Route Table

resource "aws_route_table_association" "project-public-subnet1-association" {
  subnet_id      = aws_subnet.project-public-subnet1.id
  route_table_id = aws_route_table.project-route-table-public.id
}
# Linking Public Subnet-2 With Route Table
resource "aws_route_table_association" "project-public-subnet2-association" {
  subnet_id      = aws_subnet.project-public-subnet2.id
  route_table_id = aws_route_table.project-route-table-public.id
}

#Publick Subnet 1 Block

resource "aws_subnet" "project-public-subnet1" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"
  tags = {
    Name = "project-public-subnet1"
  }
}
#Public Subnet 2 Block

resource "aws_subnet" "project-public-subnet2" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1b"
  tags = {
    Name = "project-public-subnet2"
  }
}

#Network

resource "aws_network_acl" "project-network_acl" {
  vpc_id     = aws_vpc.project_vpc.id
  subnet_ids = [aws_subnet.project-public-subnet1.id, aws_subnet.project-public-subnet2.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

#Load Balancer Security Group

resource "aws_security_group" "project-load_balancer_sg" {
  name        = "project-load-balancer-sg"
  description = "Load balancer security group"
  vpc_id      = aws_vpc.project_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#EC2 Security Group 

resource "aws_security_group" "project-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.project_vpc.id
 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.project-load_balancer_sg.id]
  }
 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.project-load_balancer_sg.id]
  }
  ingress {
    description = "SSH"
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
    Name = "project-ec2-security-grp-rule"
  }
}

#EC2 Instances

#instance 1

resource "aws_instance" "project1" {
  ami             = "ami-03e08697c325f02ab"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.project-security-grp-rule.id]
  subnet_id       = aws_subnet.project-public-subnet1.id
  availability_zone = "eu-central-1a"
  tags = {
    Name   = "project-1"
    source = "terraform"
  }
}

#instance 2
 resource "aws_instance" "project2" {
  ami             = "ami-03e08697c325f02ab"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.project-security-grp-rule.id]
  subnet_id       = aws_subnet.project-public-subnet2.id
  availability_zone = "eu-central-1b"
  tags = {
    Name   = "project-2"
    source = "terraform"
  }
}

#instance 3

resource "aws_instance" "project3" {
  ami             = "ami-03e08697c325f02ab"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.project-security-grp-rule.id]
  subnet_id       = aws_subnet.project-public-subnet2.id
  availability_zone = "eu-central-1b"
  tags = {
    Name   = "project-3"
    source = "terraform"
  }
}

#Outputing public IPs into a file 

resource "local_file" "Ip_address" {
  filename = "C:/Users/HP/Desktop/Altschool/First Altschool Assignment/Terraform/host-inventory"
  content  = <<EOT
${aws_instance.project1.public_ip}
${aws_instance.project2.public_ip}
${aws_instance.project3.public_ip}
  EOT
}

#LOAD BALANCER

resource "aws_lb" "project-load-balancer" {
  name               = "projet-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.project-load_balancer_sg.id]
  subnets            = [aws_subnet.project-public-subnet1.id, aws_subnet.project-public-subnet2.id]
  #enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.project1, aws_instance.project2, aws_instance.project3]
}

#Target Group Block

resource "aws_lb_target_group" "project-target-group" {
  name     = "project-target-group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

#Listener Rule

resource "aws_lb_listener" "project-listener" {
  load_balancer_arn = aws_lb.project-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project-target-group.arn
  }
}
# Create the listener rule

resource "aws_lb_listener_rule" "project-listener-rule" {
  listener_arn = aws_lb_listener.project-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project-target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# Linking Target Group With Load Balancer

resource "aws_lb_target_group_attachment" "project-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.project-target-group.arn
  target_id        = aws_instance.project1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "project-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.project-target-group.arn
  target_id        = aws_instance.project2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "project-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.project-target-group.arn
  target_id        = aws_instance.project3.id
  port             = 80 
  }

# Route 53 Block

