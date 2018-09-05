/*
SPDX-License-Identifier: Apache-2.0
*/

'use strict';

// Bring key Fabric SDK classes into scope
const {Gateway, FileSystemWallet} = require('fabric-network');

// A wallet stores a collection of identities for use
const wallet = new FileSystemWallet('./WALLETS/wallet');

// A gateway defines the peers used to access Fabric networks
const gateway = new Gateway();

// Main try/catch block
try {

  // Connect to network using 'admin' identity
  await gateway.connect(ccp, {
    identity: 'admin',
    wallet: wallet
  });

  console.log('Connected to Fabric gateway.')

  // Get addressability to PaperNet network
  const network = await gateway.getNetwork('PaperNet');

  // Get addressability to commercial-paper contract
  const contract = await network.getContract('CommercialPaperContract');

  console.log('Submit commercial paper issue transaction.')

  // issue commercial paper
  const paper = await contract.submitTransaction('issue', 'MagnetoCorp', '00001', '2020-05-31', '2020-11-30', '5000000');

  console.log('Transaction complete.')

} catch(error) {

  console.log(error);
  console.log('Unable to connect to Fabric gateway.')

} finally {

    // Disconnect from the gateway
    console.log('Disconnect from Fabric gateway.')
    gateway.disconnect();

}