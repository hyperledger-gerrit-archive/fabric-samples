/*
SPDX-License-Identifier: Apache-2.0
*/

'use strict';

// Bring key classes into scope, most importantly Fabric SDK network class
const fs = require('fs');
const { FileSystemWallet, X509WalletMixin } = require('fabric-network');
const path = require('path');

const fixtures = path.resolve(__dirname,'../../infrastructure/basic-network');

// A wallet stores a collection of identities for use
const wallet = new FileSystemWallet('./_idwallet');

async function main(){

    // Main try/catch block
    try {

        // define the identity to use
        const credPath = path.join(fixtures , '/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com');
        const cert = fs.readFileSync(path.join(credPath , '/msp/signcerts/User1@org1.example.com-cert.pem')).toString();
        const key = fs.readFileSync(path.join(credPath , '/msp/keystore/00e4975ef7cb7558f7896384aa59327575242c0a8527948a5ba3cbc397b8172b_sk')).toString();
        const identityLabel = 'User1@org1.example.com';

        // prep wallet and test it at the same time
        await wallet.import(identityLabel, X509WalletMixin.createIdentity('Org1MSP', cert, key));

    } catch (error) {
        console.log(`Error adding to wallet. ${error}`);
        console.log(error.stack);
    }
}

main().then(()=>{
    console.log('done');
}).catch((e)=>{
    console.log(e);
    console.log(e.stack);
    process.exit(-1);
});
