/* create cluster itself */

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-cluster"
}

resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "app-keypair"
  public_key = "${tls_private_key.app_key.public_key_openssh}"
}

/* define what kind of instance to launch */

resource "aws_launch_configuration" "app_lc" {
    name                        = "${var.app_name}-lc"
    image_id                    = "ami-6b81980b"
    instance_type               = "t2.micro"
    iam_instance_profile        = "${aws_iam_instance_profile.app_ecs_instance_profile.id}"
    key_name                    = "${aws_key_pair.generated_key.key_name}"
    security_groups             = ["${aws_security_group.app_cluster_sg.id}"]
    associate_public_ip_address = true
    user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=${aws_ecs_cluster.app_cluster.name} >> /etc/ecs/ecs.config
                                  echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
EOF
    enable_monitoring           = true
    ebs_optimized               = false

    ebs_block_device {
        device_name           = "/dev/xvdcz"
        volume_type           = "gp2"
        volume_size           = 22
        delete_on_termination = true
    }

}

/* define autoscaling rules (for ec2 instances, not app instances inside ec2) */

resource "aws_autoscaling_group" "app_cluster_asg" {
    name                      = "${var.app_name}-cluster-asg"
    desired_capacity          = 1
    health_check_grace_period = 0
    health_check_type         = "EC2"
    launch_configuration      = "${aws_launch_configuration.app_lc.name}"
    max_size                  = 1
    min_size                  = 0
    vpc_zone_identifier       = ["${aws_subnet.app_subnet_1a.id}", "${aws_subnet.app_subnet_1c.id}"]

    tag {
        key   = "Name"
        value = "${var.app_name} ECS Instance"
        propagate_at_launch = true
    }

}

data "aws_instance" "app_instance" {
  instance_tags = {
    "Name" = "${var.app_name} ECS Instance"
  }
}

