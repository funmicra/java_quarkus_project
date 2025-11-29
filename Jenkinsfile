pipeline {
    agent any

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

    triggers {
        githubPush()
    }

    stages {

        stage('Checkout Source') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/funmicra/java_quarkus_project.git'
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

        // stage('Authenticate to Registry') {
        //     steps {
        //         withCredentials([usernamePassword(
        //             credentialsId: 'docker-registry-creds',
        //             usernameVariable: 'REG_USER',
        //             passwordVariable: 'REG_PASS'
        //         )]) {
        //             sh '''
        //             echo "$REG_PASS" | docker login ${REGISTRY_URL} -u "$REG_USER" --password-stdin
        //             '''
        //         }
        //     }
        // }

        stage('Push to Nexus Registry') {
            steps {
                sh """
                docker push ${FULL_IMAGE}
                """
            }
        }

        stage('Deploy with Ansible') {
            steps {
                sshagent(credentials: ['ansible_ssh']) {
                    sh """
                    cd /usr/bin/ansible &&
                    ansible-playbook -i ansible/hosts.ini ansible/deploy-quarkus.yaml
                    """
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
