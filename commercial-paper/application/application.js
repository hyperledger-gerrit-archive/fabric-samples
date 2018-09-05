/*
SPDX-License-Identifier: Apache-2.0
*/

'use strict';

// Bring key classes into scope, most importantly Fabric SDK network class
const file = require("fs");
const yaml = require('js-yaml');
const { FileSystemWallet, Gateway } = require('fabric-network');
const { CommercialPaper } = require('./paper.js');

// A wallet stores a collection of identities for use
const wallet = new FileSystemWallet('./wallet');

// A gateway defines the peers used to access Fabric networks
const gateway = new Gateway();

// Main try/catch block
try {

  // Load connection profile; will be used to locate a gateway
  connectionProfile = yaml.safeLoad(file.readFileSync('./gateway/connectionProfile.yaml', 'utf8'));

  // Set connection options; use 'admin' identity from application wallet
  let connectionOptions = {
    identity: 'admin@digibank.com',
    wallet: wallet
  }

  // Connect to gateway using application specified parameters
  await gateway.connect(connectionProfile, connectionOptions);

  console.log('Connected to Fabric gateway.')

  // Get addressability to PaperNet network
  const network = await gateway.getNetwork('PaperNet');

  // Get addressability to commercial-paper contract
  const contract = await network.getContract('CommercialPaperContract');

  console.log('Submit commercial paper issue transaction.')

  // issue commercial paper

  const paper = await contract.submitTransaction('issue', 'MagnetoCorp', '00001', '2020-05-31', '2020-11-30', '5000000');

  let realPaper = CommercialPaper._deserialize(paper);

  console.log ('Paper Face Value= '+realPaper.faceValue);

  console.log('Transaction complete.')

} catch (error) {

  console.log(error);
  console.log('Unable to connect to Fabric gateway.')

} finally {

  // Disconnect from the gateway
  console.log('Disconnect from Fabric gateway.')
  gateway.disconnect();

}