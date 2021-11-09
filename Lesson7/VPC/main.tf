module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "terra-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-east-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.200.0/24", "10.0.201.0/24", "10.0.202.0/24"]

  tags = {
    Terraform = "true"
  }
}
