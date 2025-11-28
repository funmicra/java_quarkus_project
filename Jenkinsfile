pipeline {
    agent any

    environment {
        HEIMDALL_VOLUME = "heimdall_data"
        HEIMDALL_CONTAINER = "heimdall"
    }

    stages {
        stage('Register Hosts in Known Hosts') {
            steps {
                sh '''
                    HOSTS="rocky1 rocky2"
    
                    for HOST in $HOSTS; do
                        echo "Scanning $HOST..."
                        sudo -u jenkins ssh-keyscan -T 10 $HOST >> /var/lib/jenkins/.ssh/known_hosts 2>/dev/null || true
                    done

                    echo "Known hosts successfully populated."
                '''
            }
        }
        
        stage('Checkout') {
            steps {
                // Clone via SSH using Jenkins user's key
                git branch: 'master',
                    url: 'git@github.com:funmicra/quarkus.git'
            }
        }

        stage('Install Docker') {
            steps {
                // Playbook is at root of repo
                sh 'ansible-playbook install_docker.yaml -i hosts.ini'
            }
        }

        stage('Prepare Hosts for Ansible Docker Modules') {
            steps {
                sh '''
                ansible all -i hosts.ini -m raw -a "sudo dnf install -y python3 python3-pip"
                ansible all -i hosts.ini -m pip -a "name=docker executable=pip3"
                '''
            }
        }
        stage('Create Docker Volume') {
            steps {
                sh """
                if ! docker volume inspect ${HEIMDALL_VOLUME} >/dev/null 2>&1; then
                    docker volume create ${HEIMDALL_VOLUME}
                else
                    echo "Volume ${HEIMDALL_VOLUME} already exists"
                fi
                """
            }
        }

        stage('Deploy Heimdall') {
            steps {
                // Playbook is at root of repo
                sh 'ansible-playbook heimdall.yaml -i hosts.ini'
            }
        }
    }

    post {
        success {
            echo "Heimdall deployed successfully!"
        }
        failure {
            echo "Deployment failed!"
        }
    }
}
