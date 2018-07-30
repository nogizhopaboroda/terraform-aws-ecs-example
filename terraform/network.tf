/* create VPC */

resource "aws_vpc" "app_main_vpc" {
    cidr_block           = "172.31.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags {
      Name = "${var.app_name} main VPC"
    }
}

data "aws_availability_zones" "available" {}

locals {
  network_count = "${length(data.aws_availability_zones.available.names)}"
}

/* create subnets in thids VPC */
resource "aws_subnet" "app_subnet" {
    count = "${local.network_count}"
    vpc_id                  = "${aws_vpc.app_main_vpc.id}"
    cidr_block              = "${cidrsubnet(aws_vpc.app_main_vpc.cidr_block, 8, count.index)}"
    availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = true

    tags {
      Name = "${var.app_name} subnet in zone: ${data.aws_availability_zones.available.names[count.index]}"
    }
}


/* create security groups for this VPC */

resource "aws_security_group" "app_load_balancer_sg" {
    name        = "${var.app_name}-elb-sg"
    description = "load balancer security group"
    vpc_id      = "${aws_vpc.app_main_vpc.id}"

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }


    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "app_cluster_sg" {
    name        = "${var.app_name}-ecs-sg"
    description = "cluster security group"
    vpc_id      = "${aws_vpc.app_main_vpc.id}"

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 1
        to_port         = 65535
        protocol        = "tcp"
        security_groups = ["${aws_security_group.app_load_balancer_sg.id}"]
        self            = false
    }


    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

}



/* create load balancer upon those subnets */

resource "aws_lb_target_group" "app_lb_tg" {
  name     = "${var.app_name}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.app_main_vpc.id}"
  target_type = "instance"
}

resource "aws_alb" "app_load_balancer" {
    name            = "${var.app_name}-elb"
    idle_timeout    = 60
    internal        = false
    security_groups = ["${aws_security_group.app_load_balancer_sg.id}"]
    subnets         = ["${aws_subnet.app_subnet.*.id}"]

    enable_deletion_protection = false

    tags {
    }
}

resource "aws_alb_listener" "app_lb_listener" {
    load_balancer_arn = "${aws_alb.app_load_balancer.arn}"
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_lb_target_group.app_lb_tg.arn}"
        type             = "forward"
    }
}




/* App internet gateways */

resource "aws_internet_gateway" "app_internet_gateway" {
    vpc_id = "${aws_vpc.app_main_vpc.id}"

    tags {
      Name = "${var.app_name} Internet Gateway"
    }
}

/* associate route table with gateway */

resource "aws_route_table" "app_route_table" {
    vpc_id     = "${aws_vpc.app_main_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.app_internet_gateway.id}"
    }

    tags {
      Name = "${var.app_name} Routing Table"
    }
}

resource "aws_route_table_association" "app_rta" {
  count = "${local.network_count}"
  subnet_id      = "${aws_subnet.app_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.app_route_table.id}"
}

