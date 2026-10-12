pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'jeeva22893/trend-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                '''
            }
        }

        stage('Docker Push') {
            steps {
                sh '''
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }

        stage('Docker Deploy') {
            steps {
                sh '''
                    set -eu

                    docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}

                    docker rm -f trend-app || true

                    docker run -d \
                        --name trend-app \
                        --restart unless-stopped \
                        -p 3000:3000 \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}

                    for i in $(seq 1 15); do
                        if curl -fsS http://localhost:3000/ > /dev/null; then
                            echo "Trend application deployed successfully!"
                            exit 0
                        fi
                        sleep 2
                    done

                    echo "Deployment health check failed"
                    docker logs --tail 30 trend-app
                    exit 1
                '''
            }
        }

    }

    post {
        success {
            echo 'Trend Docker image pushed successfully!'
        }

        failure {
            echo 'Trend CI/CD pipeline failed.'
        }
    }
}
