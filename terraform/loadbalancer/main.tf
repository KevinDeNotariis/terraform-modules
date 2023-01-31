# ---------------------------------------------------------------
# 1. Define the Security Groups for the Load Balancer
# ---------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${local.identifier}-loadbalancer-${var.suffix}"
  description = "Allow inbound from the internet and outbound only to VPC"
  vpc_id      = var.vpc_id

  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "Allow Inbound Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Inbound Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow Outbound to VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 2. Define the Internet-Facing Load Balancer
# ---------------------------------------------------------------
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "this" {
  name                       = "${local.identifier}-${var.suffix}"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.public_subnets_ids
  drop_invalid_header_fields = true

  security_groups = [aws_security_group.this.id]

  enable_deletion_protection = contains(local.dev_environments, var.environment) ? false : true

  tags = local.tags
}

# ---------------------------------------------------------------
# 3. Define the target Groups
# ---------------------------------------------------------------
resource "aws_lb_target_group" "this" {
  name        = "${local.identifier}-${var.suffix}"
  vpc_id      = var.vpc_id
  port        = 80
  protocol    = "HTTP"
  target_type = var.lb_target_type

  health_check {
    protocol            = "HTTP"
    port                = 80
    path                = "/status/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10 # Seconds
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 4. Request TLS certificate
# ---------------------------------------------------------------
resource "aws_acm_certificate" "this" {
  domain_name       = local.lb_cname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 5. Create the Hosted Zone record for the Load Balancer
# ---------------------------------------------------------------
resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.id
  name    = local.lb_cname
  type    = "CNAME"
  records = [aws_lb.this.dns_name]
  ttl     = var.lb_cname_ttl
}

# ---------------------------------------------------------------
# 6.1 TLS Certificate Validation
# ---------------------------------------------------------------
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# ---------------------------------------------------------------
# 6.2 Validation of the certificate
# ---------------------------------------------------------------
resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.this.id
  ttl             = 60
}

# ---------------------------------------------------------------
# 7. Define the Listeners
# ---------------------------------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443

  protocol        = "HTTPS"
  certificate_arn = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }

  tags = local.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
