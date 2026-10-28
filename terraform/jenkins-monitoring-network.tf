# Private connection between the ShopNow EKS VPC and Jenkins VPC.
resource "aws_vpc_peering_connection" "jenkins_monitoring" {
  vpc_id      = aws_vpc.shopnow.id
  peer_vpc_id = "vpc-06c1389ff2c5ac57a"
  auto_accept = true

  tags = {
    Name = "shopnow-dev-to-jenkins"
  }
}

# Route replies from the Jenkins VPC back to the EKS VPC.
resource "aws_route" "jenkins_to_shopnow" {
  route_table_id            = "rtb-006c4f60fe575b87b"
  destination_cidr_block    = aws_vpc.shopnow.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.jenkins_monitoring.id
}

# Allow the EKS VPC to reach only the metrics proxy port.
resource "aws_vpc_security_group_ingress_rule" "jenkins_metrics" {
  security_group_id = "sg-0e488daa51ed1a5f8"
  description       = "ShopNow EKS access to Jenkins metrics proxy"
  cidr_ipv4         = aws_vpc.shopnow.cidr_block
  from_port         = 9105
  to_port           = 9105
  ip_protocol       = "tcp"
}