def SERVICE_NAME="react"
def SERVICE_TAG = "latest"
def ECR_REPO_URL = "540322794711.dkr.ecr.us-east-1.amazonaws.com/${SERVICE_NAME}"

node {
    def app
    stage('Clone Repository') {
        git branch: "test", url: "https://github.com/srikanthbayyapu/Fargate-Terraform.git"
    }

    stage('Start Docker Services') {
        sh "sudo service docker start"
    }

    stage('Remove Unused Docker Images') {
        sh "docker image prune -a --force"
    } 

    stage('Docker Build') {
        sh "docker build -t 540322794711.dkr.ecr.us-east-1.amazonaws.com/react:latest ."
    }

    stage('Push Image to ECR') {
        docker.withRegistry('https://540322794711.dkr.ecr.us-east-1.amazonaws.com', 'ecr:us-east-1:react-ecr-role') {
            sh "docker push 540322794711.dkr.ecr.us-east-1.amazonaws.com/react:latest"
        }
    }

    stage('Creating Infrastructure') {
        sh "cd ./terraform/01-infrastructure && terraform init"
        sh "cd ./terraform/01-infrastructure && terraform apply -var-file='production.tfvars' -auto-approve"
    }     

    stage('Creating Platform') {
        sh "cd ./terraform/02-platform && terraform init"
        sh "cd ./terraform/02-platform && terraform apply -var-file='production.tfvars' -auto-approve"
    }

    stage('Creating ECS Service') {
        sh "cd ./terraform/03-application && terraform init"
        sh "cd ./terraform/03-application && terraform apply -var-file='production.tfvars' -var 'nginx_app_image=${ECR_REPO_URL}:${SERVICE_TAG}' -auto-approve"
    }
}
