output "alb_dns_name" {
  description = "Load Balancer DNS Name"
  value       = aws_lb.app_alb.dns_name
}
