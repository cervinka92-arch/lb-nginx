output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "HTTP URL for the nginx application"
  value       = "http://${aws_lb.main.dns_name}"
}
