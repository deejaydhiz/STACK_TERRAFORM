pipeline {
  agent any
  parameters {
    credentials credentialType: 'com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl', defaultValue: 'stack_prog_uat', name: 'AWS', required: false
  }

  environment {
    PATH = "${PATH}:${getTerraformPath()}"
  }

  stages {
    stage('Initial Deployment Approval') {
      steps {
        script {
          def userInput = input(id: 'initial_confirm', message: 'Start Pipeline?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Start Pipeline', name: 'confirm'] ])
        }
      }
    }

    stage('terraform init') {
      steps {
        sh 'terraform init'
      }
    }

    stage('terraform plan'){
      steps {
        sh 'terraform plan -out=tfplan -input=false'
      }
    }
    
    stage('Final Deployment Approval') { 
      steps { 
        script { 
          def userInput = input(id: 'final_confirm', message: 'Apply Terraform?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform', name: 'confirm'] ]) 
        } 
      } 
    }

    stage('Terraform Apply'){ 
      steps {
        sh "terraform apply -input=false tfplan" 
      } 
    }
  }
}

def getTerraformPath() {
  def tfHome = tool name: 'terraform-14', type: 'terraform'
  return tfHome
}