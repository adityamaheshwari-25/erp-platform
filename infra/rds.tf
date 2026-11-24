resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-"
  vpc_id      = module.vpc.vpc_id

  # Allows PostgreSQL traffic on TCP 5432 from network interfaces associated with the EKS node security group.
  # The security group reference continues to work as worker nodes and their IP addresses change.
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  # Allows outbound IPv4 traffic wherever routing permits it. Security groups are stateful and
  # automatically allow return traffic for permitted connections.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-rds"
    Environment = var.environment
  }
}

resource "aws_db_instance" "erp" {
  identifier = "${var.cluster_name}-db"

  engine = "postgres"
  # Selects PostgreSQL major version 16 and lets RDS choose the initial minor version.
  engine_version = "16"
  # Uses a burstable T3 database instance class that spends CPU credits above its baseline.
  instance_class = "db.t3.micro"

  # Allocates 20 GiB of general-purpose SSD storage. At this size, gp3 has a baseline of
  # 3,000 IOPS and 125 MiB/s of storage throughput.
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "erpdb"
  username = var.db_username
  # The sensitive variable masks the password in normal Terraform output. Terraform state still stores it.
  password = var.db_password

  # Gives RDS private subnet placement options in two Availability Zones. The instance defaults to
  # Single-AZ. Setting multi_az would add a standby in another Availability Zone for failover.
  db_subnet_group_name = module.vpc.database_subnet_group_name
  # Attaches the security group that controls which clients can reach the database port.
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Skips the final snapshot at deletion. For a new instance with backup_retention_period unset,
  # the AWS provider sends zero days of retention, which disables automated backups.
  skip_final_snapshot = true

  # publicly_accessible = false ensures the database is only reachable from within the VPC. Combined with database subnets, this is defense in depth.
  # The endpoint uses a private IP. Clients need a route to it and permission from the security group.
  publicly_accessible = false

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}