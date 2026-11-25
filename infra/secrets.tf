resource "aws_secretsmanager_secret" "erp_db" {
  name = "${var.cluster_name}/db-credentials"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "erp_db" {
  secret_id = aws_secretsmanager_secret.erp_db.id
  secret_string = jsonencode({
    host     = aws_db_instance.erp.address
    port     = aws_db_instance.erp.port
    username = var.db_username
    password = var.db_password
    dbname   = "erpdb"
  })
}
