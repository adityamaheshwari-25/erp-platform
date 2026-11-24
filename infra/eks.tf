module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name = var.cluster_name
  # Sets the Kubernetes control plane version. Check add-on and node version compatibility when upgrading.
  kubernetes_version = "1.35"

  vpc_id = module.vpc.vpc_id
  # Uses private subnets across two Availability Zones for worker nodes and EKS control plane network interfaces.
  subnet_ids = module.vpc.private_subnets

  # Enables the public Kubernetes API endpoint. The module also enables the private endpoint by default.
  # The public endpoint allows all IPv4 source addresses by default. Clients still need cluster permissions.
  endpoint_public_access = true

  # Creates an EKS access entry that grants the Terraform caller cluster-wide Kubernetes admin permissions.
  enable_cluster_creator_admin_permissions = true

  addons = {
    # Resolves Kubernetes Service names and other DNS queries for Pods.
    coredns = {}
    # Lets Pods obtain temporary AWS credentials through an IAM role associated with their Kubernetes service account.
    eks-pod-identity-agent = {
      # Allows early add-on creation. The agent runs on eligible worker nodes after they join.
      before_compute = true
    }
    # Programs node networking rules that route Kubernetes Service traffic to backend Pods.
    kube-proxy = {}
    # Sets up Pod networking and assigns Pods IP addresses from the VPC subnets.
    vpc-cni = {
      # Allows the CNI add-on to start provisioning while the module delays worker creation.
      before_compute = true
    }
  }

  # EKS manages worker provisioning and rolling updates through an EC2 Auto Scaling group.
  eks_managed_node_groups = {
    system = {
      # Selects the EKS-optimized Amazon Linux 2023 image for x86-64 workers.
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.system_node_instance_type]
      # Sets the lower and upper bounds for the node group's Auto Scaling group.
      min_size = 2
      max_size = 3
      # Starts with two nodes. The module ignores later desired-size changes so an autoscaler can adjust capacity.
      desired_size = 2

      labels = {
        # Lets workloads target these nodes with a matching nodeSelector or node affinity rule.
        role = "system"
      }
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    # Tags the module-created node security group so Karpenter can find it with a matching EC2NodeClass selector.
    "karpenter.sh/discovery" = var.cluster_name
  }
}
