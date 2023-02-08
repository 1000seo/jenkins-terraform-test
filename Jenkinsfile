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
        SLACK_DEPLOY_CHANNEL = "#jenkins"
        SLACK_CHANNEL = "#jenkins"
    }

    tools {
        terraform 'terraform1.2.6'
        git 'git'
    }


    stages {
        stage('Setup Account ID') {
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {
                    fail_stage = "${STAGE_NAME}"
                    switch(PROJECT_NAME) {
                        case "project" :
                            if (ENV == 'dev' || ENV == 'qa') {
                                env.AWS_ACCOUNT_ID = '1234' 
                            }
                            else {
                                env.AWS_ACCOUNT_ID = '5678'
                            }
                        break;
                        case "project2" :
                            if (ENV == 'dev' || ENV == 'qa') {
                                env.AWS_ACCOUNT_ID = '1234' 
                            }
                            else {
                                env.AWS_ACCOUNT_ID = '5678'
                            }
                        break;
                        case "project3" :
                            if (ENV == 'dev' || ENV == 'qa') {
                                env.AWS_ACCOUNT_ID = '1234' 
                            }
                            else {
                                env.AWS_ACCOUNT_ID = '5678'
                            }
                        break;
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {fail_stage = "${STAGE_NAME}"}
                checkout scm
                sh 'git status'
                
                echo "========== variables value check ========="
                echo "Project name: ${PROJECT_NAME}"
                echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
                echo "ENV: ${ENV}"
                echo "Three tier: ${THREE_TIER}"
                echo "Service: ${SERVICE}"
                
                echo "========== Directory Path =========="
                script {
                    fail_stage = "${STAGE_NAME}"
                    env.DIR_PATH = "${PROJECT_NAME}/${AWS_ACCOUNT_ID}/${ENV}/${THREE_TIER}/${SERVICE}"
                }
                echo "DIR_PATH: ${DIR_PATH}"
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
                dir("${DIR_PATH}"){
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
                dir("${DIR_PATH}"){
                    sh 'pwd'
                    sh "terraform plan -input=false -out tfplan "
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                    sh 'ls -al'
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
                dir("${DIR_PATH}"){
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
                script {
                    fail_stage = "${STAGE_NAME}"
                    slackSend(channel: SLACK_CHANNEL, color: '#00FF00', botUser: true,
                                message: "Apply STARTED: Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
                    }
                dir("${DIR_PATH}"){
                    sh "terraform apply -input=false tfplan"
                    sh "terraform output > tfoutput.txt"
                    sh "ls -al"
                }
            }
        }

        stage('Read Output') {
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                dir("${DIR_PATH}"){
                    sh 'ls -al'
                    script {
                        def data = readFile(file: 'tfoutput.txt')
                        echo(data)
                    }
                }
            }
        }

        stage('Destroy') {
            when {
                equals expected: true, actual: params.destroy
            }
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {
                    fail_stage = "${STAGE_NAME}"
                    slackSend(channel: SLACK_CHANNEL, color: '#00FF00', botUser: true,
                                message: "Destroy STARTED: Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
                    }
                dir("${DIR_PATH}"){
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
                    slackSend(channel: SLACK_CHANNEL, blocks: formatSlackMsg(deploymentMessage), botUser: true)
                    sh "echo ${GIT_HASH} > git_hash"
                    
                }
            }
        }
    }
    post {
        failure {
            script {
                msg = "${fail_stage} FAILED: Job '${env.JOB_NAME} [${BUILD_TAG}/#${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
                slackSend(channel: SLACK_CHANNEL, color: '#FF0000', message: msg)
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
