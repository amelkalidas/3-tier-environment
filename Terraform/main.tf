# main.tf
provider "aws" {
  region = var.region
}
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "DevEngine_Vpc01"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "DevEngine_IGW"
  }
}
#######################################################################################################
### Subnets 
#######################################################################################################

resource "aws_subnet" "web_public_1" {
  cidr_block        = var.public_subnet_cidrs_AZ1
  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zone_A
  map_public_ip_on_launch = true
  tags = {
    Name = "Web_Pub_A"
  }
}
resource "aws_subnet" "Web_public_2" {
    cidr_block        = var.public_subnet_cidrs_AZ3
    vpc_id            = aws_vpc.main.id
    availability_zone = var.availability_zone_C
    map_public_ip_on_launch = true
    tags = {
      Name = "Web_Pub_C"
    }
}

resource "aws_subnet" "App_Private_A" {
  
  cidr_block        = var.private_app_sub_cidrs_AZ1
  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zone_A
  tags = {
    Name = "App_Prvt_A"
  } 
}
resource "aws_subnet" "App_Private_C" {
    cidr_block        = var.private_app_sub_cidrs_AZ3
    vpc_id            = aws_vpc.main.id
    availability_zone = var.availability_zone_C
    tags = {
      Name = "App_Prvt_C"
    } 
}
resource "aws_subnet" "DB_Prvt_A" {
    cidr_block        = var.private_DB_sub_cidrs_AZ1
    vpc_id            = aws_vpc.main.id
    availability_zone = var.availability_zone_A
    tags = {
      Name = "DB_Prvt_A"
    } 
}
resource "aws_subnet" "DB_Prvt_C" {
    cidr_block        = var.private_DB_sub_cidrs_AZ3
    vpc_id            = aws_vpc.main.id
    availability_zone = var.availability_zone_C
    tags = {
      Name = "DB_Prvt_C"
    } 
}
resource "aws_eip" "nat1" {
  tags = {
    Name = "eip1"
  }  
}
resource "aws_eip" "nat2" {
  tags = {
    Name = "eip2"
  }    
}

resource "aws_nat_gateway" "gw1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.web_public_1.id
  tags = {
    Name = "NGW1"
  }  
}
resource "aws_nat_gateway" "gw2" {
    allocation_id = aws_eip.nat2.id
    subnet_id     = aws_subnet.Web_public_2.id
    tags = {
        Name = "NGW2"
      }
}
#######################################################################################################
# Route Table
#######################################################################################################

resource "aws_route_table" "publicWeb_RT" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "PublicRoute_devEngine"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private_APP_RT_1" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "PrvtApp_devEngine_1"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw1.id
  }
}

resource "aws_route_table" "private_APP_RT_2" {
    vpc_id = aws_vpc.main.id
    tags = {
    Name = "PrvtApp_devEngine_2"
  }
  
    route {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.gw2.id
    }
  }

resource "aws_route_table_association" "public_A" {
  
  subnet_id      = aws_subnet.web_public_1.id
  route_table_id = aws_route_table.publicWeb_RT.id
}
resource "aws_route_table_association" "public_C" {
    
    subnet_id      = aws_subnet.Web_public_2.id
    route_table_id = aws_route_table.publicWeb_RT.id
}

resource "aws_route_table_association" "private_App_1" {
  subnet_id      = aws_subnet.App_Private_A.id
  route_table_id = aws_route_table.private_APP_RT_1.id
}
resource "aws_route_table_association" "private_App_2" {
  subnet_id      = aws_subnet.App_Private_C.id
  route_table_id = aws_route_table.private_APP_RT_2.id
}

#######################################################################################################
# Security Groups
#######################################################################################################

resource "aws_security_group" "external_alb_sg" {
  name        = "External_ALB_SG"
  description = "External Application LB SG"
  vpc_id      = aws_vpc.main.id
  

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
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Web EC2 SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb_sg.id]
  }
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks  = ["${chomp(data.http.ipinfo.response_body)}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "internal_alb_sg" {
  name        = "internal_alb_sg"
  description = "Internal ALB SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "App EC2 SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb_sg.id]
  }
  ingress {
    from_port = 4000
    to_port = 4000
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.ipinfo.response_body)}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "DB SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#######################################################################################################
# EC2 Instances
#######################################################################################################

resource "aws_instance" "web_ec2" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.web_public_1.id

  vpc_security_group_ids = [
    aws_security_group.web_sg.id,
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  
  
  tags = {
    Name = "web_instance"
  }
}

