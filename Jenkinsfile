pipeline {

    agent {
        docker {
            image 'node16-docker-agent:latest'

            args '''
                --network bridge
                -e DOCKER_HOST=tcp://172.18.0.2:2376
                -e DOCKER_CERT_PATH=/certs/client
                -e DOCKER_TLS_VERIFY=1
                -v /certs/client:/certs/client:ro
            '''

            reuseNode true
        }
    }

    environment {
        DOCKER_HOST = 'tcp://172.18.0.2:2376'
        DOCKER_CERT_PATH = '/certs/client'
        DOCKER_TLS_VERIFY = '1'

        IMAGE_NAME = 'aws-node-app'
        DOCKERHUB_IMAGE = 'shrmhrjn99/assessment2'
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
                sh 'docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKERHUB_IMAGE}:${IMAGE_TAG}'
            }
        }

        stage('Vulnerability Scan') {
            steps {
                echo 'Scanning Docker image for HIGH and CRITICAL vulnerabilities...'
                echo 'The security gate fails the build for fixable HIGH/CRITICAL vulnerabilities.'

                sh '''
                    docker run --rm \
                    -e DOCKER_HOST=tcp://172.18.0.2:2376 \
                    -e DOCKER_CERT_PATH=/certs/client \
                    -e DOCKER_TLS_VERIFY=1 \
                    -v /certs/client:/certs/client:ro \
                    aquasec/trivy:latest \
                    image \
                    --severity HIGH,CRITICAL \
                    --ignore-unfixed \
                    --exit-code 1 \
                    ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Logging in to Docker Hub and pushing the image...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x

                        echo "$DOCKERHUB_TOKEN" | docker login \
                            --username "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        docker push ${DOCKERHUB_IMAGE}:${IMAGE_TAG}

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'package.json,package-lock.json,Jenkinsfile',
                             allowEmptyArchive: true
        }

        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'CI/CD pipeline failed. Check the stage logs above.'
        }
    }
}