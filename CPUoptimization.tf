

provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "optimization_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "optimization-vpc"
  }
}

resource "aws_internet_gateway" "optimization_igw" {
  vpc_id = aws_vpc.optimization_vpc.id
  tags = {
    Name = "optimization-igw"
  }
}

resource "aws_subnet" "optimization_subnet" {
  vpc_id                  = aws_vpc.optimization_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "optimization-subnet"
  }
}

resource "aws_route_table" "optimization_rt" {
  vpc_id = aws_vpc.optimization_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.optimization_igw.id
  }
  tags = {
    Name = "optimization-route-table"
  }
}

resource "aws_route_table_association" "optimization_rta" {
  subnet_id      = aws_subnet.optimization_subnet.id
  route_table_id = aws_route_table.optimization_rt.id
}

resource "aws_launch_template" "optimization_lt" {
  name_prefix   = "optimization-lt"
  image_id      = "ami-071226ecf16aa7d96" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t3.micro"
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "optimization-instance"
    }
  }
}


resource "aws_autoscaling_group" "optimization_asg" {
  name                = "optimization-asg"
  min_size            = 1
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.optimization_subnet.id]
  
  launch_template {
    id      = aws_launch_template.optimization_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "optimization-asg-instance"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "scale_down" {
  name                   = "optimization-scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.optimization_asg.name
}


resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "optimization-low-cpu-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 300
  statistic          = "Average"
  threshold          = 30
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.optimization_asg.name
  }
  alarm_description = "Triggers scale down when CPU < 30% for 10 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}

# 10. Compute Optimizer Enrollment
resource "aws_computeoptimizer_enrollment_status" "optimization" {
  status = "Active"
}

# Outputs
output "vpc_id" {
  value = aws_vpc.optimization_vpc.id
}

output "subnet_id" {
  value = aws_subnet.optimization_subnet.id
}

output "asg_name" {
  value = aws_autoscaling_group.optimization_asg.name
}
