# Looks up Availability Zones in the AWS provider's configured region and names the result available.
data "aws_availability_zones" "available" {
  # Starts a filter that limits which Availability Zones AWS returns.
  filter {
    # Filters on the AWS field that indicates whether the account must opt in.
    name = "opt-in-status"
    # Keeps only zones that AWS makes available without account opt-in.
    values = ["opt-in-not-required"]
    # Ends the Availability Zone filter.
  }
  # Ends the Availability Zone data source.
}

# Calls the reusable module that creates the VPC and its networking resources.
module "vpc" {
  # Loads the AWS VPC module from the Terraform Registry.
  source = "terraform-aws-modules/vpc/aws"
  # Allows module versions from 6.0 up to, but excluding, 7.0.
  version = "~> 6.0"

  # Names the VPC by adding -vpc to the EKS cluster name.
  name = "${var.cluster_name}-vpc"
  # Sets the VPC's overall IPv4 address range to 10.0.0.0/16.
  cidr = "10.0.0.0/16"

  # Selects the first two Availability Zone names returned by the data source.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  # Assigns one /24 IPv4 range to a private subnet in each selected zone.
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  # Assigns one /24 IPv4 range to a public subnet in each selected zone.
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  # Assigns one /24 IPv4 range to a database subnet in each selected zone.
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

  # Enables a NAT gateway so resources in private subnets can initiate outbound internet connections.
  enable_nat_gateway = true

  # single_nat_gateway = true keeps costs low by routing all private traffic through one NAT gateway instead of one per AZ.
  # Shares one NAT gateway in the first public subnet for outbound internet traffic from both private subnets.
  single_nat_gateway = true
  # Enables the VPC setting that allows AWS to assign DNS hostnames to instances.
  enable_dns_hostnames = true

  # Creates an RDS DB subnet group from the database subnets.
  create_database_subnet_group = true

  # Defines the extra tags to apply to the public subnets.
  public_subnet_tags = {
    # Marks these subnets as eligible for internet-facing Kubernetes load balancers.
    "kubernetes.io/role/elb" = 1
    # Ends the public subnet tag map.
  }

  # Defines the extra tags to apply to the private subnets.
  private_subnet_tags = {
    # Marks these subnets as eligible for internal Kubernetes load balancers.
    "kubernetes.io/role/internal-elb" = 1
    # Tags these subnets with the cluster name so Karpenter can select them using a matching subnet selector.
    "karpenter.sh/discovery" = var.cluster_name
    # Ends the private subnet tag map.
  }

  # Defines common tags for resources created by the module.
  tags = {
    # Sets the Environment tag to the configured environment, such as dev.
    Environment = var.environment
    # Sets the Terraform tag to the string "true" to identify Terraform-managed resources.
    Terraform = "true"
    # Ends the common tag map.
  }
  # Ends the VPC module configuration.
}