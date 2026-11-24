# Creates separate IAM roles for the Karpenter controller and the EC2 nodes it launches.
# The controller can provision instances and use iam:PassRole to pass the node role to EC2.
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  # Identifies the cluster for IAM policy scoping and the controller's Pod Identity association.
  # The module creates the association by default so the controller's service account can get temporary AWS credentials.
  cluster_name = module.eks.cluster_name

  # The controller policy exceeds the 6,144-character limit for a managed IAM policy.
  enable_inline_policy = true

  node_iam_role_additional_policies = {
    # Grants the node's SSM Agent permissions to register and use Systems Manager features such as Session Manager.
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Creates a standalone queue. The submodule creates its own interruption queue by default.
# EventBridge sends interruption notices to the submodule's queue, which the controller can read to drain nodes.
resource "aws_sqs_queue" "karpenter" {
  name = var.cluster_name
  # SQS expires messages that remain in the queue for five minutes.
  message_retention_seconds = 300
  # Encrypts queued messages at rest with SQS-managed keys (SSE-SQS).
  sqs_managed_sse_enabled = true
}
