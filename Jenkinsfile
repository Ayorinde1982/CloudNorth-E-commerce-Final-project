pipeline {
  agent any
  options {
    timestamps()
    disableConcurrentBuilds()
  }
  environment {
    AWS_DEFAULT_REGION = 'us-east-1'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Tools Check') {
      steps {
        sh '''
          echo "Git version:"; git --version || true
          echo "Terraform version:"; terraform version || true
          which terraform || true
        '''
      }
    }
    stage('Terraform Validate (infra/phase1)') {
      steps {
        sh '''
          terraform -chdir=infra/phase1 init -backend=false -input=false
          terraform -chdir=infra/phase1 validate
        '''
      }
    }
  }
  post {
    always {
      echo "Build finished: ${currentBuild.currentResult}"
    }
  }
}
