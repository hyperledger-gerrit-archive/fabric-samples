// Pipeline script for fabric-samples

node ('hyp-x') {
    def ROOTDIR = pwd()
    def failure_stage = "none"
      stage("Get Lastest Code") {
         if (params.cleanRun) {
              deleteDir()
         }
         sh '''
            [ -e gopath/src/github.com/hyperledger/fabric-samples ] || mkdir -p $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples
            '''
            dir('gopath/src/github.com/hyperledger/fabric-samples') {
            git changelog: false, poll: false, url: 'https://github.com/rameshthoomu/fabric-samples1.git'
            }
      }

// Pull Fabric Images
      stage("Pull fabric images") {
           try {
                 dir("${ROOTDIR}/gopath/src/github.com/hyperledger/fabric-samples/scripts/Jenkins_Scripts") {
                 sh './CI_Script.sh --build_Fabric_Images'
                 }
               }
           catch (err) {
                 failure_stage = "Pull fabric docker images"
                 throw err
                }
      }

 // Pull Fabric-ca
      stage("Pull fabric-ca images") {
           try {
                 dir("${ROOTDIR}/gopath/src/github.com/hyperledger/fabric-samples/scripts/Jenkins_Scripts") {
                 sh './CI_Script.sh --build_Fabric_CA_Image'
                 }
               }
           catch (err) {
                 failure_stage = "Pull fabric-ca docker image"
                 throw err
                 }
           }
// Run byfn, eyfn tests
         stage("Run byfn_eyfn Tests") {
              try {
                   dir("${ROOTDIR}/gopath/src/github.com/hyperledger/fabric-samples/scripts/Jenkins_Scripts") {
                   sh './CI_Script.sh --byfn_eyfn_Tests'
                   }
                  }
              catch (err) {
                  failure_stage = "byfn_eyfn_Tests"
                  throw err
              }
         }
  }
