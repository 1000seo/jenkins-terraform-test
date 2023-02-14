pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        //배포할 땐 destroy 주석처리하기
        booleanParam(name: 'destroy', defaultValue: false, description: 'Destroy Terraform build?')
    }

     environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        GIT_HASH = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
        TF_PLAN = 'tfplan'
        TF_APPLY_RESOURCE = 'tfapply'
        GIT_URL = "https://github.com/1000seo/jenkins-terraform-test.git"
        GIT_REPO = "jenkins-terraform-test"
        SLACK_CHANNEL = "#jenkins"
        
    }

    tools {
        terraform 'terraform1.2.6'
        git 'git'
    }


    stages {
        stage('AWS update check') {
            steps {
                script {
                    MASTER_BRANCH_HASH = sh(returnStdout: true, script: 'git rev-parse --short origin/master').trim()
                    WORK_BRANCH_HASH = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    sh "git show ${MASTER_BRANCH_HASH}...${WORK_BRANCH_HASH} --name-only --pretty='%n' > update.txt"
                    sh 'ls -al'

                    def update = readFile(file: "update.txt")
                    slackSend(channel: SLACK_CHANNEL, color: '#00FF00', botUser: true, 
                            message: ":white_check_mark: Git Repogitory update Directory!\n :pushpin: update file ${update}")
                }
            }
        }

        stage('Git Clone & Update') {
            steps {
                checkout scm
                sh 'git status'

                script {
                    fail_stage = "${STAGE_NAME}"

                    if (env.BUILD_NUMBER == 1) {
                        sh "git clone ${GIT_URL}"
                    }
                    else {
                        dir("${GIT_REPO}"){
                            sh 'git pull origin TF-v2'
                        }
                    }
                }
            }
        }

        stage('Setup Dirctory Path') {
            steps {
                script {
                    echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                    fail_stage = "${STAGE_NAME}"

                    env.DIR_PATH = input (
                        message: "Enter the Path with Terraform apply",
                        parameters: [string(name: 'DIR_PATH', description: 'Please review the plan', defaultValue: 'Directory path value')]
                    )
                }
            }
        }
            
        stage('Init') {
            when { not { equals expected: true, actual: params.destroy } }
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"

                dir("${DIR_PATH}"){
                    script {
                        fail_stage = "${STAGE_NAME}"

                        sh 'ls -al'
                        sh 'terraform init -input=false'
                    }
                }
            }
        }

        stage('Plan') {
            when { not { equals expected: true, actual: params.destroy } }

            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {fail_stage = "${STAGE_NAME}"}

                dir("${DIR_PATH}"){
                    sh 'pwd'
                    sh "terraform plan -input=false -out ${TF_PLAN}"
                    sh 'terraform show -no-color ${TF_PLAN} > ${TF_PLAN}.txt'
                    sh 'ls -al'
                }
            }
        }

        stage('Apply Approval') {
           when {
               not { equals expected: true, actual: params.autoApprove }
               not { equals expected: true, actual: params.destroy }
            }

           steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                    
                dir("${DIR_PATH}"){
                    script{
                        fail_stage = "${STAGE_NAME}"
                        def plan = readFile(file: "${TF_PLAN}.txt")

                        sh "sed -n '/^Plan/p' ${TF_PLAN}.txt > ${TF_APPLY_RESOURCE}.txt"
                        def apply = readFile(file: 'TF_APPLY_RESOURCE.txt')
                        slackSend(channel: SLACK_CHANNEL, color: '#00FF00', botUser: true, 
                            message: ":white_check_mark: Terraform plan Completed!\n :pushpin: Apply ${apply}")

                        input message: "Do you want to apply the plan?",
                        parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                    }
                }    
            }
        }

        stage('Apply') {
            when { not { equals expected: true, actual: params.destroy } }

            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                script {
                    fail_stage = "${STAGE_NAME}"
                    slackSend(channel: SLACK_CHANNEL, color: '#00FF00', botUser: true,
                                message: ":white_check_mark: Apply STARTED: Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' \n(${env.BUILD_URL})")
                    }

                dir("${DIR_PATH}"){
                    sh "terraform apply -input=false ${TF_PLAN}"
                    sh "terraform output > tfoutput.txt"
                    sh "ls -al"
                }
            }
        }

        stage('Apply Resource Output') {
            when { not { equals expected: true, actual: params.destroy } }

            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                dir("${DIR_PATH}"){
                    script {
                        def data = readFile(file: 'tfoutput.txt')
                        slackSend(channel: SLACK_CHANNEL, color: '#00FF00', message: ":printer: Terraform Apply Output \n ${data}")
                    }
                }
            }
        }

        stage('Destroy Approval') {
           when { equals expected: true, actual: params.destroy }

           steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                    
                dir("${DIR_PATH}"){
                    script{
                        fail_stage = "${STAGE_NAME}"

                        sh "terraform init"
                        sh "terraform plan -destroy -out=tfdestroy"
                        sh 'terraform show -no-color tfdestroy > tfdestroy.txt'
                        sh 'ls -al'

                        sh "sed -n '/^Plan/p' tfdestroy.txt > destroy_number.txt"
                        def destroy_number = readFile(file: 'destroy_number.txt')
                        slackSend(channel: SLACK_CHANNEL, color: '#00FF00', botUser: true,
                                message: ":white_check_mark: Destroy Resource Check!: Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]'\n :pushpin: Destroy ${destroy_number}\n(${env.BUILD_URL})")
                        
                        def destroy = readfile(file: 'tfdestroy.txt')
                        input message: "Do you want to apply the plan?",
                        parameters: [text(name: 'Plan', description: 'Please review the destroy', defaultValue: destroy)]
                    }
                }    
            }
        }

        stage('Destroy') {
            when { equals expected: true, actual: params.destroy }
            
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                dir("${DIR_PATH}"){
                    // sh "terraform init"
                    // sh "terraform plan -destroy -out=tfdestroy"
                    // sh 'terraform show -no-color tfdestroy > tfdestroy.txt'
                    // sh 'ls -al'

                    // script{
                    //     fail_stage = "${STAGE_NAME}"
                    //     sh "sed -n '/^Plan/p' tfdestroy.txt > destroy_number.txt"
                    //     def destroy_number = readFile(file: 'destroy_number.txt')
                    //     slackSend(channel: SLACK_CHANNEL, color: '#00FF00', botUser: true,
                    //             message: ":white_check_mark: Destroy STARTED!: Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]'\n :pushpin: Destroy ${destroy_number}\n(${env.BUILD_URL})")
                    // }
                    sh "terraform destroy --auto-approve"
                }
            }
        }

        stage('Send Slack Message') {
            steps {
                echo ">>>>>>>>>>>>>>> RUN Stage Name: ${STAGE_NAME}"
                // withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_DEPLOY_REGION}") {
                //     script {
                //         gitHash = GIT_HASH
                //         catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                //             gitHash = sh(returnStdout: true, script: "aws s3 cp --region ${AWS_DEPLOY_REGION} s3://${BUCKET_NAME}/${BUCKET_TYPE}/${SERVICE_NAME}/git_hash -").trim()
                //         }
                //         deploymentMessage = sh(returnStdout: true, script: getGitFormattedLog())
                //         sh "echo ${GIT_HASH} > git_hash"
                //         sh "aws s3 cp --region ${AWS_DEPLOY_REGION} ./git_hash s3://${BUCKET_NAME}/${BUCKET_TYPE}/${SERVICE_NAME}/git_hash"
                //     }
                // }
                script {
                    fail_stage = "${STAGE_NAME}"
                    gitHash = GIT_HASH
                    deploymentMessage = sh(returnStdout: true, script: getGitFormattedLog())
                    slackSend(channel: SLACK_CHANNEL, blocks: formatSlackMsg(deploymentMessage), botUser: true)
                    //slackSend(channel: SLACK_DEPLOY_CHANNEL, blocks: formatSlackMsg(deploymentMessage), botUser: true)
                }
            }
        }
    }
    post {
        failure {
            script {
                msg = ":x:Stage(${fail_stage}) FAILED:x: \n: Job '${env.JOB_NAME} [${BUILD_TAG}/#${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
                slackSend(channel: SLACK_CHANNEL, color: '#FF0000', message: msg)
                //slackSend(channel: SLACK_DEVOPS_CHANNEL, color: '#FF0000', message: msg)            
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
            text: 'Terraform Build Success:thumbsup:'
        ]
    ]
    arr << [
        type: 'divider',
    ]
    arr << [
        type: 'section',
        text: [
            type: 'plain_text',
            text: "${PROJECT_NAME} - ${BUILD_TAG} - ${currentBuild.number}"
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
