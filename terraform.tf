
provider "aws" {
  region = "ap-south-1"
}



resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2-cluster-iam-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role" "eks_iam_role" {
  name = "eks-cluster-iam-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


#policy attachment

resource "aws_iam_role_policy_attachment" "ClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_iam_role.name
}

resource "aws_iam_role_policy_attachment" "ServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.eks_iam_role.name
}

resource "aws_iam_role_policy_attachment" "WorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.ec2_iam_role.name
}

resource "aws_iam_role_policy_attachment" "EKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.ec2_iam_role.name
}

resource "aws_iam_role_policy_attachment" "EC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.ec2_iam_role.name
}



#EKS cluster creation
resource "aws_eks_cluster" "eks_cluster" {
  name = "ekscluster"
  role_arn = aws_iam_role.eks_iam_role.arn
  
  vpc_config {
    subnet_ids = ["subnet-45acc854", "subnet-4ba59e89", "subnet-cda915a1"]
}
  tags = {
    Name = "EKS_Cluster"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ClusterPolicy,
    aws_iam_role_policy_attachment.ServicePolicy,
  ]
}

resource "aws_eks_node_group" "Node1" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node1"
  node_role_arn = aws_iam_role.ec2_iam_role.arn
  subnet_ids = ["subnet-45acc854", "subnet-4ba59e89", "subnet-cda915a1"]
  instance_types = ["t2.micro"]  
  disk_size = 40  
  remote_access {
    ec2_ssh_key = "mykey"
    source_security_group_ids = ["sg-0ac23d08cc87v2w78"]
  }

  scaling_config {
    desired_size = 1
    max_size = 1
    min_size = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNodePolicy,
    aws_iam_role_policy_attachment.EKS_CNI_Policy,
    aws_iam_role_policy_attachment.EC2ContainerRegistryReadOnly
  ]
}

resource "aws_eks_node_group" "Node2" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node2"
  node_role_arn = aws_iam_role.ec2_iam_role.arn
  subnet_ids =  ["subnet-45acc854", "subnet-4ba59e89", "subnet-cda915a1"]
  instance_types = ["t2.micro"]
  disk_size = 40  
  remote_access {
    ec2_ssh_key = "mykey"
    source_security_group_ids = ["sg-0ac23d08cc87v2w78"] 
  }
  scaling_config {
    desired_size = 1
    max_size = 1
    min_size = 1
  }

   depends_on = [
    aws_iam_role_policy_attachment.WorkerNodePolicy,
    aws_iam_role_policy_attachment.EKS_CNI_Policy,
    aws_iam_role_policy_attachment.EC2ContainerRegistryReadOnly
  ]
}

resource "aws_eks_node_group" "Node3" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node3"
  node_role_arn = aws_iam_role.ec2_iam_role.arn
  subnet_ids = ["subnet-45acc854", "subnet-4ba59e89", "subnet-cda915a1"]
  instance_types = ["t2.micro"]
  disk_size = 40  
  remote_access { 
    ec2_ssh_key = "mykey"
    source_security_group_ids = ["sg-0ac23d08cc87v2w78"]
  }
  scaling_config {
    desired_size = 1
    max_size = 1
    min_size = 1
  }

   depends_on = [
    aws_iam_role_policy_attachment.WorkerNodePolicy,
    aws_iam_role_policy_attachment.EKS_CNI_Policy,
    aws_iam_role_policy_attachment.EC2ContainerRegistryReadOnly
  ]
}

resource "aws_efs_file_system" "efs" {
  creation_token = "efs-token"

  tags = {
    Use = "EKS"
  }
}

resource "aws_efs_mount_target" "subnet1" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = "subnet-45acc854"
  security_groups = ["sg-0ac23d08cc87v2w78"]
  
}

resource "aws_efs_mount_target" "subnet2" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = "subnet-4ba59e89"
  security_groups =  ["sg-0ac23d08cc87v2w78"]
  
}

resource "aws_efs_mount_target" "subnet3" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = "subnet-cda915a1"
  security_groups =  ["sg-0ac23d08cc87v2w78"]
  
}

resource "aws_efs_access_point" "efs_ap" {
  file_system_id = aws_efs_file_system.efs.id
}
