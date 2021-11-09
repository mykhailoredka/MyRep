locals {
  name   = "myaws"
  region = "us-east-2"
  user_data = <<-EOT
  #!/bin/bash
  yum update -y
  yum install httpd php php-mysql -y
  cd /var/www/html
  echo "healthy" > healthy.html
  wget https://wordpress.org/wordpress-5.8.1.tar.gz
  amazon-linux-extras install -y php7.4
  tar -xzf wordpress-5.8.1.tar.gz
  cp -r wordpress/* /var/www/html/
  rm -rf wordpress
  rm -rf wordpress-5.8.1.tar.gz
  chmod -R 755 wp-content
  chown -R apache:apache wp-content
  chkconfig httpd on
  service httpd start
  EOT
  tags = {
    Owner       = "user"
    Environment = "test"
  }
}

#######################################VPC Module#########################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2"

  name = local.name
  cidr = "10.0.0.0/16"

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]


  create_database_subnet_group = true

  tags = local.tags
}

#######################################Security Group Module#########################################

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = local.name
  description = "Complete MySQL security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP Security Group"
  }
}
#######################################RDS Module#########################################

module "db" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = local.name

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0.20"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t2.micro"

  allocated_storage     = 10
  max_allocated_storage = 100
  storage_encrypted     = false

  name     = "db_test"
  username = "admin123"
  password = "testtest123"
  port     = 3306

  multi_az               = true
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.security_group.security_group_id]
}

#######################################Autoscaling Module#########################################

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  name = "autoscaling"

  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = module.vpc.public_subnets

  description = "A security group"
  # vpc_id      = module.vpc.vpc_id
  security_groups = [ aws_security_group.allow_http.id ]
  user_data = local.user_data

 

  lt_name                = "lt_asg"
  update_default_version = true

  use_lt    = true
  create_lt = true

  image_id          = "ami-0f19d220602031aed"
  instance_type     = "t2.micro"
  ebs_optimized     = true
  enable_monitoring = true
  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }

  placement = {
    availability_zone = local.region
  }
  

}