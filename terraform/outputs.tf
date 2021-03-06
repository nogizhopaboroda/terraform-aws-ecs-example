output "cluster_id" {
  value = "${aws_ecs_cluster.app_cluster.id}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.app_cluster.name}"
}

output "load_balancer_dns" {
  value = "${aws_alb.app_load_balancer.dns_name}"
}


output "app_name" {
  value = "${var.app_name}"
}

output "repository_url" {
  value = "${aws_ecr_repository.app_containers_repo.repository_url}"
}


output "workspace" {
  value = "${terraform.workspace}"
}

output "instance_dns" {
  value = "${data.aws_instance.app_instance.public_dns}"
}

output "instance_ssh_key_pem" {
  sensitive = true
  value = "${tls_private_key.app_key.private_key_pem}"
}
