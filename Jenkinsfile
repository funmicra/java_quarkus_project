pipeline {
    agent any
    triggers {
        githubPush()
    }
    
    environment {
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

        stage('Reapply ssh keys') {
            steps {
                sh """
                ssh-keyscan -H 192.168.88.90 >> /var/lib/jenkins/.ssh/known_hosts
                ssh-keyscan -H 192.168.88.91 >> /var/lib/jenkins/.ssh/known_hosts
                chown -R jenkins:jenkins /var/lib/jenkins/.ssh/
                """
            }
        }
        
        stage('Install Docker with Ansible') {
            steps {
                sshagent(credentials: ['JENKINS_SSH_KEY']) {
                    sh """
                    ansible-playbook -i ansible/hosts.ini ansible/install_docker.yaml -vv
                    """
                }
            }
        }

        stage('Deploy quarkus App with Ansible') {
            steps {
                sshagent(credentials: ['JENKINS_SSH_KEY']) {
                    sh """
                    ansible-playbook -i ansible/hosts.ini ansible/deploy-quarkus.yaml -vv
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    retry(5){
                        def hosts = ['192.168.88.90', '192.168.88.91']
                        for (host in hosts) {
                            sh "curl -s http://${host}:8080/sample?param=test"
                        }
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
