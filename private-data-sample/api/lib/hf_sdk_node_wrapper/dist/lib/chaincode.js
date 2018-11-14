/*
* Copyright Persistent Systems 2018. All Rights Reserved.
*
* SPDX-License-Identifier: Apache-2.0
*/

"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const FabricClient = require("fabric-client");
const util = require("util");
const helper = require("./helper");
let networkConfig;
class ChaincodeHelper {
    constructor(config) {
        this.getInstantiatedChaincodes = getInstantiatedChaincodes;
        this.installChaincode = installChaincode;
        this.instantiateChaincode = instantiateChaincode;
        this.invokeChaincode = invokeChaincode;
        this.queryChaincode = queryChaincode;
        this.getBlockchainHeight = getBlockchainHeight;
        networkConfig = config;
    }
    static getInstance(config) {
        return this._instance || (this._instance = new this(config));
    }
}
exports.ChaincodeHelper = ChaincodeHelper;
const getInstantiatedChaincodes = (user, orgName, channelName, peer) => __awaiter(this, void 0, void 0, function* () {
    const errorMessage = null;
    try {
        const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
        const channel = fabricClient.getChannel(channelName, true);
        return yield channel.queryInstantiatedChaincodes(peer);
    }
    catch (err) {
        const message = util.format("Error while querying instatiated chaincodes %s", err);
        return new Error(message);
    }
});
const installChaincode = (user, orgName, chaincodePath, chaincodeId, chaincodeVersion, peers) => __awaiter(this, void 0, void 0, function* () {
    let errorMessage;
    try {
        const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
        const request = {
            targets: peers,
            chaincodePath: chaincodePath,
            chaincodeId: chaincodeId,
            chaincodeVersion: chaincodeVersion,
            txId: fabricClient.newTransactionID(true)
        };
        const results = yield fabricClient.installChaincode(request);
        const proposalResponses = results[0];
        const proposal = results[1];
        let allGood = true;
        for (const i in proposalResponses) {
            let oneGood = false;
            if (proposalResponses && proposalResponses[i].response &&
                proposalResponses[i].response.status === 200) {
                oneGood = true;
                console.info('install proposal was good');
            }
            else {
                console.error('install proposal was bad %j', proposalResponses);
            }
            allGood = allGood && oneGood;
        }
        if (allGood) {
            console.info('Successfully sent install Proposal and received ProposalResponse');
        }
        else {
            errorMessage = 'Failed to send install Proposal or receive valid response. Response null or status is not 200';
            console.error(errorMessage);
        }
    }
    catch (error) {
        console.error('Failed to install due to error: ' + error.stack ? error.stack : error);
        errorMessage = error.toString();
    }
    if (!errorMessage) {
        const message = util.format('Successfully installed chaincode');
        console.info(message);
        const response = {
            success: true,
            message: message
        };
        return response;
    }
    else {
        const message = util.format('Failed to install due to:%s', errorMessage);
        console.error(message);
        throw new Error(message);
    }
});
const instantiateChaincode = (user, orgName, peers, channelName, chaincodeName, chaincodeVersion, functionName, chaincodeType, args, endorsementPolicy) => __awaiter(this, void 0, void 0, function* () {
    let errorMessage = null;
    const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
    FabricClient.setConfigSetting('request-timeout', 20000);
    try {
        console.debug('Successfully got the fabric client for the organization "%s"', orgName);
        const channel = fabricClient.getChannel(channelName);
        if (!channel) {
            const message = util.format('Channel %s was not defined in the connection profile', channelName);
            console.error(message);
            throw new Error(message);
        }
        let targets;
        if (typeof peers == typeof Array()) {
            targets = channel.getPeers().filter((peer) => {
                return (peers.indexOf(peer.getName()) > -1);
            });
        }
        else {
            targets = peers;
        }
        const txId = fabricClient.newTransactionID(true);
        const deployId = txId.getTransactionID();
        const request = {
            targets: targets,
            chaincodeId: chaincodeName,
            chaincodeType: chaincodeType,
            chaincodeVersion: chaincodeVersion,
            args: args,
            txId: txId,
            fcn: "Init",
            endorsementPolicy: endorsementPolicy
        };
        if (functionName)
            request.fcn = functionName;
        const results = yield channel.sendInstantiateProposal(request, 60000);
        const proposalResponses = results[0];
        const proposal = results[1];
        let allGood = true;
        for (const i in proposalResponses) {
            let oneGood = false;
            if (proposalResponses && proposalResponses[i].response &&
                proposalResponses[i].response.status === 200) {
                oneGood = true;
                console.info('instantiate proposal was good');
            }
            else {
                console.error('instantiate proposal was bad');
            }
            allGood = allGood && oneGood;
        }
        if (allGood) {
            console.info(util.format('Successfully sent Proposal and received ProposalResponse: Status - %s, message - "%s", metadata - "%s", endorsement signature: %s', proposalResponses[0].response.status, proposalResponses[0].response.message, proposalResponses[0].response.payload, proposalResponses[0].endorsement.signature));
            const promises = [];
            const eventHubs = channel.getChannelEventHubsForOrg();
            console.debug('found %s eventhubs for this organization %s', eventHubs.length, orgName);
            eventHubs.forEach((eh) => {
                const instantiateEventPromise = new Promise((resolve, reject) => {
                    console.debug('instantiateEventPromise - setting up event');
                    const event_timeout = setTimeout(() => {
                        const message = 'REQUEST_TIMEOUT:' + eh.getPeerAddr();
                        console.error(message);
                        eh.disconnect();
                    }, 60000);
                    eh.registerTxEvent(deployId, (tx, code, block_num) => {
                        console.info('The chaincode instantiate transaction has been committed on peer %s', eh.getPeerAddr());
                        console.info('Transaction %s has status of %s in blocl %s', tx, code, block_num);
                        clearTimeout(event_timeout);
                        if (code !== 'VALID') {
                            const message = util.format('The chaincode instantiate transaction was invalid, code:%s', code);
                            console.error(message);
                            reject(new Error(message));
                        }
                        else {
                            const message = 'The chaincode instantiate transaction was valid.';
                            console.info(message);
                            resolve(message);
                        }
                    }, (err) => {
                        clearTimeout(event_timeout);
                        console.error(err);
                        reject(err);
                    }, { unregister: true, disconnect: true });
                    eh.connect();
                });
                promises.push(instantiateEventPromise);
            });
            const ordererRequest = {
                txId: txId,
                proposalResponses: proposalResponses,
                proposal: proposal
            };
            const sendPromise = channel.sendTransaction(ordererRequest);
            promises.push(sendPromise);
            const results = yield Promise.all(promises);
            console.debug(util.format('------->>> R E S P O N S E : %j', results));
            const response = results.pop();
            if (response.status === 'SUCCESS') {
                console.info('Successfully sent transaction to the orderer.');
            }
            else {
                errorMessage = util.format('Failed to order the transaction. Error code: %s', response.status);
                console.debug(errorMessage);
            }
            for (const i in results) {
                const eventHubResult = results[i];
                const eventHub = eventHubs[i];
                console.debug('Event results for event hub :%s', eventHub.getPeerAddr());
                if (typeof eventHubResult === 'string') {
                    console.debug(eventHubResult);
                }
                else {
                    if (!errorMessage)
                        errorMessage = eventHubResult.toString();
                    console.debug(eventHubResult.toString());
                }
            }
        }
        else {
            errorMessage = util.format('Failed to send Proposal and receive all good ProposalResponse');
            console.debug(errorMessage);
        }
    }
    catch (error) {
        console.error('Failed to send instantiate due to error: ' + error.stack ? error.stack : error);
        errorMessage = error.toString();
    }
    if (!errorMessage) {
        const message = util.format('Successfully instantiated chaincode in organization %s to the channel \'%s\'', orgName, channelName);
        console.info(message);
        const response = {
            success: true,
            message: message
        };
        return response;
    }
    else {
        const message = util.format('Failed to instantiate. cause:%s', errorMessage);
        console.error(message);
        throw new Error(message);
    }
});
const invokeChaincode = (user, orgName, channelName, chaincodeId, fcn, args, peers, transientData) => __awaiter(this, void 0, void 0, function* () {
    let txIdString;
    let errorMessage = null;
    let eventHubs;
    try {
        const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
        const channel = fabricClient.getChannel(channelName);
        if (!channel) {
            const message = util.format('Channel %s was not defined in the connection profile', channelName);
            console.error(message);
            throw new Error(message);
        }
        let targets;
        if (typeof peers == typeof Array()) {
            targets = channel.getPeers().filter((peer) => {
                return (peers.indexOf(peer.getName()) > -1);
            });
        }
        else {
            targets = peers;
        }
        const txId = fabricClient.newTransactionID();
        txIdString = txId.getTransactionID();
        const request = {
            targets: targets,
            chaincodeId: chaincodeId,
            fcn: fcn,
            args: args,
            chainId: channelName,
            txId: txId,
	    transientMap: transientData
        };
        const results = yield channel.sendTransactionProposal(request);
        var proposalResponses = results[0];
        const proposal = results[1];
        let allGood = true;
        for (const i in proposalResponses) {
            let oneGood = false;
            if (proposalResponses && proposalResponses[i].response &&
                proposalResponses[i].response.status === 200) {
                oneGood = true;
                console.info('invoke chaincode proposal was good');
            }
            else {
                console.error('invoke chaincode proposal was bad');
            }
            allGood = allGood && oneGood;
        }
        if (allGood) {
            console.info(util.format('Successfully sent Proposal and received ProposalResponse: Status - %s, message - "%s", metadata - "%s", endorsement signature: %s', proposalResponses[0].response.status, proposalResponses[0].response.message, proposalResponses[0].response.payload, proposalResponses[0].endorsement.signature));
            const promises = [];
            eventHubs = channel.getChannelEventHubsForOrg();
            eventHubs.forEach((eh) => {
                console.debug('invokeEventPromise - setting up event');
                const invokeEventPromise = new Promise((resolve, reject) => {
                    const event_timeout = setTimeout(() => {
                        const message = 'REQUEST_TIMEOUT:' + eh.getPeerAddr();
                        console.error(message);
                        eh.disconnect();
                    }, 30000);
                    eh.registerTxEvent(txIdString, (tx, code, block_num) => {
                        console.info('The chaincode invoke chaincode transaction has been committed on peer %s', eh.getPeerAddr());
                        console.info('Transaction %s has status of %s in block %s', tx, code, block_num);
                        clearTimeout(event_timeout);
                        if (code !== 'VALID') {
                            const message = util.format('The invoke chaincode transaction was invalid, code:%s', code);
                            console.error(message);
                            reject(new Error(message));
                        }
                        else {
                            const message = 'The invoke chaincode transaction was valid.';
                            console.info(message);
                            resolve(message);
                        }
                    }, (err) => {
                        clearTimeout(event_timeout);
                        console.error(err);
                        reject(err);
                    }, { unregister: true, disconnect: true });
                    eh.connect();
                });
                promises.push(invokeEventPromise);
            });
            const ordererRequest = {
                txId: txId,
                proposalResponses: proposalResponses,
                proposal: proposal
            };
            const sendPromise = channel.sendTransaction(ordererRequest);
            promises.push(sendPromise);
            const results = yield Promise.all(promises);
            console.debug(util.format('------->>> R E S P O N S E : %j', results));
            const response = results.pop();
            if (response.status === 'SUCCESS') {
                console.info('Successfully sent transaction to the orderer.');
            }
            else {
                errorMessage = util.format('Failed to order the transaction. Error code: %s', response.status);
                console.debug(errorMessage);
            }
            for (const i in results) {
                const eventHubResult = results[i];
                const eventHub = eventHubs[i];
                console.debug('Event results for event hub :%s', eventHub.getPeerAddr());
                if (typeof eventHubResult === 'string') {
                    console.debug(eventHubResult);
                }
                else {
                    if (!errorMessage)
                        errorMessage = eventHubResult.toString();
                    console.debug(eventHubResult.toString());
                }
            }
        }
        else {
            errorMessage = util.format('Failed to send Proposal and receive all good ProposalResponse');
            console.debug(errorMessage);
        }
    }
    catch (error) {
        console.error('Failed to invoke due to error: ' + error.stack ? error.stack : error);
        errorMessage = error.toString();
    }
    if (!errorMessage) {
        const message = util.format('Successfully invoked the chaincode %s to the channel \'%s\' for transaction ID: %s', orgName, channelName, txIdString);
        console.info(message);
//        return txIdString; proposalResponses[0].response.payload.toString('utf8');
	return proposalResponses[0].response.payload.toString('utf8');
    }
    else {
        const message = util.format('Failed to invoke chaincode. cause:%s', errorMessage);
        console.error(message);
        throw new Error(message);
    }
});
const queryChaincode = (user, orgName, channelName, chaincodeId, fcn, args, peers) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
        const channel = yield fabricClient.getChannel(channelName, true);
        if (!channel) {
            const message = util.format('Channel %s was not defined in the connection profile', channelName);
            console.error(message);
            throw new Error(message);
        }
        let targets;
        if (typeof peers == typeof Array()) {
            targets = channel.getPeers().filter((peer) => {
                return (peers.indexOf(peer.getName()) > -1);
            });
        }
        else {
            targets = peers;
        }
        const request = {
            chaincodeId: chaincodeId,
            fcn: fcn,
            args: args,
            targets: targets
        };
        return yield channel.queryByChaincode(request);
    }
    catch (err) {
        const message = util.format("Error while querying chaincode: %s", err);
        return new Error(message);
    }
});
const getBlockchainHeight = (user, orgName, channelName, peer) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
        const channel = fabricClient.getChannel(channelName, false);
        return yield channel.queryInfo(peer, false);
    }
    catch (err) {
        const message = util.format("Error while calling channel.queryInfo: %s", err);
        return new Error(message);
    }
});
//# sourceMappingURL=chaincode.js.map
