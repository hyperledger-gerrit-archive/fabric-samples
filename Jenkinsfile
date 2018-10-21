// Copyright IBM Corp All Rights Reserved
//
// SPDX-License-Identifier: Apache-2.0
//

// Pipeline script for fabric-samples

node ('hyp-x') { // trigger build on x86_64 node
  timestamps {
   try {
    def ROOTDIR = pwd() // workspace dir (/w/workspace/<job_name>
    env.PROJECT_DIR = "gopath/src/github.com/hyperledger"
    env.NODE_VER = "8.11.3"
    env.GO_VER = "1.10.4"
    env.PROJECT_DIR = "gopath/src/github.com/hyperledger"
    env.GOPATH = "$WORKSPACE/gopath"
    env.GOROOT = "/opt/go${GO_VER}.linux.amd64"
    env.PATH = "$GOPATH/bin:$GOROOT/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:~/npm/bin:/home/jenkins/.nvm/versions/node/v${NODE_VER}/bin:$PATH"
    def failure_stage = "none"
    // delete working directory
    deleteDir()
      stage("Fetch Patchset") { // fetch gerrit refspec on latest commit
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          try {
              dir("${ROOTDIR}"){
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
                 throw err
           }
         }
      }
// clean environment and get env data
      stage("Clean Environment - Get Env Info") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-samples/scripts/Jenkins_Scripts") {
                 sh './CI_Script.sh --clean_Environment --env_Info'
                 }
               }
           catch (err) {
                 failure_stage = "Clean Environment - Get Env Info"
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
                 throw err
           }
         }
      }
      
      } finally {
           junit '**/cobertura-coverage.xml'
           step([$class: 'CoberturaPublisher', autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: '**/cobertura-coverage.xml', failUnhealthy: false, failUnstable: false, maxNumberOfBuilds: 0, onlyStable: false, sourceEncoding: 'ASCII', zoomCoverageChart: false])
           archiveArtifacts artifacts: '**/*.log'
           // Sends notification to Rocket.Chat
           rocketSend channel: 'jenkins-robot', message: "Build Notification - Branch: ${env.GERRIT_BRANCH} - Project: ${env.PROJECT} - (<${env.BUILD_URL}|Open>)"
        }
  }
}
