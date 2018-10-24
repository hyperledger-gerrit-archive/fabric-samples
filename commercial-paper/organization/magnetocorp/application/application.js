/*
SPDX-License-Identifier: Apache-2.0
*/

/*
 * This application has 6 basic steps:
 * 1. Select an identity from a wallet
 * 2. Connect to network gateway
 * 3. Access PaperNet network
 * 4. Construct request to issue commercial paper
 * 5. Submit transaction
 * 6. Process response
 */

'use strict';

// Bring key classes into scope, most importantly Fabric SDK network class
const fs = require('fs');
const yaml = require('js-yaml');
const { FileSystemWallet, Gateway } = require('fabric-network');
const CommercialPaper = require('../contract/lib/paper.js');

// A wallet stores a collection of identities for use
//const wallet = new FileSystemWallet('../user/isabella/wallet');
const wallet = new FileSystemWallet('../identity/user/isabella/wallet');

// Main program function
async function main() {

  // A gateway defines the peers used to access Fabric networks
  const gateway = new Gateway();

  // Main try/catch block
  try {

    // Specify userName for network access
    // const userName = 'isabella.issuer@magnetocorp.com';
    const userName = 'User1@org1.example.com';

    // Load connection profile; will be used to locate a gateway
    let connectionProfile = yaml.safeLoad(fs.readFileSync('../gateway/networkConnection.yaml', 'utf8'));

    // Set connection options; identity and wallet
    let connectionOptions = {
      identity: userName,
      wallet: wallet
    };

    // Connect to gateway using application specified parameters
    await gateway.connect(connectionProfile, connectionOptions);

    console.log('Connected to Fabric gateway.');

    // Get addressability to PaperNet network
    const network = await gateway.getNetwork('mychannel');

    // Get addressability to commercial paper contract
    const contract = await network.getContract('papercontract', 'org.papernet.commercialpaper');

    console.log('Submit commercial paper issue transaction.');

    // issue commercial paper
    const issueResponse = await contract.submitTransaction('issue', 'MagnetoCorp', '00002', '2020-05-31', '2020-11-30', '5000000');

    let paper = CommercialPaper.fromBuffer(issueResponse);

    console.log(`${paper.issuer} commercial paper : ${paper.paperNumber} successfully issued for value ${paper.faceValue}`);
    console.log('Transaction complete.')

    console.log('Submit commercial paper buy transaction.');

    // buy commercial paper
    const buyResponse = await contract.submitTransaction('buy', 'MagnetoCorp', '00002', 'MagnetoCorp', 'DigiBank', '4900000', '2020-05-31');
    paper = CommercialPaper.fromBuffer(buyResponse);

    console.log(`${paper.issuer} commercial paper : ${paper.paperNumber} successfully purchased by ${paper.owner}`);
    console.log('Transaction complete.');

    console.log('Submit commercial paper redeem transaction.');

    // issue commercial paper
    const redeemResponse = await contract.submitTransaction('redeem', 'MagnetoCorp', '00002', 'DigiBank', '2020-11-30');
    paper = CommercialPaper.fromBuffer(redeemResponse);

    console.log(`${paper.issuer} commercial paper : ${paper.paperNumber} successfully redeemed`);
    console.log('Transaction complete.');

  } catch (error) {

    console.log(`Error processing transaction. ${error}`);
    console.log(error.stack);

  } finally {

    // Disconnect from the gateway
    console.log('Disconnect from Fabric gateway.')
    gateway.disconnect();

  }
}
main().then(() => {

  console.log('Main program complete');

}).catch((e) => {

  console.log('Main program exception');
  console.log(e);
  console.log(e.stack);
  process.exit(-1);

});