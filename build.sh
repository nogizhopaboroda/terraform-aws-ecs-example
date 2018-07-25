APP_NAME=$(cd terraform ; terraform output app_name)
REPO_URL=$(cd terraform ; terraform output repository_url)
TAG=${1:-$(git rev-parse --short HEAD)}
PROFILE=$(cd terraform ; terraform workspace show)

docker build -t $APP_NAME -t $APP_NAME:$TAG .

docker tag $APP_NAME:$TAG $REPO_URL:$TAG

docker tag $APP_NAME:latest $REPO_URL:latest

docker_login=$(aws --profile $PROFILE ecr get-login --no-include-email)
eval $docker_login

docker push $REPO_URL
