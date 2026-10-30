pipeline {
    agent any

    triggers { pollSCM('H/2 * * * *') }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Build Docker Image') {
            steps { sh 'docker compose build' }
        }
        stage('Deploy Containers') {
            steps {
                sh 'docker compose down || true'
                sh 'docker compose up -d'
            }
        }
        stage('Verify Application') {
            steps {
                sh '''
                for i in $(seq 1 30); do
                  if curl -sf http://localhost:8000 > /dev/null; then
                    echo "Application is accessible"; exit 0
                  fi
                  echo "Waiting for app... ($i)"; sleep 5
                done
                echo "Application not reachable"; docker compose logs; exit 1
                '''
            }
        }
    }
    post {
        success { echo 'Deployed: http://localhost:8000' }
        failure { sh 'docker compose logs --tail=50 || true' }
    }
}
