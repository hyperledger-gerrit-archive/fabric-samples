#!groovy
// Copyright IBM Corp All Rights Reserved
//
// SPDX-License-Identifier: Apache-2.0
//

// Pipeline script for fabric-samples
@Library("fabric-ci-lib") _
  pipeline {
    agent {
      // Execute tests on x86_64 build nodes
      // Set this value from Jenkins Job Configuration
      label env.NODE_ARCH
    }
      options {
        // Using the Timestamper plugin we can add timestamps to the console log
        timestamps()
        // Set build timeout for 60 mins
        timeout(time: 60, unit: 'MINUTES')
      }
      environment {
        ROOTDIR = pwd()
        // Applicable only on x86_64 nodes
        nodeHome = tool 'nodejs-8.11.3'
        MARCH = sh(returnStdout: true, script: "uname -m | sed 's/x86_64/amd64/g'").trim()
        ARCH = sh(returnStdout: true, script: "uname -s|tr '[:upper:]' '[:lower:]'").trim()
        props = "null"
      }
      stages {
        stage('Clean Environment') {
          steps {
            script {
              // delete working directory
              deleteDir()
              // Clean build env before start the build
              fabBuildLibrary.cleanupEnv()
              // Display jenkins environment details
              fabBuildLibrary.envOutput()
            }
          }
        }
        stage('Checkout SCM') {
          steps {
            script {
              // Get changes from gerrit
              fabBuildLibrary.cloneRepo('fabric-samples')
              // Load properties from ci.properties file
              props = fabBuildLibrary.loadProperties()
              env.GOROOT = "/opt/go/go" + props["GO_VER"] + ".linux." + "$MARCH"
              env.GOPATH = "$WORKSPACE/gopath"
              env.PATH = "$GOROOT/bin:$GOPATH/bin:${nodeHome}/bin:$PATH"
              fabBuildLibrary.fabBuildImages('fabric', 'docker')
            }
          }
        }
        // Pull build artifacts
        stage('Pull Build Artifacts') {
          steps {
            script {
                if(props["SKIP_PULL_IMAGES"] == "true") {
                  println "SKIP: Pull Images from Nexus"
                  // call buildFabric to clone and build images
                  fabBuildLibrary.cloneScm('fabric', 'master')
                  env.GOROOT = "/opt/go/go" + props["GO_VER"] + ".linux." + "$MARCH"
                  env.PATH = "$GOROOT/bin:$GOPATH/bin:$PATH"
                  fabBuildLibrary.fabBuildImages('fabric', 'docker')
                } else {
                dir("$ROOTDIR/gopath/src/github.com/hyperledger") {
                  // Pull Binaries with latest version from nexus2
                  fabBuildLibrary.pullBinaries('latest', props["FAB_BINARY_REPO"])
                  // Pull Docker Images from nexus3
                  fabBuildLibrary.pullDockerImages(props["FAB_BASE_VERSION"], props["FAB_IMAGES_LIST"])
                  // Pull Thirdparty Docker Images from hyperledger DockerHub
                  fabBuildLibrary.pullThirdPartyImages(props["FAB_BASEIMAGE_VERSION"], props["FAB_THIRDPARTY_IMAGES_LIST"])
                }
                }
              }
            }
          }
        // Run byfn, eyfn tests (default, custom channel, couchdb, nodejs chaincode)
        stage('Run byfn_eyfn Tests') {
          steps {
            script {
              // making the output color coded
              wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                try {
                  dir("$ROOTDIR/$BASE_DIR/scripts/ci_scripts") {
                    sh './ciScript.sh --byfn_eyfn_Tests'
                  }
                }
                catch (err) {
                  failure_stage = "byfn_eyfn_Tests"
                  currentBuild.result = 'FAILURE'
                  throw err
                }
              }
            }
          }
        }
        // Run fabcar tests
        stage('Run Fab Car Tests') {
          steps {
            script {
              // making the output color coded
              wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                try {
                  dir("$ROOTDIR/$BASE_DIR/scripts/ci_scripts") {
                    sh './ciScript.sh --fabcar_Tests'
                  }
                }
                catch (err) {
                  failure_stage = "fabcar_Tests"
                  currentBuild.result = 'FAILURE'
                  throw err
                }
              }
            }
          }
        }
      } // stages
      post {
        always {
          // Archiving the .log files and ignore if empty
          archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
        }
        failure {
          script {
            if (env.JOB_TYPE == 'merge') {
              // Send rocketChat notification to channel
              // Send merge build failure email notifications to the submitter
              sendNotifications(currentBuild.result, props["CHANNEL_NAME"])
            }
          }
        }
      } // post
  } // pipeline
