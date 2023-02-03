pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        booleanParam(name: 'destroy', defaultValue: false, description: 'Destroy Terraform build?')
    }

     environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        GIT_HASH = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
    }

    tools {
        terraform 'terraform1.2.6'
        git 'git'
    }


    stages {
        stage('checkout') {
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                    checkout scm
                    sh 'git status'
                }
            }
            
        stage('Init') {
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
            
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {fail_stage = "${STAGE_NAME}"}
                dir('terraform-code'){
                    sh 'ls -al'
                    sh 'terraform init -input=false'
                }
                
            }
        }

        stage('Plan') {
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
            
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {fail_stage = "${STAGE_NAME}"}
                dir('terraform-code'){
                    sh 'pwd'
                    sh "terraform plan -input=false -out tfplan "
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                }
            }
        }

        stage('Approval') {
           when {
               not {
                   equals expected: true, actual: params.autoApprove
               }
               not {
                    equals expected: true, actual: params.destroy
                }
           }
           steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {fail_stage = "${STAGE_NAME}"}
                
                dir('terraform-code'){
                    script {
                        def plan = readFile 'tfplan.txt'
                        input message: "Do you want to apply the plan?",
                        parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                    }
                }
            }
        }

        stage('Apply') {
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {fail_stage = "${STAGE_NAME}"}

                dir('terraform-code'){
                    sh "terraform apply -input=false tfplan"
                }
            }
        }

        stage('Destroy') {
            when {
                equals expected: true, actual: params.destroy
            }
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {fail_stage = "${STAGE_NAME}"}

                dir('terraform-code'){
                    sh "terraform init"
                    sh "terraform destroy --auto-approve"
                }
            }
        }

        stage('Send Slack Message') {
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {
                    fail_stage = "${STAGE_NAME}"
                    gitHash = GIT_HASH
                    deploymentMessage = sh(returnStdout: true, script: getGitFormattedLog())
                    slackSend(channel: "#jenkins", blocks: formatSlackMsg(deploymentMessage), botUser: true)
                    //slackSend(channel: SLACK_DEPLOY_CHANNEL, blocks: formatSlackMsg(deploymentMessage), botUser: true)
                    sh "echo ${GIT_HASH} > git_hash"
                    
                }
            }
        }
    }
    post {
        failure {
            script {
                msg = "${fail_stage} FAILED: Job '${env.JOB_NAME} [${BUILD_TAG}/#${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
                slackSend(channel: "#jenkins", color: '#FF0000', message: msg)
                // slackSend(channel: SLACK_DEVOPS_CHANNEL, color: '#FF0000', message: msg)
            }
        }
        always {
            cleanWs()
        }
    }
}

def getGitFormattedLog() {
    return "git log --pretty=format:'<https://github.com/1000seo/${getRepoName()}/commit/%h|%h> ( *%<(8,trunc) %an* ) %s' ${gitHash}...${GIT_HASH} --date=format:'%Y-%m-%d %H:%m' | sed '/Merge /d'"
}

String getRepoName() {
    return scm.getUserRemoteConfigs()[0].getUrl().tokenize('/').last().split("\\.")[0]
}

def formatSlackMsg(msgStr) {
    def arr = []
    arr << [
        type: 'header',
        text: [
            type: 'plain_text',
            text: '[Terraform] Apply Success'
        ]
    ]
    arr << [
        type: 'divider',
    ]
    arr << [
        type: 'section',
        text: [
            type: 'plain_text',
            text: "${currentBuild.number}"
        ]
    ]
    msgStr.split('\n').each {
        if (it.trim().length() > 0) {
            arr << [
                type: 'section',
                text: [
                    type: 'mrkdwn',
                    text: it.trim()
                ]
            ]
        }
    }
    return arr
}
