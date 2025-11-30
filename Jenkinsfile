pipeline {
    agent any
    triggers {
        githubPush()
    }
    
    environment {
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        REGISTRY_URL = "registry.black-crab.cc"
        IMAGE_NAME   = "demo-quarkus"
        FULL_IMAGE   = "${env.REGISTRY_URL}/${env.IMAGE_NAME}:latest"
    }

    stages {

        stage('Checkout Source') {
            steps {
                git credentialsId: 'github-creds',
                    url: 'https://github.com/funmicra/java_quarkus_project.git',
                    branch: 'master'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    docker build -t ${FULL_IMAGE} .
                    """
                }
            }
        }

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

        stage('Push to Nexus Registry') {
            steps {
                sh """
                docker push ${FULL_IMAGE}
                """
            }
        }
        
        stage('deploy on cluster') {
            steps {
                sh """
                kubectl delete namespace quarkus || true
                kubectl create namespace quarkus
                kubectl apply -f k8s/deployment.yaml -n quarkus
                kubectl apply -f k8s/service.yaml -n quarkus
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    retry(5){
                        def hosts = ['192.168.88.80', '192.168.88.81']
                        for (host in hosts) {
                            sh "curl http://${host}:8080/sample?param=test"
                        }
                    }
                }
            }

        }
        
    post {
        success {
            echo "Deployment pipeline executed successfully."
        }
        failure {
            echo "Pipeline execution failed. Please review logs."
        }
    }
    }
}  
