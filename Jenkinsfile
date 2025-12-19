pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        REGISTRY_URL = "registry.black-crab.cc"
        IMAGE_NAME   = "java-quarkus"
        FULL_IMAGE   = "${env.REGISTRY_URL}/${env.IMAGE_NAME}:latest"
    }

    stages {
        // Connect to Github repo
        stage('Checkout Source') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/funmicra/java_quarkus_project.git'
            }
        }

        // Terraform Provision
        stage('Terraform Provision VMs') {
            when {
                expression {
                    // Execute this stage ONLY if commit message contains [INFRA]
                    currentBuild.changeSets.any { cs ->
                        cs.items.any { it.msg.contains("[INFRA]") }
                    }
                }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'PROXMOX_TOKEN_ID', variable: 'PM_API_TOKEN_ID'),
                    string(credentialsId: 'PROXMOX_TOKEN_SECRET', variable: 'PM_API_TOKEN_SECRET'),
                    string(credentialsId: 'VM_CI_PASSWORD', variable: 'CI_PASSWORD'),
                    string(credentialsId: 'VM_CI_USER', variable: 'CI_USER'),
                    file(credentialsId: 'PROXMOX_SSH_KEY', variable: 'SSH_KEYS_FILE')
                ]) {
                    sh '''
                        chmod +x scripts/provision_terraform.sh
                        bash scripts/provision_terraform.sh                        
                    '''
                }
            }
        }

        stage('Announce Terraform Import Commands') {
            steps {
                sh '''
                    python3 scripts/announce_tf_imports.py
                '''
            }
        }

        stage('Update Dynamic Inventory') {
            steps {
                script {
                    // Retry inventory generation to handle first-run latency
                    sh '''
                        python3 ansible/dynamic_inventory.py
                    '''
                }
            }
        }        

        // Reapply SSH keys for Ansible
        stage('Reapply SSH keys') {
            when {
                expression {
                    currentBuild.changeSets.any { cs ->
                        cs.items.any { it.msg.contains("[INFRA]") }
                    }
                }
            }
            steps {
                sh '''
                    chmod +x scripts/update_known_hosts.sh
                    bash scripts/update_known_hosts.sh
                '''
            }
        }

        // Deploy Kubernetes with Kubespray
        stage('Deploy Kubernetes Cluster with Kubespray') {
            when {
                expression {
                    currentBuild.changeSets.any { cs ->
                        cs.items.any { it.msg.contains("[K8S]") }
                    }
                }
            }
            steps {
                sh '''
                    chmod +x scripts/deploy_k8s.sh
                    bash scripts/deploy_k8s.sh
                '''
            }
        }
        
        // stage('Verify Docker Access') {
        //     steps {
        //         sh '''
        //         id
        //         docker version
        //         docker ps
        //         '''
        //     }
        // }

        // // Build Quarkus Application
        // stage('Build Quarkus App (Native)') {
        //     steps {
        //         sh '''
        //         ./mvnw clean package \
        //             -DskipTests \
        //             -Pnative \
        //             -Dquarkus.native.container-build=true

        //         '''
        //     }
        // }


        // Build Docker Image
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ."
            }
        }

        // Authenticate to Registry
        stage('Authenticate to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'NEXUS_REGISTRY_LOGIN',
                    usernameVariable: 'REG_USER',
                    passwordVariable: 'REG_PASS'
                )]) {
                    sh 'echo "$REG_PASS" | docker login ${REGISTRY_URL} -u "$REG_USER" --password-stdin'
                }
            }
        }

        // Push Docker Image
        stage('Push to Nexus Registry') {
            steps {
                sh "docker push ${FULL_IMAGE}"
            }
        }
        
        stage('⚙️ Fetch Kubeconfig') {
            steps {
                sh'''
                    ansible-playbook -i ansible/hosts.ini ansible/get-kubeconfig.yaml
                '''
                }
        }

        // Stage to deploy application on Kubernetes cluster        
        stage('Deploy on Cluster') {
            steps {
                sh """
                    chmod +x scripts/deploy_quarkus.sh
                    bash scripts/deploy_quarkus.sh
                """
            }
        }
        
        // Stage to verify deployment by sending HTTP requests
        stage('Verify Deployment') {
            steps {
                sh '''
                chmod +x scripts/verify_deployment.sh
                bash scripts/verify_deployment.sh ansible/hosts.ini /sample?param=java 30080 5 5
                '''
            }
        }

    }
    //     stage('🧹 Cleanup Workspace') {
    //         steps {
    //             echo 'Cleaning Jenkins workspace...'
    //             deleteDir()  // Jenkins Pipeline step to remove all files in the workspace
    //         }
    //     }
    // }

    post {
        success {
            echo "Pipeline executed successfully!✅"
        }
        failure {
            echo "Pipeline failed. Check logs for errors. ⚠️"
        }
    }
} 
