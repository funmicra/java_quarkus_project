// Jenkins Pipeline to build, push Docker image and deploy Quarkus application on Kubernetes cluster
pipeline {
    agent any
    triggers {
        githubPush()
    }
    // Define environment variables
    environment {
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        REGISTRY_URL = "registry.black-crab.cc"
        IMAGE_NAME   = "demo-quarkus"
        FULL_IMAGE   = "${env.REGISTRY_URL}/${env.IMAGE_NAME}:latest"
    }
    
    // Define the stages of the pipeline
    stages {

        // Stage to checkout source code from GitHub
        stage('Checkout Source') {
            steps {
                git credentialsId: 'github-creds',
                    url: 'https://github.com/funmicra/java_quarkus_project.git',
                    branch: 'master'
            }
        }
        
        // Stage to build Docker image
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    docker build -t ${FULL_IMAGE} .
                    """
                }
            }
        }

        // Stage to authenticate to Nexus registry
        stage('Authenticate to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus_registry_login',
                    usernameVariable: 'REG_USER',
                    passwordVariable: 'REG_PASS'
                )]) {
                    sh '''
                    echo "$REG_PASS" | docker login ${REGISTRY_URL} -u "$REG_USER" --password-stdin
                    '''
                }
            }
        }

        // Stage to push Docker image to Nexus registry
        stage('Push to Nexus Registry') {
            steps {
                sh """
                docker push ${FULL_IMAGE}
                """
            }
        }

        // Stage to deploy application on Kubernetes cluster        
        stage('deploy on cluster') {
            steps {
                sh """
                if kubectl get namespace quarkus >/dev/null 2>&1; then
                    kubectl delete all --all -n quarkus
                    kubectl delete namespace quarkus
                else
                    echo "Namespace 'quarkus' not present — skipping delete."
                fi
                kubectl create namespace quarkus
                kubectl apply -f k8s/deployment.yaml -n quarkus
                kubectl apply -f k8s/service.yaml -n quarkus

                sleep 10
                """
            }
        }

        // Stage to verify deployment by sending HTTP requests
        stage('Verify Deployment') {
            steps {
                script {
                    retry(5){
                        def hosts = ['192.168.88.80', '192.168.88.81']
                        for (host in hosts) {
                            sh "curl http://${host}:30080/sample?param=test || exit 1"
                        }
                    }
                }
            }
        }
    }

    // Post actions to execute after pipeline completion
    post {
        success {
            echo "Deployment pipeline executed successfully."
        }
        failure {
            echo "Pipeline execution failed. Please review logs."
        }
    }
}  
