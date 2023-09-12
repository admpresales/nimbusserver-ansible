@Library("nimbus-pipeline-library") _

pipeline {
    agent { label 'vm' }

    options {
        ansiColor('xterm')
    }

    environment {
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
                    if (params.RELEASE_VERSION) {
                        VERSION=params.RELEASE_VERSION
                        RELEASE_VERSION=VERSION
                    } else {
                        VERSION = "${BRANCH_NAME}-BETA"
                        RELEASE_VERSION=VERSION + "-" + currentBuild.number
                    }

                    echo "VERSION: ${VERSION}"
                    echo "RELEASE_VERSION: ${RELEASE_VERSION}"

                    notifyStart()
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
                echo "VERSION: ${VERSION}"
                echo "RELEASE_VERSION: ${RELEASE_VERSION}"

                withCredentials([string(credentialsId: 'mf-te-registration', variable: 'MF_TE')]) {
                    sh label: "Start Packer Build",
                       script: """
                            rm -rf build
                            export PATH=\$PATH:/usr/local/packer
                            packer build -var version=${VERSION} -var "registration_code=${MF_TE}" -var memory=64000 -var cpus=16 -var headless=true -force -timestamp-ui packer-base.json
                            packer build -var version=${VERSION} -var "registration_code=${MF_TE}" -var memory=64000 -var cpus=16 -var headless=true -force -timestamp-ui packer-setup.json
                        """
                }
                sendNotification(
                    color: '#00FF00',
                    message: "Build ${currentBuild.displayName}",
                    stauts: "VMWare Build Complete"
                )
            }
        }

        stage('Convert and Upload') {
            when {
                expression { params.PUSH }
            }
            steps {
                sh label: "Run ovftool", script: """
                    cd build
                    time ovftool --overwrite nimbusserver-${VERSION}/nimbusserver-${VERSION}.vmx nimbusserver-${VERSION}/disk.vmdk &
                    time 7z a nimbusserver-${VERSION}.7z -v2G -m0=lzma2 -mx=5 -mmt=8 -y nimbusserver-${VERSION} &
                    wait
                """

                sh label "Create VHDX file for Azure", script: """
                    cd build
                    time qemu-img convert nimbusserver-${VERSION}/disk-disk1.vmdk -O vhdx nimbusserver-${VERSION}-disk1.vhdx -p
                """

                sh label "Compress VHDX", script: """
                    cd build
                    time 7z a nimbusserver-${VERSION}-vhdx.7z -v2G -m0=lzma2 -mx=5 -mmt=8 -y nimbusserver-${VERSION}-disk1.vhdx
                """

                withAWS(region: 'us-east-1', credentials: 'nimbusbuild-aws') {
                    s3Upload(bucket:"s3-adm-ftp", path:"nimbusserver-beta/${RELEASE_VERSION}/zip",  includePathPattern:'*.7z*', workingDir:'build')
                    s3Upload(bucket:"s3-adm-ftp", path:"nimbusserver-beta/${RELEASE_VERSION}/vmdk", includePathPattern:"disk-disk1.vmdk", workingDir:"build/nimbusserver-${VERSION}")
                }
            }
        }

        stage('Upload to EC2') {
            when {
                expression { params.PUSHEC2 }
            }
            steps {
                withAWS(region: 'us-east-1', credentials: 'nimbusbuild-aws') {
                    awsImportVMDK(
                        tag: "nimbusserver-${RELEASE_VERSION}",
                        bucket: "s3-adm-ftp",
                        key: "nimbusserver-beta/${RELEASE_VERSION}/vmdk/disk-disk1.vmdk"
                    )
                }
            }
        }

        stage('Upload to FTP') {
            when {
                expression { params.PUSH }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'mf-ftp-host', variable: 'FTP_HOST'),
                    usernamePassword(credentialsId: 'ftp-adm-te', passwordVariable: 'FTP_PASS', usernameVariable: 'FTP_USER'),
                    usernamePassword(credentialsId: 'mf-partner-ftp', passwordVariable: 'PARTNER_PASS', usernameVariable: 'PARTNER_USER'),
                ]) {
                    sh label: 'FTP Upload', script: '''
                    cd build
                    for f in *.7z*
                    do
                        echo "Uploading $f"
                        time curl -T "$f" "ftp://${FTP_HOST}/Nimbus/nimbusserver-${RELEASE_VERSION}/" --ftp-create-dirs --user "${FTP_USER}:${FTP_PASS}"
                        time curl -T "$f" "ftp://${FTP_HOST}/Nimbus/nimbusserver-${RELEASE_VERSION}/" --ftp-create-dirs --user "${PARTNER_USER}:${PARTNER_PASS}"
                    done
                    '''
                }
            }
        }
    }
    post {
        always {
            notifyComplete()
        }
    }
}
