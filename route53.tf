# Route 53 Block

variable "domain_name" {
  default    = "netizensworld.me"
  type        = string
  description = "Domain name"
}

# Getting the Hosted Zone Details Block
resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
  tags = {
    Environment = "dev"
  }
}
# Createing A Record Set In Route53
# terraform aws route 53 record
resource "aws_route53_record" "site_domain" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "terraform-test.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.project-load-balancer.dns_name
    zone_id                = aws_lb.project-load-balancer.zone_id
    evaluate_target_health = true
  }
}