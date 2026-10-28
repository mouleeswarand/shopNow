pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '625228299204.dkr.ecr.ap-south-1.amazonaws.com'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Verify tools') {
            steps {
                sh '''
                    git --version
                    docker --version
                    aws --version
                    aws sts get-caller-identity --region "$AWS_REGION"
                '''
            }
        }

        stage('Build images') {
            steps {
                sh '''
                    docker build \
                      --build-arg USER_NAME=mouli \
                      -t "$ECR_REGISTRY/mouli-shopnow/frontend:$IMAGE_TAG" \
                      ./frontend

                    docker build \
                      --build-arg USER_NAME=mouli \
                      -t "$ECR_REGISTRY/mouli-shopnow/admin:$IMAGE_TAG" \
                      ./admin

                    docker build \
                      -t "$ECR_REGISTRY/mouli-shopnow/backend:$IMAGE_TAG" \
                      ./backend
                '''
            }
        }

        stage('Push images to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region "$AWS_REGION" |
                      docker login --username AWS --password-stdin "$ECR_REGISTRY"

                    docker push "$ECR_REGISTRY/mouli-shopnow/frontend:$IMAGE_TAG"
                    docker push "$ECR_REGISTRY/mouli-shopnow/admin:$IMAGE_TAG"
                    docker push "$ECR_REGISTRY/mouli-shopnow/backend:$IMAGE_TAG"
                '''
            }
        }
    }
}
