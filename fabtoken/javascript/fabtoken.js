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

const valid_operation_names = ['issue', 'transfer', 'redeem', 'list'];
const channel_name = "tokenchannel"

start();

async function start() {
	console.log('\n\n --- fabtoken.js - start');
	try {
		console.log('Setting up client side network objects');

		// fabric client instance
		// starting point for all interactions with the fabric network
		const fabric_client = new Fabric_Client();

		// -- channel instance to represent the ledger
		const channel = fabric_client.newChannel(channel_name);
		console.log(' Created client side object to represent the channel');

		// -- peer instance to represent a peer on the channel
		const peer = fabric_client.newPeer('grpc://localhost:7051');
		console.log(' Created client side object to represent the peer');

		// -- orderer instance to reprsent the channel's orderer
		const orderer = fabric_client.newOrderer('grpc://localhost:7050')
		console.log(' Created client side object to represent the orderer');

		// add peer and orderer to the channel
		channel.addPeer(peer);
		channel.addOrderer(orderer);

		// create users from existing crypto materials
		const {admin, user1, user2} = await createUsers();

		console.log('Successfully setup client side');
		console.log('\n\nStart processing token');

		let operation = null;
		let user = null;
		const args = [];
		if (process.argv.length >= 4) {
			operation = process.argv[2];
			if (process.argv[3] === 'user1') {
				user = user1;
			} else if (process.argv[3] === 'user2') {
				user = user2;
			} else {
				throw new Error(util.format('Invalid username "%s". Must be user1 or user2', process.argv[3]));
			}
			for (let i = 4; i < process.argv.length; i++) {
				if (process.argv[i]) {
					console.log(' Token arg: ' + process.argv[i]);
					args.push(process.argv[i]);
				}
			}
		} else {
			throw new Error('Missing required arguments: operation, user');
		}

		let result = null;
		switch (operation) {
			case 'issue':
				// admin issues tokens to the user as specified in args
				if (args.length < 2) {
					throw new Error('Missing required parameter for issue: token_type, quantity');
				}
				result = await issue(fabric_client, channel, admin, user, args);
				break;
			case 'transfer':
				// user transfers token to recipient
				if (args.length < 5) {
					throw new Error('Missing required parameters for transfer: recipient, transfer_quantity, remaining_quantity, tokenId_txid, tokenId_index');
				}
				let recipient
				if (args[0] === 'user1') {
					recipient = user1;
				} else if (args[0] === 'user2') {
					recipient = user2;
				} else {
					throw new Error(util.format('Invalid recipient "%s". Must be user1 or user2', process.argv[3]));
				}
				result = await transfer(fabric_client, channel, user, recipient, args);
				break;
			case 'redeem':
				// user redeems token
				if (args.length < 2) {
					throw new Error('Missing required parameter for redeem: quantity, tokenId_txid, tokenId_index');
				}
				result = await redeem(fabric_client, channel, user, args);
				break;
			case 'list':
				// user lists token
				result = await list(fabric_client, channel, user, user);
				break;
			default:
				throw new Error(' Unknown operation requested: ' + operation);
		}

		console.log('End token operation, returns %s', util.inspect(result, {depth: null}));

	} catch(error) {
		console.log('Problem with fabric token ::'+ error.toString());
	}
	console.log('\n\n --- fabtoken.js - end');
};

// admin issues token to user
async function issue(client, channel, admin, user, args) {
	console.log(' Start token issue with args ' + args);
	await client.setUserContext(admin, true);

	// build the request for admin to issue tokens to user - issue same quantity for 2 token types: USD and EURO
	const txId = client.newTransactionID();
	const param = {
		owner: {type: 0, raw: user.getIdentity().serialize()},
		type: args[0],
		quantity: args[1]
	};
	const request = {
		params: [param],
		txId: txId,
	};

	// admin issues tokens to user
	const tokenClient = client.newTokenClient(channel, 'localhost:7051');
	console.log('after newTokenClient');
	return await tokenClient.issue(request);
}

