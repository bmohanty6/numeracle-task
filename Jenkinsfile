pipeline {
    agent any

    environment {
        IMAGE_NAME = "bmohanty6/numeracle-demo"
        TAG_NAME   = "v${currentBuild.number}"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub_bmohanty6')
    }

    stages {
        stage('checkout') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/bmohanty6/numeracle-task.git']]])
            }
        }
        stage('build') {
            steps {
                sh './mvnw install'
            }
        }
        stage('Docker image build'){
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${TAG_NAME} -t ${IMAGE_NAME}:latest .'
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                // sh 'docker push ${IMAGE_NAME}'
            }
        }
        stage('Plan terraform changes'){
            steps {
                withAWS(credentials: 'biswa_infra_automation', region: 'us-east-1') {
                    sh 'cd terraform; terraform init ; terraform plan'
                    input message: 'Go ahead with planned terraform changes'
                }
            }
        }
        stage('Apply terraform changes'){
            steps {
                withAWS(credentials: 'biswa_infra_automation', region: 'us-east-1') {
                    sh 'cd terraform; terraform init ; terraform apply -auto-approve'
                }
            }
        }
    }
    post {
        always {
          sh 'docker logout'
        }
    }
}
