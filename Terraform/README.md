

### Creating a KeyPair throgh aws-cli


```bash
aws ec2 create-key-pair \
  --key-name hello-you-bastion \
  --region eu-north-1 \
  --query 'asdasd' \
  --output text > ~/.ssh/pemfile

chmod 400 ~/.ssh/pemfile
```



#### References:
1. [ecs-terraform](https://github.com/alex/ecs-terraform/blob/master/main.tf)
2. [terraform-aws-ecs](https://github.com/anrim/terraform-aws-ecs/blob/master/main.tf)
3. [terraform-aws-modules/ecs/](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/3.1.0/examples/complete-ecs)