// user transfers token to recipient
async function transfer(client, channel, user, recipient, args) {
	console.log('Start token transfer with args ' + args);
	await client.setUserContext(user, true);

	// build the request for admin to issue tokens to user
	const txId = client.newTransactionID();
	const param1 = {
		owner: {type: 0, raw: recipient.getIdentity().serialize()},
		quantity: args[1]
	};
	let request = null;
	if (args[2] === '0') {
		request = {
			tokenIds: [{tx_id: args[3], index: parseInt(args[4])}],
			params: [param1],
			txId: txId,
		};
	} else {
		const param2 = {
			owner: {type: 0, raw: user.getIdentity().serialize()},
			quantity: args[2]
		};
		request = {
			tokenIds: [{tx_id: args[3], index: parseInt(args[4])}],
			params: [param1, param2],
			txId: txId,
		};
		
	}

	// admin issues tokens to user
	const tokenClient = client.newTokenClient(channel, 'localhost:7051');
	console.log('after newTokenClient');
	return await tokenClient.transfer(request);
}

// user transfers token to recipient
async function redeem(client, channel, user, args) {
	console.log('Start token redeem with args ' + args);
	await client.setUserContext(user, true);

	// build the request for admin to issue tokens to user
	const txId = client.newTransactionID();
	const param = {
		quantity: args[0]
	};
	const request = {
		tokenIds: [{tx_id: args[1], index: parseInt(args[2])}],
		params: [param],
		txId: txId,
	};

	// admin issues tokens to user
	const tokenClient = client.newTokenClient(channel, 'localhost:7051');
	console.log('after newTokenClient');
	return await tokenClient.redeem(request);
}

async function list(client, channel, user, args) {
	console.log('Start token issue with args ' + args);
	await client.setUserContext(user, true);
	console.log('after set user context')

	// admin issues tokens to user
	const tokenClient = client.newTokenClient(channel, 'localhost:7051');
	console.log('after newTokenClient');
	return await tokenClient.list();
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

// create admin, user1 and user2
async function createUsers() {

		// This sample application will read user idenitity information from
		// files and create users. It will use a client object as
		// an easy way to create the user objects from known cyrpto material.

		const client = new Fabric_Client();

		// load admin
		let keyPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore');
		let keyPEM = Buffer.from(readAllFiles(keyPath)[0]).toString();
		let certPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts');
		let certPEM = readAllFiles(certPath)[0];

		let user_opts = {
			username: 'admin',
			mspid: 'Org1MSP',
			skipPersistence: true,
			cryptoContent: {
				privateKeyPEM: keyPEM,
				signedCertPEM: certPEM
			}
		};
		const admin = await client.createUser(user_opts);

		// load user1
		keyPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore');
		keyPEM = Buffer.from(readAllFiles(keyPath)[0]).toString();
		certPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts');
		certPEM = readAllFiles(certPath)[0];

		user_opts = {
			username: 'user1',
			mspid: 'Org1MSP',
			skipPersistence: true,
			cryptoContent: {
				privateKeyPEM: keyPEM,
				signedCertPEM: certPEM
			}
		};
		const user1 = await client.createUser(user_opts);

		// load user2
		keyPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/User2@org1.example.com/msp/keystore');
		keyPEM = Buffer.from(readAllFiles(keyPath)[0]).toString();
		certPath = path.join(__dirname, '../../basic-network/crypto-config/peerOrganizations/org1.example.com/users/User2@org1.example.com/msp/signcerts');
		certPEM = readAllFiles(certPath)[0];

		user_opts = {
			username: 'user2',
			mspid: 'Org1MSP',
			skipPersistence: true,
			cryptoContent: {
				privateKeyPEM: keyPEM,
				signedCertPEM: certPEM
			}
		};
		const user2 = await client.createUser(user_opts);

		return {admin: admin, user1: user1, user2: user2};
}
