resource "aws_security_group_rule" "icmp_security_group_rule" {
  type              = "ingress"
  description       = "Allow all incoming ICMP - IPv4 traffic"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-123456-icmp"
}

resource "aws_security_group_rule" "tcp_security_group_rule" {
  type              = "ingress"
  description       = "Allow internal HTTP(S) and service communication"
  from_port         = 80
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-123456-tcp"
}

resource "aws_security_group_rule" "udp_security_group_rule" {
  type              = "ingress"
  description       = "Allow internal UDP traffic"
  from_port         = 80
  to_port           = 65535
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-123456-udp"
}

resource "aws_security_group_rule" "external_security_group_rule" {
  type              = "egress"
  description       = "Allow outbound traffic to the internet"
  from_port         = -1
  to_port           = -1
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-123456-egress"
}