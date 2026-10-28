pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timeout(time: 45, unit: 'MINUTES')
    }

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '625228299204.dkr.ecr.ap-south-1.amazonaws.com'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }

    stages {
        stage('Verify tools and identity') {
            steps {
                sh '''
                    git --version
                    docker --version
                    aws --version
                    kubectl version --client
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

        stage('Check backend syntax') {
            steps {
                sh '''
                    docker run --rm \
                      "$ECR_REGISTRY/mouli-shopnow/backend:$IMAGE_TAG" \
                      node --check server.js
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

        stage('Deploy to EKS') {
            steps {
                sh '''
                    kubectl apply -f kubernetes/namespace.yaml
                    kubectl apply -f kubernetes/storageclass.yaml

                    # The existing mongodb-credentials Secret must already
                    # be present in the shopnow namespace.
                    kubectl get secret mongodb-credentials -n shopnow -o name

                    kubectl apply -f kubernetes/mongodb.yaml
                    kubectl rollout status deployment/mongodb -n shopnow --timeout=300s

                    sed "s|/backend:build-6|/backend:$IMAGE_TAG|g" \
                      kubernetes/backend.yaml | kubectl apply -f -

                    sed -e "s|/frontend:build-6|/frontend:$IMAGE_TAG|g" \
                        -e "s|/admin:build-6|/admin:$IMAGE_TAG|g" \
                      kubernetes/web.yaml | kubectl apply -f -

                    kubectl apply -f kubernetes/hpa.yaml
		    kubectl apply -f kubernetes/ingress.yaml

                    kubectl rollout status deployment/backend -n shopnow --timeout=300s
                    kubectl rollout status deployment/frontend -n shopnow --timeout=300s
                    kubectl rollout status deployment/admin -n shopnow --timeout=300s
                '''
            }
        }

        stage('Post-deployment checks') {
            steps {
                sh '''
                    kubectl get pods,svc,hpa -n shopnow
   		    bash scripts/smoke-test.sh	
                '''
            }
       	  }
	}

	post {
           failure {
            emailext(
                subject: "FAILED: ShopNow deployment - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """The ShopNow pipeline failed.

		Job: ${env.JOB_NAME}
		Build number: ${env.BUILD_NUMBER}
		Build URL: ${env.BUILD_URL}

		Open the Jenkins console output to find the failed stage and error.
		""",
                to: '$DEFAULT_RECIPIENTS'
            )
         }
      
     }
}
