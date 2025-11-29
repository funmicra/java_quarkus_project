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

    options {
        ansiColor('xterm')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
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

        stage('Install Docker with Ansible') {
            steps {
                sshagent(credentials: ['JENKINS_SSH_KEY']) {
                    sh """
                    ansible-playbook -i ansible/hosts.ini ansible/install_docker.yaml
                    """
                }
            }
        }

        stage('Deploy with Ansible') {
            steps {
                sshagent(credentials: ['JENKINS_SSH_KEY']) {
                    sh """
                    ansible-playbook -i ansible/hosts.ini ansible/deploy-quarkus.yaml
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    def hosts = ['192.168.88.90', '192.168.88.91']
                    for (host in hosts) {
                        sh "curl -s http://${host}:8081/sample?param=test"
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