resource "aws_instance" "app_ec2" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.App_Private_A.id
  
  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "app_instance"
  }
}
######################################################################################################
# DB 
#######################################################################################################

resource "aws_db_subnet_group" "auroradbsubnetgroup" {
  name       = "auroradbsubnetgroup"
  subnet_ids =  [aws_subnet.DB_Prvt_A.id,aws_subnet.DB_Prvt_C.id]

  tags = {
    Name = "auroradbsubnetgroup"
  }
}


resource "aws_rds_cluster" "WebDB" {
  cluster_identifier      = "aurora-db-1"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.04.0"
  availability_zones      = [var.availability_zone_A, var.availability_zone_C]
  database_name           = "admin"
  master_username         = "adminpassword123"
  master_password         = "adminpassword123"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.auroradbsubnetgroup.id
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  lifecycle {
    ignore_changes = [engine, master_username, master_password, engine_version, database_name,availability_zones]
  }
  
}
resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "aurora-db-1-${count.index}"
  cluster_identifier = aws_rds_cluster.WebDB.id
  instance_class     = "db.r5.xlarge"
  engine             = aws_rds_cluster.WebDB.engine
  engine_version     = aws_rds_cluster.WebDB.engine_version
  db_subnet_group_name = aws_db_subnet_group.auroradbsubnetgroup.id
  lifecycle {
    ignore_changes =  [identifier, engine, engine_version, cluster_identifier]
  }
}

# S3 Bucket creation. 

resource "aws_s3_bucket" "storage" {
  bucket = var.s3_bucket
  force_destroy = true

  tags = {
    Name        = "mys3for3tierapp15"
    Environment = "Dev"
  }
}


#######################  Load Balancer ###############################

resource "aws_lb_target_group" "privt_app" {
  name = "targetgroup-prvt-ec2"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id


  health_check {
    enabled = true
    interval = 30
    path = "/health"
    protocol = "HTTP"
    healthy_threshold = 3
    unhealthy_threshold = 3
  }  
}
resource "aws_lb" "internal_lb" {
  name               = "internallb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb_sg.id]
  subnets            = [aws_subnet.App_Private_A.id,aws_subnet.App_Private_C.id]
  tags = {
    Environment = "Internal"
  }
}
resource "aws_lb_target_group_attachment" "prvt_app_attach" {
  target_group_arn = aws_lb_target_group.privt_app.arn
  target_id        = aws_instance.app_ec2.id
  port             = 80
  
}
resource "aws_lb_listener" "back_end" {
  load_balancer_arn = aws_lb.internal_lb.arn
  port              = "4000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.privt_app.arn
  }
}


resource "aws_lb_target_group" "public_tg" {
  name = "tg-public-ec2"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id


  health_check {
    enabled = true
    interval = 30
    path = "/health"
    protocol = "HTTP"
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb" "external_lb" {
  name               = "external-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external_alb_sg.id]
  subnets            = [aws_subnet.web_public_1.id,aws_subnet.Web_public_2.id]
  tags = {
    Environment = "External"
  }
}
resource "aws_lb_target_group_attachment" "public_app_attach" {
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_instance.web_ec2.id
  port             = 80

}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.external_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg.arn
  }
}
#################################### New ###################################

resource "aws_launch_template" "Public_LT_ASG" {
  name = "web_tier_LT"
  image_id = var.image_id
  instance_type = var.ec2_instance_type  
}

resource "aws_launch_template" "PRVT_LT_ASG" {
  name = "App_tier_LT"
  image_id = var.image_id
  instance_type = var.ec2_instance_type  
}


################# auto scalling ###############################

resource "aws_autoscaling_group" "Web_ASG" {
  name                      = "web_tier_ASG"
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.public_tg.arn]
  launch_template {
    id = aws_launch_template.Public_LT_ASG.id
    version = "$Latest"
  }
  
  vpc_zone_identifier       = [aws_subnet.web_public_1.id,aws_subnet.Web_public_2.id]

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }
  

  
  tag {
    key                 = "Type"
    value               = "External"
    propagate_at_launch = true
  }

  
}

resource "aws_autoscaling_group" "APP_ASG" {
  name                      = "APP_tier_ASG"
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.privt_app.arn]
  launch_template {
    id = aws_launch_template.PRVT_LT_ASG.id
    version = "$Latest"
  }
  
  vpc_zone_identifier       = [aws_subnet.App_Private_A.id,aws_subnet.App_Private_C.id]

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }
  

  
  tag {
    key                 = "Type"
    value               = "INternal"
    propagate_at_launch = true
  }

  
}