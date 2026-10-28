# IAM role assumed by the Ansible target EC2 instance.
resource "aws_iam_role" "ansible_target" {
  name = "shopnow-dev-ansible-target-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Allows the target to register with AWS Systems Manager.
resource "aws_iam_role_policy_attachment" "ansible_target_ssm" {
  role       = aws_iam_role.ansible_target.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Makes the IAM role available to the EC2 instance.
resource "aws_iam_instance_profile" "ansible_target" {
  name = "shopnow-dev-ansible-target-profile"
  role = aws_iam_role.ansible_target.name
}

# No inbound rules: Jenkins will connect through Systems Manager.
resource "aws_security_group" "ansible_target" {
  name        = "shopnow-dev-ansible-target-sg"
  description = "Outbound access for the ShopNow Ansible target"
  vpc_id      = aws_vpc.shopnow.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "shopnow-dev-ansible-target-sg"
  }
}

resource "aws_instance" "ansible_target" {
  ami                         = "ami-0fc5120b2d80d4749"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ansible_target.id]
  iam_instance_profile        = aws_iam_instance_profile.ansible_target.name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "shopnow-dev-ansible-target"
    Role = "ansible-target"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ansible_target_ssm
  ]
}

output "ansible_target_instance_id" {
  description = "Instance ID of the Ansible-managed EC2 target"
  value       = aws_instance.ansible_target.id
}