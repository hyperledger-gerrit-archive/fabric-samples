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
const util = require("util");
const helper = require("./helper");
let networkConfig;
class EventsHelper {
    constructor(config) {
        this.registerBlockEventListener = registerBlockEventListener;
        this.registerTxEventListener = registerTxEventListener;
        this.registerChaincodeEventListener = registerChaincodeEventListener;
        networkConfig = config;
    }
    static getInstance(config) {
        return this._instance || (this._instance = new this(config));
    }
}
exports.EventsHelper = EventsHelper;
const registerBlockEventListener = (user, orgName, channelName, peer, onEvent, onError, options) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForUser(user, orgName, networkConfig);
        const channel = yield fabricClient.getChannel(channelName);
        const channelEventHub = channel.newChannelEventHub(peer);
        const listenerRefNum = channelEventHub.registerBlockEvent(onEvent, onError, options);
        return { channelEventHub: channelEventHub, blockRegistrationNumber: listenerRefNum };
    }
    catch (err) {
        const message = util.format("Failed to get and register block event listener: %s ", err);
        throw new Error(message);
    }
});
const registerTxEventListener = (admin, orgName, channelName, peer, txId, onEvent, onError, options) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForUser(admin, orgName, networkConfig);
        const channel = yield fabricClient.getChannel(channelName);
        const channelEventHub = channel.newChannelEventHub(peer);
        const id = channelEventHub.registerTxEvent(txId, onEvent, onError, options);
        return { channelEventHub: channelEventHub, txId: id };
    }
    catch (err) {
        const message = util.format("Failed to get and register transaction event listener: %s ", err);
        throw new Error(message);
    }
});
const registerChaincodeEventListener = (admin, orgName, channelName, peer, ccId, eventName, onEvent, onError, options) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForUser(admin, orgName, networkConfig);
        const channel = yield fabricClient.getChannel(channelName);
        const channelEventHub = channel.newChannelEventHub(peer);
        const chaincodeEventHandle = channelEventHub.registerChaincodeEvent(ccId, eventName, onEvent, onError, options);
        return { channelEventHub: channelEventHub, chaincodeEventHandle: chaincodeEventHandle };
    }
    catch (err) {
        const message = util.format("Failed to get and register transaction event listener: %s ", err);
        throw new Error(message);
    }
});
//# sourceMappingURL=events.js.map