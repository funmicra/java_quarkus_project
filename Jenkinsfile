pipeline {
    agent any

    environment {
        NEXUS_URL = 'http://nexus.example.com/repository/pypi-local/' // Your Nexus PyPI repo
        NEXUS_USER = credentials('nexus-username')   // Jenkins credentials ID
        NEXUS_PASSWORD = credentials('nexus-password')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/funmicra/quarkus.git'
            }
        }



        stage('Publish to Nexus') {
            steps {
                sh """
                twine upload --repository-url ${NEXUS_URL} -u ${NEXUS_USER} -p ${NEXUS_PASSWORD} dist/*
                """
            }
        }
    }

    post {
        success {
            echo 'Build and upload completed successfully.'
        }
        failure {
            echo 'Something went wrong!'
        }
    }
}
