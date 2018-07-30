resource "aws_iam_role" "app_ecs_service_role" {
    name                = "${var.app_name}-ecs-service-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.ecs-service-policy.json}"
}

resource "aws_iam_role_policy_attachment" "app_ecs_service_role_attachment" {
    role       = "${aws_iam_role.app_ecs_service_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ecs.amazonaws.com"]
        }
    }
}


resource "aws_iam_role" "app_ecs_instance_role" {
    name                = "${var.app_name}-ecs-instance-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.ecs-instance-policy.json}"
}

data "aws_iam_policy_document" "ecs-instance-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role_policy_attachment" "app_ecs_instance_role_attachment" {
    role       = "${aws_iam_role.app_ecs_instance_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "app_ecs_instance_profile" {
    name = "${var.app_name}-ecs-instance-profile"
    path = "/"
    role = "${aws_iam_role.app_ecs_instance_role.id}"
    provisioner "local-exec" {
      command = "sleep 10"
    }
}
