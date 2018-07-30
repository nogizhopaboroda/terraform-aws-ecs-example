# terraform-aws-ecs-example
example of forming infrastructure on aws ecs using terraform

# init terraform

```sh
cd terraform
terraform init
```

# steps

- provision aws

```sh
terraform apply
```

- make sure it works and load balancer is open to the world on port 80

```sh
curl -I `terraform output load_balancer_dns`
```

*this will return 503 error (because we didn't deploy the app yet), but it means infrastructure is ready*

- configure and authorize aws cli

```sh
aws configure
```

**previous 3 operations should be done just once for one environment**

- build container

```sh
cd ../
sh build.sh [image tag, default is latest commit short hash]
```

*additional tag `latest` applies automatically*


- deploy container

```sh
sh deploy.sh [image tag, default is 'latest']
```

- go to aws console -> Elastic Container Service -> clusters -> my_cool_app_cluster -> my-cool-app-ecs-service -> events

- wait until service has reached a steady state

- curl it again to make sure it works

```sh
cd terraform
curl -I `terraform output load_balancer_dns`
```

# working with multiple accounts (staging, prod, qa, etc)

- create terraform workspace

```sh
cd terraform
terraform workspace new staging
```

- repeat from the beginning
