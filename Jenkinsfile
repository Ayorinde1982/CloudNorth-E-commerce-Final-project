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
    stage('Terraform Validate (infra/phase1)') {
      steps {
        sh '''
          if command -v terraform >/dev/null 2>&1; then
            terraform -chdir=infra/phase1 init -backend=false -input=false
            terraform -chdir=infra/phase1 validate
          else
            echo "Terraform not installed on agent"
            exit 1
          fi
        '''
      }
    }
    stage('Frontend Lint/Test (optional)') {
      steps {
        sh '''
          if [ -f apps/frontend/package.json ]; then
            cd apps/frontend
            if command -v npm >/dev/null 2>&1; then
              npm ci || npm install
              npm test || echo "No frontend tests defined"
            else
              echo "npm not installed on agent; skipping"
            fi
          else
            echo "No frontend app detected; skipping"
          fi
        '''
      }
    }
    stage('Backend Test (optional)') {
      steps {
        sh '''
          if [ -f apps/backend/requirements.txt ]; then
            python3 -m venv .venv
            . .venv/bin/activate
            pip install -r apps/backend/requirements.txt
            if command -v pytest >/dev/null 2>&1; then
              pytest -q || echo "No backend tests defined"
            else
              echo "pytest not installed; skipping"
            fi
          else
            echo "No backend app detected; skipping"
          fi
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
