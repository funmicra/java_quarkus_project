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
                git credentialsId: 'github-creds',
                    url: 'https://github.com/funmicra/java_quarkus_project.git',
                    branch: 'master'
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
                        cd terraform
                        
                        TF_VAR_pm_api_token_id=$PM_API_TOKEN_ID \
                        TF_VAR_pm_api_token_secret=$PM_API_TOKEN_SECRET \
                        TF_VAR_ciuser=funmicra \
                        TF_VAR_cipassword=$CI_PASSWORD \
                        TF_VAR_ssh_keys_file=$SSH_KEYS_FILE \
                        terraform init

                        TF_VAR_pm_api_token_id=$PM_API_TOKEN_ID \
                        TF_VAR_pm_api_token_secret=$PM_API_TOKEN_SECRET \
                        TF_VAR_ciuser=funmicra \
                        TF_VAR_cipassword=$CI_PASSWORD \
                        TF_VAR_ssh_keys_file=$SSH_KEYS_FILE \
                        terraform apply -auto-approve

                        sleep 20
                    '''
                }
            }
        }

        // Reapply SSH keys for Ansible
        stage('🔒 Reapply SSH keys') {
            when {
                expression {
                    // Execute this stage ONLY if commit message contains [INFRA]
                    currentBuild.changeSets.any { cs ->
                        cs.items.any { it.msg.contains("[INFRA]") }
                    }
                }
            }
            steps {
                sh """
                ssh-keyscan -H 192.168.88.90 >> /var/lib/jenkins/.ssh/known_hosts
                ssh-keyscan -H 192.168.88.91 >> /var/lib/jenkins/.ssh/known_hosts
                chown -R jenkins:jenkins /var/lib/jenkins/.ssh/
                """
            }
        }
 
        // Deploy Kubernetes with Kubespray
        stage('Deploy Kubernetes Cluster with Kubespray') {
            when {
                expression {
                    // Execute this stage ONLY if commit message contains [INFRA]
                    currentBuild.changeSets.any { cs ->
                        cs.items.any { it.msg.contains("[INFRA]") }
                    }
                }
            }
            steps {
                sh '''
                    rm -rf kubespray
                    git clone https://github.com/kubernetes-sigs/kubespray.git
                    cd kubespray

                    python3 -m venv venv
                    . venv/bin/activate
                    python3 -m pip install --upgrade pip
                    pip3 install -r requirements.txt

                    cp -rfp inventory/sample inventory/mycluster
                    
                    CONFIG_FILE=inventory/mycluster/hosts.yaml

                    cat <<EOF > $CONFIG_FILE
all:
  hosts:
    ctrl-plane:
      ansible_host: 192.168.88.90
      ip: 192.168.88.90
      access_ip: 192.168.88.90
    worker1:
      ansible_host: 192.168.88.91
      ip: 192.168.88.91
      access_ip: 192.168.88.91
  children:
    kube_control_plane:
      hosts:
        ctrl-plane:
    kube_node:
      hosts:
        worker1:
    etcd:
      hosts:
        ctrl-plane:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
EOF

                    # Use Jenkins user's SSH key
                    ansible-playbook -i inventory/mycluster/hosts.yaml \
                        --private-key ~/.ssh/id_rsa \
                        -u funmicra \
                        --become --become-user=root \
                        cluster.yml
                '''
            }
        }

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
        // Stage to deploy application on Kubernetes cluster        
        stage('Deploy on Cluster') {
            steps {
                sh """
                echo "Streamlining workload refresh pipeline..."

                # Ensure namespace exists (idempotent)
                kubectl get namespace quarkus >/dev/null 2>&1 || kubectl create namespace quarkus

                echo "Namespace 'quarkus' validated."

                # Hard refresh only the application footprint
                echo "Purging stale workloads..."
                kubectl delete deployment --all -n quarkus --ignore-not-found
                kubectl delete svc        --all -n quarkus --ignore-not-found

                # Apply the new service contract and pod shape
                echo "Rolling fresh artifacts..."
                kubectl apply -f k8s/deployment.yaml -n quarkus
                kubectl apply -f k8s/service.yaml    -n quarkus || true

                # Operational visibility
                echo "Resource ledger:"
                kubectl get pods -n quarkus
                kubectl get svc  -n quarkus

                sleep 3
                """
            }
        }
        
        // Stage to verify deployment by sending HTTP requests
        stage('Verify Deployment') {
            steps {
                script {
                    retry(5){
                        def hosts = ['192.168.88.91', '192.168.88.90']
                        for (host in hosts) {
                            sh "curl http://${host}:30080/sample?param=java || exit 1"
                        }
                    }
                }
            }
        }

        stage('🧹 Cleanup Workspace') {
            steps {
                sh 'rm -rf *'
            }
        }
    }

    post {
        success {
            echo "Pipeline executed successfully!✅"
        }
        failure {
            echo "Pipeline failed. Check logs for errors. ⚠️"
        }
    }
} 
