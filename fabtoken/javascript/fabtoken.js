'use strict';
/*
* Copyright IBM Corp All Rights Reserved
*
* SPDX-License-Identifier: Apache-2.0
*/
/*
 * Chaincode Invoke
 */

const Fabric_Client = require('fabric-client');
const path = require('path');
const util = require('util');
const os = require('os');
const fs = require('fs-extra');

start();

async function start() {
	console.log('\n\n --- fabtoken.js - start');
	try {
		console.log('Setting up client side network objects');
		// fabric client instance
		// starting point for all interactions with the fabric network
		const fabric_client = new Fabric_Client();

		// setup the fabric network
		// -- channel instance to represent the ledger named "mychannel"
		const channel = fabric_client.newChannel('mychannel');
		console.log('Created client side object to represent the channel');
		// -- peer instance to represent a peer on the channel
		const peer = fabric_client.newPeer('grpc://localhost:7051');
		console.log('Created client side object to represent the peer');
		// -- orderer instance to reprsent the channel's orderer
		const orderer = fabric_client.newOrderer('grpc://localhost:7050')
		console.log('Created client side object to represent the orderer');

		// create the user identity from existing crypto material
		const {user1, admin} = await createUsers();

		console.log('Successfully setup client side');
		console.log('\n\nStart processing');

		let operation = null;
		const args = [];
		if (process.argv.length > 2) {
			if (process.argv[2]) {
				operation = process.argv[2];
				console.log(' Token operation: ' + operation);
			}
			for (let i = 3; i < process.argv.length; i++) {
				if (process.argv[i]) {
					console.log(' Token arg: ' + process.argv[i]);
					args.push(process.argv[i]);
				}
			}
		} else {
			throw new Error(' NO operation requested ');
		}

		switch (operation) {
			case 'issue':
				issue(fabric_client, channel, admin, user1, null, args);
				break;
			case 'move':
				//
				break;
			case 'query':
				//
				break;
			default:
				throw new Error(' Unknown operation requested: ' + operation);
		}

	} catch(error) {
		console.log('Problem with fabric token ::'+ error.toString());
	}
	console.log('\n\n --- fabtoken.js - end');
};

async function issue(client, channel, admin, user1, user2, args) {
	console.log('Start token issue with args ' + args);
	await client.setUserContext(admin, true);


	console.log('End token issue');
}

function readAllFiles(dir) {
	const files = fs.readdirSync(dir);
	const certs = [];
	files.forEach((file_name) => {
		const file_path = path.join(dir, file_name);
		const data = fs.readFileSync(file_path);
		certs.push(data);
	});
	return certs;
}

async function createUsers() {

		// This sample application will read user idenitity information from
		// files and create users. It will use a client object as
		// an easy way to create the user objects from known cyrpto material.

		const client = new Fabric_Client();

		// first load user1
		let keyPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore');
		let keyPEM = Buffer.from(readAllFiles(keyPath)[0]).toString();
		let certPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts');
		let certPEM = readAllFiles(certPath)[0];

		let user_opts = {
			username: 'user1',
			mspid: 'org1',
			skipPersistence: true,
			cryptoContent: {
				privateKeyPEM: keyPEM,
				signedCertPEM: certPEM
			}
		};
		const user1 = await client.createUser(user_opts);

		// first load user1
		keyPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore');
		keyPEM = Buffer.from(readAllFiles(keyPath)[0]).toString();
		certPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts');
		certPEM = readAllFiles(certPath)[0];

		user_opts = {
			username: 'admin',
			mspid: 'org1',
			skipPersistence: true,
			cryptoContent: {
				privateKeyPEM: keyPEM,
				signedCertPEM: certPEM
			}
		};
		const admin = await client.createUser(user_opts);

		return {user1: user1, admin: admin};
}
