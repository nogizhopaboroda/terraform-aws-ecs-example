/* define task */

variable "is_deployment" {
  default = false
}

variable "image_tag" {
  default = "latest"
}


data "aws_ecs_task_definition" "app_td" {
  count = "${var.is_deployment == true ? 1 : 0}"
  task_definition = "${aws_ecs_task_definition.app_td.family}"
}

resource "aws_ecs_task_definition" "app_td" {
  count = "${var.is_deployment == true ? 1 : 0}"
  family                = "${var.app_name}-td"
  container_definitions = <<DEFINITION
[
  {
    "name": "web",
    "image": "${aws_ecr_repository.app_containers_repo.repository_url}:${var.image_tag}",
    "cpu": 128,
    "memoryReservation": 128,
    "portMappings": [
      {
        "containerPort": 8080,
        "protocol": "tcp"
      }
    ],
    "command": [
      "npm", "start"
    ],
    "essential": true
  }
]
DEFINITION
}


/* define service that runs task */

resource "aws_ecs_service" "app_service" {
  count = "${var.is_deployment == true ? 1 : 0}"
  name            = "${var.app_name}-ecs-service"
  iam_role        = "${aws_iam_role.app_ecs_service_role.name}"
  cluster         = "${aws_ecs_cluster.app_cluster.id}"
  task_definition = "${aws_ecs_task_definition.app_td.family}:${max("${aws_ecs_task_definition.app_td.revision}", "${data.aws_ecs_task_definition.app_td.revision}")}"
  desired_count   = 1

  depends_on = ["aws_alb.app_load_balancer", "aws_lb_target_group.app_lb_tg", "aws_iam_role.app_ecs_service_role", "aws_ecs_task_definition.app_td"]

  load_balancer {
    target_group_arn  = "${aws_lb_target_group.app_lb_tg.arn}"
    container_port    = 8080
    container_name    = "web"
  }
}
