pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 1, unit: 'HOURS')
    }


    parameters {
        string(name: 'DOCKER_HUB_USER', defaultValue: 'viateur', description: 'Docker Hub Username')
        string(name: 'DOCKER_HUB_REPO', defaultValue: 'jenkins-simple-web-app', description: 'Docker Hub Repository Name')
        string(name: 'EC2_PUBLIC_IP', defaultValue: '', description: 'Target EC2 Public IP')
        string(name: 'APP_VERSION', defaultValue: '1.0.0', description: 'Application Version')
    }

    environment {
        // Industry Best Practice: Bind credentials directly in the environment block
        // This automatically creates DOCKER_CREDS_USR and DOCKER_CREDS_PSW
        DOCKER_CREDS      = credentials('registry_creds')
        
        // ID for the SSH Agent plugin
        EC2_SSH_CREDS_ID  = 'ec2_ssh'
        
        // Construct image name dynamically from parameters
        DOCKER_IMAGE      = "${params.DOCKER_HUB_USER}/${params.DOCKER_HUB_REPO}"
        
        // Application configuration
        APP_MESSAGE       = "Deployment successful via Jenkins Best Practices Pipeline!"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Install') {
            steps {
                echo "Installing dependencies..."
                sh 'npm install'
            }
        }

        stage('Unit Tests') {
            steps {
                echo "Running unit tests..."
                sh 'npm test'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_IMAGE}:${params.APP_VERSION}"
                    sh "docker build --build-arg APP_VERSION=${params.APP_VERSION} -t ${DOCKER_IMAGE}:${params.APP_VERSION} ."
                    sh "docker tag ${DOCKER_IMAGE}:${params.APP_VERSION} ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    // Using variables provided by the credentials() helper
                    sh "echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin"
                    echo "Pushing image to Docker Hub..."
                    sh "docker push ${DOCKER_IMAGE}:${params.APP_VERSION}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                // Ensure deployment only happens if an IP is provided
                expression { params.EC2_PUBLIC_IP != '' }
            }
            steps {
                sshagent(credentials: [EC2_SSH_CREDS_ID]) {
                    echo "Deploying to ${params.EC2_PUBLIC_IP}..."
                    sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@${params.EC2_PUBLIC_IP} "
                            docker pull ${DOCKER_IMAGE}:latest &&
                            docker stop web-app || true &&
                            docker rm web-app || true &&
                            docker run -d --name web-app \
                                -p 80:3000 \
                                -e APP_MESSAGE='${APP_MESSAGE}' \
                                -e APP_VERSION='${params.APP_VERSION}' \
                                ${DOCKER_IMAGE}:latest &&
                            docker system prune -f
                        "
                    """
                }
            }
        }
    }

    post {
        always {
            sh "docker logout || true"
            cleanWs() // Best Practice: Keep Jenkins agents clean
        }
        success {
            echo "Successfully deployed version ${params.APP_VERSION} to http://${params.EC2_PUBLIC_IP}"
        }
        failure {
            echo "Pipeline failed. Check build logs."
        }
    }
}
