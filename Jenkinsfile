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
                    file(credentialsId: 'PROXMOX_SSH_KEY', variable: 'SSH_KEYS_FILE')
                ]) {
                    sh '''
                        chmod +x scripts/provision_terraform.sh
                        scripts/provision_terraform.sh                        
                    '''
                }
            }
        }

        stage('Announce Terraform Import Commands') {
            when {
                expression {
                    // Execute this stage ONLY if commit message contains [INFRA]
                    currentBuild.changeSets.any { cs ->
                        cs.items.any { it.msg.contains("[INFRA]") }
                    }
                }
            }
            steps {
                script {
                    // Read Terraform outputs
                    def vm_ids = readJSON(text: sh(script: "terraform -chdir=terraform output -json vm_ids", returnStdout: true).trim())
                    def vm_names = readJSON(text: sh(script: "terraform -chdir=terraform output -json vm_names", returnStdout: true).trim())

                    // Generate import commands dynamically for all VMs
                    vm_ids.eachWithIndex { id, idx ->
                        def name = vm_names[idx]
                        echo "terraform import \"proxmox_vm_qemu.${name}\" ${id}"
                    }
                }
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
                    scripts/update_known_hosts.sh
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
                    scripts/deploy_k8s.sh
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
                    credentialsId: 'nexus_registry_login',
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
                    scripts/deploy_quarkus.sh
                """
            }
        }
        
        // Stage to verify deployment by sending HTTP requests
        stage('Verify Deployment') {
            steps {
                script {
                    // Retry the whole block up to 5 times
                    retry(5) {
                        // Read hosts.ini dynamically
                        def hosts = []
                        def inventory = readFile('ansible/hosts.ini').split('\n')
                        for (line in inventory) {
                            line = line.trim()
                            if (line && !line.startsWith('[') && !line.startsWith('#')) {
                                // Extract the ansible_host IP
                                def matcher = line =~ /ansible_host=(\S+)/
                                if (matcher) {
                                    hosts << matcher[0][1]
                                }
                            }
                        }

                        // Verify deployment on each host
                        for (host in hosts) {
                            sh "curl http://${host}:30080/sample?param=java || exit 1"
                        }
                    }
                }
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
