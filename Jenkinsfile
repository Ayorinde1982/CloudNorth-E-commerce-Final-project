pipeline {
  agent any
  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20')) // keep last 20 builds
  }
  environment {
    AWS_DEFAULT_REGION = 'us-east-1'
  }
  stages {
    stage('Clean workspace') {
      steps {
        deleteDir()   // built-in; deletes everything in the current workspace
      }
    }
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Tools Check') {
      steps {
        sh '''
          set -euxo pipefail
          echo "Git version:"; git --version
          echo "Terraform version:"; terraform version
          which terraform || true
        '''
      }
    }
    stage('Terraform Validate (infra/phase1)') {
      steps {
        sh '''
          set -euxo pipefail
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
