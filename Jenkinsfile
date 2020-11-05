def SERVICE_NAME="react"
def SERVICE_TAG = "latest"
def ECR_REPO_URL = "922079431449.dkr.ecr.us-east-1.amazonaws.com/${SERVICE_NAME}"

node {
    def app
    stage('Clone Repository') {
        git branch: "destroy", url: "https://github.com/Neikl/Fargate-Terraform.git"
    }

    stage('Start Docker Services') {
        sh "sudo service docker start"
    }

    stage('Remove Unused Docker Images') {
        sh "docker image prune -a --force"
    } 

    stage('Destroying ECS Service') {
        sh "cd ./terraform/03-application && terraform init"
        sh "cd ./terraform/03-application && terraform destroy -var-file='production.tfvars' -var 'nginx_app_image=${ECR_REPO_URL}:${SERVICE_TAG}' -auto-approve"
    }

    stage('Destroying Platform') {
        sh "cd ./terraform/02-platform && terraform init"
        sh "cd ./terraform/02-platform && terraform destroy -var-file='production.tfvars' -auto-approve"
    }

    stage('Destroying Infrastructure') {
        sh "cd ./terraform/01-infrastructure && terraform init"
        sh "cd ./terraform/01-infrastructure && terraform destroy -var-file='production.tfvars' -auto-approve"
    }
}
