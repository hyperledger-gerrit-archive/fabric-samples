// Copyright IBM Corp All Rights Reserved
//
// SPDX-License-Identifier: Apache-2.0
//

// Pipeline script for fabric-samples

node ('hyp-x') { // trigger build on x86_64 node
  timestamps {
   try {
    def ROOTDIR = pwd() // workspace dir (/w/workspace/<job_name>
    env.NODE_VER = "8.11.3"
    env.GO_VER = "1.10.4"
    env.VERSION = "1.3.0"
    env.PROJECT_DIR = "$WORKSPACE/gopath/src/github.com/hyperledger"
    env.GOPATH = "$WORKSPACE/gopath"
    env.GOROOT = "/opt/go${GO_VER}.linux.amd64"
    env.PATH = "$GOPATH/bin:$GOROOT/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:~/npm/bin:/home/jenkins/.nvm/versions/node/v${NODE_VER}/bin:$PATH"
    def failure_stage = "none"
    // delete working directory
    deleteDir()
      stage("Fetch Patchset") { // fetch gerrit refspec on latest commit
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          try {
              dir("${ROOTDIR}") {
              sh '''
                 [ -e gopath/src/github.com/hyperledger/fabric-samples ] || mkdir -p $PROJECT_DIR
                 cd $PROJECT_DIR
                 git clone git://cloud.hyperledger.org/mirror/fabric-samples && cd fabric-samples
                 git fetch origin "$GERRIT_REFSPEC" && git checkout FETCH_HEAD
              '''
              }
          }
          catch (err) {
                 failure_stage = "Fetch patchset"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }
// clean environment and get env data
      stage("Cleanup Env") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
                 sh './CI_Script.sh --clean_Environment --env_Info'
                 }
               }
           catch (err) {
                 failure_stage = "Clean Environment - Get Env Info"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }


    // Pull Fabric Images
      stage("Pull third_party images") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
                 sh './CI_Script.sh --pull_Thirdparty_Images'
                 }
               }
           catch (err) {
                 failure_stage = "Pull third_party docker images"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }

// Pull Docker Images
      stage("Pull Docker images") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
                 sh './CI_Script.sh --pull_Fabric_Images --pull_Fabric_CA_Image'
                 }
               }
           catch (err) {
                 failure_stage = "Pull fabric and fabric-ca docker images"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }

// Run byfn, eyfn tests (default, custom channel, couchdb, nodejs chaincode, fabric-ca samples)
      stage("Run byfn_eyfn Tests") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
                 sh './CI_Script.sh --byfn_eyfn_Tests'
                 }
               }
           catch (err) {
                 failure_stage = "byfn_eyfn_Tests"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }
      } finally {
           archiveArtifacts allowEmptyArchive: true, artifacts: '**/*.log'
           // Sends notification to Rocket.Chat
           if (currentBuild.result == 'FAILURE' && env.GERRIT_EVENT_TYPE == 'change-merged')  { // Other values: SUCCESS, UNSTABLE
               rocketSend channel: 'jenkins-robot', message: "Build Notification - STATUS: ${currentBuild.result} - BRANCH: ${env.GERRIT_BRANCH} - PROJECT: ${env.PROJECT} - (<${env.BUILD_URL}|Open>)"
           }
        }
// try end here
  }
// node end here
}
