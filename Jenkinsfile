pipeline {
    agent { label 'vm' }

    options {
        ansiColor('xterm')
    }

    environment {
        VERSION = "${BRANCH_NAME}-BETA"
        FTP_ADDR = '34.226.67.113'
    }

    parameters {
        booleanParam(
                name: 'BUILD',
                defaultValue: true,
                description: 'Build Nimbus Server VM'
        )

        booleanParam(
                name: 'PUSH',
                defaultValue: true,
                description: 'Push VM to S3'
        )

        booleanParam(
                name: 'PUSHEC2',
                defaultValue: true,
                description: 'Import VM into EC2'
        )

        text(
            name: 'RELEASE_VERSION',
            defaultValue: "",
            description: 'The Version to be Released'
        )
    }

    stages {
        stage('Preparing Pipeline') {
            steps {
                script {
                    if (params.RELEASE_VERSION == '')  {
                        RELEASE_VERSION=VERSION + "-" + currentBuild.number
                    } else {
                        RELEASE_VERSION=params.RELEASE_VERSION
                    }

                    echo RELEASE_VERSION

                    withCredentials([string(credentialsId: 'teams-webhook-url', variable: 'MS_URL')]) {
                        office365ConnectorSend(
                                color:  (currentBuild.previousBuild?.result == 'SUCCESS') ? '00FF00' : 'FF0000',
                                message: "Build ${currentBuild.displayName} triggered by ${currentBuild.buildCauses[0].shortDescription}",
                                webhookUrl: "${env.MS_URL}",
                                status: "Building"
                        )
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Base'){
            when {
                expression { params.BUILD }
            }
            steps {
                sh label: "Start Packer Build",
                        script: '''
                            export PATH=$PATH:/usr/local/packer
                            packer build -var version=${VERSION} -var memory=64000 -var cpus=16 -var headless=true -force -timestamp-ui nimbusserver.json
                    '''
                withCredentials([string(credentialsId: 'teams-webhook-url', variable: 'MS_URL')]) {
                    office365ConnectorSend(
                            color:  '00FF00',
                            message: "Build ${currentBuild.displayName}",
                            webhookUrl: "${env.MS_URL}",
                            status: "VMWare Build Complete"
                    )
                }
            }
        }

        stage('Push to S3') {
            when {
                expression { params.PUSH }
            }
            steps {
                withAWS(region:'us-east-1', credentials:'b6c88c9e-da69-4e09-bd1a-d73df8d5363a') {
                    s3Upload(bucket:"s3-adm-ftp", path:"nimbusserver-beta/${RELEASE_VERSION}/zip",  includePathPattern:'*.tar.gz', workingDir:'build')
                    s3Upload(bucket:"s3-adm-ftp", path:"nimbusserver-beta/${RELEASE_VERSION}/vmdk", includePathPattern:"disk.vmdk", workingDir:"build/nimbusserver-${VERSION}")
                }
            }
        }

        stage('Upload to EC2') {
            when {
                expression { params.PUSHEC2 }
            }
            steps {
                withAWS(region:'us-east-1', credentials:'b6c88c9e-da69-4e09-bd1a-d73df8d5363a') {
                    sh label: "Start VM Import to AWS", script: "ec2-conversion/aws_import_image.sh ${RELEASE_VERSION} $VERSION"
                }
            }
        }
    }
    post {
        always {
            withCredentials([string(credentialsId: 'teams-webhook-url', variable: 'MS_URL')]) {
                office365ConnectorSend(
                        color:  (currentBuild.currentResult == 'SUCCESS') ? '00FF00' : 'FF0000',
                        message: "Build ${currentBuild.displayName} *${currentBuild.currentResult}* in ${currentBuild.durationString.replaceAll(' and counting', '')}",
                        webhookUrl: "${env.MS_URL}",
                        status: "${currentBuild.currentResult}"
                )
            }
        }
    }
}
