output "vpc_id" {
  description = "Trend VPC ID"
  value       = aws_vpc.trend_vpc.id
}

output "public_subnet_id" {
  description = "Trend public subnet ID"
  value       = aws_subnet.trend_public_subnet.id
}

output "jenkins_instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Jenkins public IP"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "Jenkins public DNS"
  value       = aws_instance.jenkins.public_dns
}
