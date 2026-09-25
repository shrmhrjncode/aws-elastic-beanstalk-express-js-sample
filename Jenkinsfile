pipeline {

    agent {
        docker {
            image 'node16-docker-agent:latest'

            args '''
                --network bridge
                -e DOCKER_HOST=tcp://172.18.0.2:2376
                -e DOCKER_CERT_PATH=/certs/client
                -e DOCKER_TLS_VERIFY=1
                -v jenkins-docker-compose_dind-certs:/certs/client:ro
            '''

            reuseNode true
        }
    }

    environment {
        IMAGE_NAME = 'aws-node-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                sh 'npm ci'
            }
        }

        stage('Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh 'npm test'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building application Docker image...'
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Vulnerability Scan') {
            steps {
                echo 'Scanning Docker image for HIGH and CRITICAL vulnerabilities...'

                sh '''
                    docker run --rm \
                      aquasec/trivy:latest \
                      image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Docker image passed the vulnerability scan.'
                echo 'Registry push will be configured after Jenkins credentials are added.'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'package.json,package-lock.json,Jenkinsfile',
                             allowEmptyArchive: true
        }

        success {
            echo 'CI pipeline completed successfully.'
        }

        failure {
            echo 'CI pipeline failed. Check the stage logs above.'
        }
    }
}