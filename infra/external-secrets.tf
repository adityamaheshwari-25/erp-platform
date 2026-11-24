resource "aws_iam_role" "external_secrets" {
  name_prefix = "ExternalSecrets-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Condition = {
        StringEquals = {
          "aws:RequestTag/kubernetes-namespace"       = "external-secrets"
          "aws:RequestTag/kubernetes-service-account" = "external-secrets"
        }
      }
    }]
  })

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "ReadErpDatabaseSecret"
  role = aws_iam_role.external_secrets.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.erp_db.arn
    }]
  })
}

resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets.arn
}
