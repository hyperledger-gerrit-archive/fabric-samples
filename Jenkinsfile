// Pipeline script for fabric-samples

node ('hyp-x') {
    def CI_SCRIPTS_DIR = env.WORKSPACE+ '/gopath/src/github.com/hyperledger'
    parameters {[
            string(name: 'PROJECT', defaultValue: 'fabric-samples'),
            string(name: 'GERRIT_BRANCH', defaultValue: 'master'),
            string(name: 'GERRIT_REFSPEC', defaultValue: ''),
    ]}
    def failure_stage = "none"
    try {
        sh 'mkdir -p ' + CI_SCRIPTS_DIR + ' && cd ' + CI_SCRIPTS_DIR

// Clean Environment
        stage("cleanEnv_outputEnv") {

            wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                try {
                    dir("${CI_SCRIPTS_DIR}/fabric-samples/scripts/Jenkins_Scripts") {
                    sh './CI_Script.sh --cleanEnvironment --env_Info'
                }
                }
                catch (err) {
                    failure_stage = "cleanEnvironment"
                    throw err
                }
            }
        }

// Clone fabric-samples
        stage('Clone fabric-samples repository') {
            try {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    sh 'env && echo "----> SCRIPT" ' + CI_SCRIPTS_DIR

                    if(env.GERRIT_REFSPEC && env.GERRIT_PATCHSET_REVISION) {
                        println "$GERRIT_REFSPEC" && println "$GERRIT_BRANCH"
                        sh 'cd ' + CI_SCRIPTS_DIR + ' && git clone git://cloud.hyperledger.org/mirror/fabric-samples && cd fabric-samples && git fetch origin $GERRIT_REFSPEC && git checkout FETCH_HEAD'
                    } else {
                        echo "------> Clone fabric-samples"
                        sh 'cd ' + CI_SCRIPTS_DIR + ' && git clone git://cloud.hyperledger.org/mirror/fabric-samples && cd fabric-samples && git fetch origin $GERRIT_REFSPEC && git checkout FETCH_HEAD'
                    }
                }
            }
            catch (err) {
                failure_stage = "clone_repo"
                throw err
            }
        }

// Build Fabric
        stage("Build fabric") {

            wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                try {
                    dir("${CI_SCRIPTS_DIR}/fabric-samples/scripts/Jenkins_Scripts") {
                    sh './CI_Script.sh --build_Fabric_Images'
                }
                }
                catch (err) {
                    failure_stage = "Build fabric docker images"
                    throw err
                }
            }
        }

 // Build Fabric-ca
        stage("Build fabric-ca") {

            wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                try {
                    dir("${CI_SCRIPTS_DIR}/fabric-samples/scripts/Jenkins_Scripts") {
                    sh './CI_Script.sh --build_Fabric_CA_Image'
                }
                }
                catch (err) {
                    failure_stage = "Build fabric-ca docker image"
                    throw err
                }
            }
        }

         stage("Run byfn_eyfn Tests") {
            
            wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) { 
                try {
                    dir("${CI_SCRIPTS_DIR}/fabric-samples/scripts/Jenkins_Scripts") {
                    sh './CI_Script.sh --byfn_eyfn_Tests'
                }
                }
                catch (err) {
                    failure_stage = "byfn_eyfn_Tests"
                    throw err
                }
           }
        }
                        
    }
                catch (err) {
                     failure_stage = "Build fabric"
                     throw err
                }
}
