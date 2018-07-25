set -e

TAG=${1:-latest}

cd terraform

terraform apply -var "is_deployment=true" -var "image_tag=${TAG}" -target=aws_ecs_task_definition.app_td -target=aws_ecs_service.app_service -auto-approve

cd -
