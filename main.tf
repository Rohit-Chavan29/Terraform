provider "aws" {
    region = "ap-south-1"
}
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my_vpc"
  }
}
resource "aws_subnet" "subnet1a-public" {
    vpc_id     = aws_vpc.vpc.id
     cidr_block = "10.0.1.0/24"
     availability_zone = "ap-south-1a"
     map_public_ip_on_launch=true
    tags = {
        Name = "subnet-1a-public"
        }
}
resource "aws_subnet" "subnet1a-private" {
    vpc_id     = aws_vpc.vpc.id
     cidr_block = "10.0.2.0/24"
     availability_zone = "ap-south-1a"
    tags = {
        Name = "subnet-1a-private"
        }
}
resource "aws_subnet" "subnet1b-public" {
    vpc_id     = aws_vpc.vpc.id
     cidr_block = "10.0.3.0/24"
     availability_zone = "ap-south-1b"
     map_public_ip_on_launch=true
    tags = {
        Name = "subnet-1b-public"
        }
}
resource "aws_subnet" "subnet1b-private" {
    vpc_id     = aws_vpc.vpc.id
     cidr_block = "10.0.4.0/24"
     availability_zone = "ap-south-1b"
    tags = {
        Name = "subnet-1b-private"
        }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "my-gateway"
  }
}
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "subnet-public-routetable"
  }
}
resource "aws_route_table_association" "association1" {
  subnet_id      = aws_subnet.subnet1a-public.id
  route_table_id = aws_route_table.route_table.id
}
resource "aws_route_table_association" "association2" {
  subnet_id      = aws_subnet.subnet1b-public.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table" "private_route_table_1a" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway1a.id
  }

  tags = {
    Name = "private-route-table-1a"
  }
}
resource "aws_route_table_association" "private_association1a" {
  subnet_id      = aws_subnet.subnet1a-private.id
  route_table_id = aws_route_table.private_route_table_1a.id
}
resource "aws_route_table" "private_route_table_1b" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway1b.id
  }

  tags = {
    Name = "private-route-table-1b"
  }
}
resource "aws_route_table_association" "private_association1b" {
  subnet_id      = aws_subnet.subnet1b-private.id
  route_table_id = aws_route_table.private_route_table_1b.id
}
resource "aws_eip" "eip1" {

}
resource "aws_eip" "eip2" {

}
resource "aws_nat_gateway" "nat_gateway1a" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.subnet1a-public.id

  tags = {
    Name = "NAT1"
  }

  depends_on = [aws_internet_gateway.gw]
}
resource "aws_nat_gateway" "nat_gateway1b" {
  allocation_id = aws_eip.eip2.id
  subnet_id     = aws_subnet.subnet1b-public.id

  tags = {
    Name = "NAT2"
  }

  depends_on = [aws_internet_gateway.gw]
}
resource "aws_security_group" "sg" {
  
  vpc_id = aws_vpc.vpc.id

   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_launch_template" "launch_template" {
  name = "launch_template"
  image_id = "ami-04a37924ffe27da53"

  instance_type = "t2.micro"
  key_name = "amazon_login"

  network_interfaces {
    associate_public_ip_address = false
    security_groups= [aws_security_group.sg.id]
  }
  user_data =  base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
     INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    if [[ "$INSTANCE_ID" =~ "i-1" ]]; then
      echo "<html><body><h1>This is server 1</h1></body></html>" > /home/ec2-user/index.html
    else
      echo "<html><body><h1>This is server 2</h1></body></html>" > /home/ec2-user/index.html
    fi
     cd /home/ec2-user
    nohup python3 -m http.server 8000 &
    # Create the HTML file with content
    # echo "Hello from Python Server" > /home/ec2-user/index.html

    # # Start Python HTTP server on port 8000 in the background
    # cd /home/ec2-user
    # nohup python3 -m http.server 8000 &
  EOF
  )
}
resource "aws_autoscaling_group" "asg" {
  capacity_rebalance  = true
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.subnet1a-private.id, aws_subnet.subnet1b-private.id]
   
}
resource "aws_lb" "alb" {
  name               = "application-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.subnet1a-public.id ,aws_subnet.subnet1b-public.id]

}    
resource "aws_lb_target_group" "alb-target_group" {
  name        = "alb-tg"
  target_type = "instance"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn    = aws_lb_target_group.alb-target_group.arn
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target_group.arn
  }
}
