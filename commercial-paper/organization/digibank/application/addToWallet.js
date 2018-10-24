/*
 *  SPDX-License-Identifier: Apache-2.0
 */

'use strict';

// Bring key classes into scope, most importantly Fabric SDK network class
const fs = require('fs');
const { FileSystemWallet, X509WalletMixin } = require('fabric-network');
const path = require('path');

const fixtures = path.resolve(__dirname, '../../../../basic-network');

// A wallet stores a collection of identities
const wallet = new FileSystemWallet('../identity/user/balaji/wallet');

async function main() {

    // Main try/catch block
    try {

        // Identity to credentials to be stored in the wallet
        //        const credPath = path.join(fixtures, 'papernet/organization/magnetocorp/users/isabella.issuer@magnetocorp.com');
        //        const cert = fs.readFileSync(path.join(credPath, '/msp/signcerts/isabella.issuer@magnetocorp.com-cert.pem')).toString();
        //        const key = fs.readFileSync(path.join(credPath, '/msp/keystore/c75bd6911aca808941c3557ee7c97e90f3952e379497dc55eb903f31b50abc83_sk')).toString();
        //        const identityLabel = 'isabella.issuer@magnetcorp.com';
        const credPath = path.join(fixtures, '/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com');
        const cert = fs.readFileSync(path.join(credPath, '/msp/signcerts/Admin@org1.example.com-cert.pem')).toString();
        const key = fs.readFileSync(path.join(credPath, '/msp/keystore/cd96d5260ad4757551ed4a5a991e62130f8008a0bf996e4e4b84cd097a747fec_sk')).toString();
        const identityLabel = 'Admin@org1.example.com';

        // Load credentials into wallet
        // await wallet.import(identityLabel, X509WalletMixin.createIdentity('magnetocorp', cert, key));
        await wallet.import(identityLabel, X509WalletMixin.createIdentity('Org1MSP', cert, key));

    } catch (error) {
        console.log(`Error adding to wallet. ${error}`);
        console.log(error.stack);
    }
}

main().then(() => {
    console.log('done');
}).catch((e) => {
    console.log(e);
    console.log(e.stack);
    process.exit(-1);
});