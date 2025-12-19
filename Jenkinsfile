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
                    // Retry inventory generation to handle first-run latency
                    sh '''
                        cd ansible
                        python3 dynamic_inventory.py
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
                    set -e

                    INVENTORY="ansible/hosts.ini"
                    KNOWN_HOSTS="/var/lib/jenkins/.ssh/known_hosts"

                    if [ ! -f "$INVENTORY" ]; then
                    echo "[ERROR] Inventory not found: $INVENTORY"
                    exit 1
                    fi

                    echo "[INFO] Updating known_hosts from inventory"

                    # Extract hostnames / IPs:
                    # - ignore group headers
                    # - ignore vars
                    # - take first column only
                    awk '
                    /^[[]/ { next }
                    /^[[:space:]]*$/ { next }
                    /=/ { next }
                    { print $1 }
                    ' "$INVENTORY" | while read -r host; do
                        echo "[INFO] Scanning $host"
                        ssh-keyscan -H "$host" >> "$KNOWN_HOSTS" 2>/dev/null || true
                    done

                    chown -R jenkins:jenkins /var/lib/jenkins/.ssh
                '''
            }
        }

        // Deploy Kubernetes with Kubespray
        stage('Deploy Kubernetes Cluster with Kubespray') {
            when {
                expression {
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
                    pip install -r requirements.txt

                    cp -rfp inventory/sample inventory/mycluster
                    CONFIG_FILE="$WORKSPACE/kubespray/inventory/mycluster/hosts.yaml"
                    HOSTS_INI="$WORKSPACE/ansible/hosts.ini"

                    if [ ! -f "$HOSTS_INI" ]; then
                        echo "ERROR: Hosts file not found: $HOSTS_INI"
                        exit 1
                    fi

                    # Extract dynamic host info from ansible/hosts.ini
                    CTRL_PLANE_HOSTS=$(awk -F'ansible_host=' '/ctrl-plane/ {print $1 ":" $2}' $HOSTS_INI | tr -d ' ')                    WORKER_HOSTS=$(awk -F'ansible_host=' '/worker/ {print $1 ":" $2}' ../../ansible/hosts.ini | tr -d ' ')
                    WORKER_HOSTS=$(awk -F'ansible_host=' '/worker/ {print $1 ":" $2}' $HOSTS_INI | tr -d ' ')
                    # Build hosts section dynamically
                    echo "all:" > $CONFIG_FILE
                    echo "  hosts:" >> $CONFIG_FILE

                    # Add control-plane hosts
                    for host in $CTRL_PLANE_HOSTS; do
                        NAME=$(echo $host | cut -d: -f1)
                        IP=$(echo $host | cut -d: -f2)
                        echo "    $NAME:" >> $CONFIG_FILE
                        echo "      ansible_host: $IP" >> $CONFIG_FILE
                        echo "      ip: $IP" >> $CONFIG_FILE
                        echo "      access_ip: $IP" >> $CONFIG_FILE
                    done

                    # Add worker hosts
                    for host in $WORKER_HOSTS; do
                        NAME=$(echo $host | cut -d: -f1)
                        IP=$(echo $host | cut -d: -f2)
                        echo "    $NAME:" >> $CONFIG_FILE
                        echo "      ansible_host: $IP" >> $CONFIG_FILE
                        echo "      ip: $IP" >> $CONFIG_FILE
                        echo "      access_ip: $IP" >> $CONFIG_FILE
                    done

                    # Build children groups
                    echo "  children:" >> $CONFIG_FILE
                    echo "    kube_control_plane:" >> $CONFIG_FILE
                    echo "      hosts:" >> $CONFIG_FILE
                    for host in $CTRL_PLANE_HOSTS; do
                        NAME=$(echo $host | cut -d: -f1)
                        echo "        $NAME:" >> $CONFIG_FILE
                    done

                    echo "    kube_node:" >> $CONFIG_FILE
                    echo "      hosts:" >> $CONFIG_FILE
                    for host in $WORKER_HOSTS; do
                        NAME=$(echo $host | cut -d: -f1)
                        echo "        $NAME:" >> $CONFIG_FILE
                    done

                    echo "    etcd:" >> $CONFIG_FILE
                    echo "      hosts:" >> $CONFIG_FILE
                    for host in $CTRL_PLANE_HOSTS; do
                        NAME=$(echo $host | cut -d: -f1)
                        echo "        $NAME:" >> $CONFIG_FILE
                    done

                    echo "    k8s_cluster:" >> $CONFIG_FILE
                    echo "      children:" >> $CONFIG_FILE
                    echo "        kube_control_plane:" >> $CONFIG_FILE
                    echo "        kube_node:" >> $CONFIG_FILE

                    echo "    calico_rr:" >> $CONFIG_FILE
                    echo "      hosts: {}" >> $CONFIG_FILE

                    # Run Kubespray playbook
                    ansible-playbook -i $CONFIG_FILE \
                        --private-key ~/.ssh/id_rsa \
                        -u funmicra \
                        --become --become-user=root \
                        cluster.yml
                '''
            }
        }

        
        stage('Verify Docker Access') {
            steps {
                sh '''
                id
                docker version
                docker ps
                '''
            }
        }

        // Build Quarkus Application
        stage('Build Quarkus App (Native)') {
            steps {
                sh '''
                ./mvnw clean package \
                    -DskipTests \
                    -Pnative \
                    -Dquarkus.native.container-build=true
                    
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
        stage('Deploy on Cluster') {
            steps {
                sh """
                echo "Validating namespace runway..."

                # Create namespace only if missing
                if ! kubectl get namespace quarkus >/dev/null 2>&1; then
                    echo "Namespace 'quarkus' missing — provisioning..."
                    kubectl create namespace quarkus
                else
                    echo "Namespace 'quarkus' present — leveraging existing environment."
                fi

                echo "Rolling forward application assets..."

                # Smart redeploy: apply manifests directly
                kubectl apply -f k8s/deployment.yaml -n quarkus
                kubectl apply -f k8s/service.yaml    -n quarkus || true

                echo "Surfacing runtime status..."
                kubectl get pods -n quarkus
                kubectl get svc  -n quarkus
                sleep 5

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
