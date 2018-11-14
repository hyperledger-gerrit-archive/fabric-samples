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
const fs = require("fs");
const util = require("util");
const helper = require("./helper");
let networkConfig;
class ChannelHelper {
    constructor(config) {
        this.createChannel = createChannel;
        this.joinChannel = joinChannel;
        this.getAllChannels = getAllChannels;
        this.getChannelConfig = getChannelConfig;
        networkConfig = config;
    }
    static getInstance(config) {
        return this._instance || (this._instance = new this(config));
    }
}
exports.ChannelHelper = ChannelHelper;
const createChannel = (user, orgName, channelName, pathToChannelFile, ordererName) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
        const envelope_bytes = fs.readFileSync(pathToChannelFile);
        const config = fabricClient.extractChannelConfig(envelope_bytes);
        const signature = fabricClient.signChannelConfig(config);
        const txId = fabricClient.newTransactionID(true);
        const request = {
            config: config,
            signatures: [signature],
            name: channelName,
            txId: txId,
            orderer: null
        };
        if (ordererName) {
            request.orderer = ordererName;
        }
        const response = yield fabricClient.createChannel(request);
        console.debug(' response ::%j', response);
        if (response && response.status === 'SUCCESS') {
            console.debug('Successfully created the channel.');
            const response = {
                success: true,
                message: 'Channel \'' + channelName + '\' created Successfully'
            };
            return response;
        }
        else {
            console.error('\n!!!!!!!!! Failed to create the channel \'' + channelName +
                '\' !!!!!!!!!\n\n');
            throw new Error('Failed to create the channel \'' + channelName + '\'');
        }
    }
    catch (err) {
        console.error('Failed to initialize the channel: ' + err.stack ? err.stack : err);
        throw new Error('Failed to initialize the channel: ' + err.toString());
    }
});
const getAllChannels = (user, orgName, peer) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
        return yield fabricClient.queryChannels(peer);
    }
    catch (err) {
        const message = util.format("Got error during client.queryChannels() %s", err);
        return new Error(message);
    }
});
const getChannelConfig = (user, orgName, channelName) => __awaiter(this, void 0, void 0, function* () {
    const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
    try {
        const channel = fabricClient.getChannel(channelName, false);
        return channel.getChannelConfig();
    }
    catch (err) {
        const message = util.format("Got error during client.getChannel() %s", err);
        throw new Error(message);
    }
});
const joinChannel = (user, orgName, channelName, peers) => __awaiter(this, void 0, void 0, function* () {
    console.debug('\n\n============ Join Channel start ============\n');
    let error_message = null;
    const all_eventhubs = [];
    try {
        console.info('Calling peers in organization "%s" to join the channel', orgName);
        const client = yield helper.getClientForUser(user, orgName, networkConfig);
        console.debug('Successfully got the fabric client for the organization "%s"', orgName);
        const channel = client.getChannel(channelName);
        if (!channel) {
            const message = util.format('Channel %s was not defined in the connection profile', channelName);
            console.error(message);
            throw new Error(message);
        }
        const request = {
            txId: client.newTransactionID(true)
        };
        const genesis_block = yield channel.getGenesisBlock(request);
        const promises = [];
        promises.push(new Promise(resolve => setTimeout(resolve, 10000)));
        const join_request = {
            targets: peers,
            txId: client.newTransactionID(true),
            block: genesis_block
        };
        const join_promise = channel.joinChannel(join_request);
        promises.push(join_promise);
        const results = yield Promise.all(promises);
        console.debug(util.format('Join Channel R E S P O N S E : %j', results));
        const peers_results = results.pop();
        for (const i in peers_results) {
            const peer_result = peers_results[i];
            if (peer_result.response && peer_result.response.status == 200) {
                console.info('Successfully joined peer to the channel %s', channelName);
            }
            else {
                const message = util.format('Failed to joined peer to the channel %s', channelName);
                error_message = message;
                console.error(message);
            }
        }
    }
    catch (error) {
        console.error('Failed to join channel due to error: ' + error.stack ? error.stack : error);
        error_message = error.toString();
    }
    all_eventhubs.forEach((eh) => {
        eh.disconnect();
    });
    if (!error_message) {
        const message = util.format('Successfully joined peers in organization %s to the channel:%s', orgName, channelName);
        console.info(message);
        const response = {
            success: true,
            message: message
        };
        return response;
    }
    else {
        const message = util.format('Failed to join all peers to channel. cause:%s', error_message);
        console.error(message);
        throw new Error(message);
    }
});
//# sourceMappingURL=channel.js.map