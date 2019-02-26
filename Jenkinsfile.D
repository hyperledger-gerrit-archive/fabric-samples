pipeline {

  /*
   * Example pipeline script for fabric-samples.
   */
  agent {
      label 'hyp-x'
  }

  options {
    timestamps()
  }

    def ROOTDIR = pwd() // workspace dir (/w/workspace/<job_name>
    def nodeHome = tool 'nodejs-8.11.3'
    def jobname = sh(returnStdout: true, script: 'echo ${JOB_NAME} | grep -q "verify" && echo patchset || echo merge').trim()
    def failure_stage = "none"

  environment {
    //Use Pipeline Utility Steps plugin to read information from pom.xml into env variables
    ARCH = "amd64"
    VERSION = sh(returnStdout: true, script: 'curl -O https://raw.githubusercontent.com/hyperledger/fabric/master/Makefile && cat Makefile | grep "BASE_VERSION =" | cut -d "=" -f2').trim()
    VERSION = "$VERSION" // BASE_VERSION from fabric Makefile
    BASE_IMAGE_VER = sh(returnStdout: true, script: 'cat Makefile | grep "BASEIMAGE_RELEASE =" | cut -d "=" -f2').trim() // BASEIMAGE Version from fabric Makefile
    IMAGE_TAG = "${ARCH}-${VERSION}-stable" // fabric latest stable version from nexus
    PROJECT_VERSION = "${VERSION}-stable"
    BASE_IMAGE_TAG = "${ARCH}-${BASE_IMAGE_VER}" //fabric baseimage version
    PROJECT_DIR = "gopath/src/github.com/hyperledger"
    GOPATH = "$WORKSPACE/gopath"
    PATH = "$GOPATH/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:${nodeHome}/bin:$PATH"
  }

  stages {
    stage('Fetch Patchset') { // fetch gerrit refspec on latest commit
      steps {
        try {
        if (jobname == "patchset")  {
          println "$GERRIT_REFSPEC"
          println "$GERRIT_BRANCH"
          checkout([
          $class: 'GitSCM',
          branches: [[name: '$GERRIT_REFSPEC']],
          extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'gopath/src/github.com/hyperledger/$PROJECT'], [$class: 'CheckoutOption', timeout: 10]],
          userRemoteConfigs: [[credentialsId: 'hyperledger-jobbuilder', name: 'origin', refspec: '$GERRIT_REFSPEC:$GERRIT_REFSPEC', url: '$GIT_BASE']]])
        } else {
          // Clone fabric-samples on merge
          println "Clone $PROJECT repository"
          checkout([
          $class: 'GitSCM',
          branches: [[name: 'refs/heads/$GERRIT_BRANCH']],
          extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'gopath/src/github.com/hyperledger/$PROJECT']],
          userRemoteConfigs: [[credentialsId: 'hyperledger-jobbuilder', name: 'origin', refspec: '+refs/heads/$GERRIT_BRANCH:refs/remotes/origin/$GERRIT_BRANCH', url: '$GIT_BASE']]])
        }
          dir("${ROOTDIR}/$PROJECT_DIR/$PROJECT") {
            sh '''
              # Print last two commit details
              echo
              git log -n2 --pretty=oneline --abbrev-commit
              echo
               '''
          }
        } catch (err) {
            failure_stage = "Fetch_Patchset"
            throw err
          }
      }
    }
    stage("Clean Environment - Get Env Info") {
      steps {
        try {
          dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
          sh './CI_Script.sh --clean_Environment --env_Info'
          }
        } catch (err) {
            failure_stage = "Clean Environment - Get Env Info"
            throw err
          }
      }
    }
    stage ("Pull third_party Images") {
      steps {
        wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          try {
            dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
            sh './CI_Script.sh --pull_Thirdparty_Images'
            }
          } catch (err) {
              failure_stage = "Pull_third_party_Images"
              throw err
            }
        }
      }
    }
    stage ("Pull Docker Images") {
      steps {
        wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          try {
            dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
            sh './CI_Script.sh --pull_Docker_Images'
            }
          } catch (err) {
              failure_stage = "Pull_Docker_Images"
              throw err
            }
        }
      }
    }
    stage ("Run byfn_eyfn Tests") {
      steps {
        wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          try {
            dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
            sh './CI_Script.sh --byfn_eyfn_Tests'
            }
          } catch (err) {
              failure_stage = "Run_byfn_eyfn_Tests"
              throw err
            }
        }
      }
    }
    stage ("Run FabCar Tests") {
      steps {
        wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          try {
            dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
            sh './CI_Script.sh --fabcar_Tests'
            }
          } catch (err) {
              failure_stage = "Run_FabCar_Tests"
              throw err
            }
        }
      }
    }
  }
    post {
      always {
        // we only worry about archiving the jar file if the build steps are successful
        archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true)
      }
      unstable {
        // notify users when the Pipeline fails
        rocketSend message: "Build Notification - STATUS: *${currentBuild.result}* - BRANCH: *${env.GERRIT_BRANCH}* - PROJECT: *${env.PROJECT}* - (<${env.BUILD_URL}|Open>)"
      }
      failure {
        // notify users when the Pipeline fails
        rocketSend message: "Build Notification - STATUS: *${currentBuild.result}* - BRANCH: *${env.GERRIT_BRANCH}* - PROJECT: *${env.PROJECT}* - (<${env.BUILD_URL}|Open>)"
      }
    }
}
