
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "flask-sample:latest"
        VMS_INVENTORY = "hosts.ini" // Ansible inventory file listing your VMs
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Cloning Flask app repository..."
                git branch: 'main', url: 'https://github.com/funmicra/quarkus.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                script {
                    docker.build(DOCKER_IMAGE)
                }
            }
        }

        stage('Push to Registry (Optional)') {
            steps {
                sh "docker login <registry_url> -u <user> -p <password>"
                sh "docker tag $DOCKER_IMAGE <registry_url>/$DOCKER_IMAGE"
                sh "docker push <registry_url>/$DOCKER_IMAGE"
            }
        }

        stage('Deploy to VMs') {
            steps {
                echo "Deploying Flask container via Ansible..."
                ansiblePlaybook credentialsId: 'ssh-key-id',
                                playbook: 'deploy-flask.yml',
                                inventory: VMS_INVENTORY
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "Verifying Flask deployment..."
                sh 'curl http://<vm_ip>:5000/sample?param=test'
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
