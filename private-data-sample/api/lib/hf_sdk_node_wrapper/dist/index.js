"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const admin_1 = require("./lib/admin");
const user_1 = require("./lib/user");
const channel_1 = require("./lib/channel");
const chaincode_1 = require("./lib/chaincode");
const events_1 = require("./lib/events");
class HfcUtils {
    constructor(config) {
        this.adminHelper = admin_1.AdminHelper.getInstance(config);
        this.userHelper = user_1.UserHelper.getInstance(config);
        this.channelHelper = channel_1.ChannelHelper.getInstance(config);
        this.chaincodeHelper = chaincode_1.ChaincodeHelper.getInstance(config);
        this.eventsHelper = events_1.EventsHelper.getInstance(config);
        this.enrollAdmin = this.adminHelper.enrollAdmin;
        this.getAdmin = this.adminHelper.getAdmin;
        this.fetchAdmin = this.adminHelper.fetchAdmin;
        this.enrollUser = this.userHelper.enrollUser;
        this.fetchUser = this.userHelper.fetchUser;
        this.registerUser = this.userHelper.registerUser;
        this.createChannel = this.channelHelper.createChannel;
        this.joinChannel = this.channelHelper.joinChannel;
        this.getAllChannels = this.channelHelper.getAllChannels;
        this.getChannelConfig = this.channelHelper.getChannelConfig;
        this.getInstantiatedChaincodes = this.chaincodeHelper.getInstantiatedChaincodes;
        this.installChaincode = this.chaincodeHelper.installChaincode;
        this.instantiateChaincode = this.chaincodeHelper.instantiateChaincode;
        this.invokeChaincode = this.chaincodeHelper.invokeChaincode;
        this.queryChaincode = this.chaincodeHelper.queryChaincode;
        this.getBlockchainHeight = this.chaincodeHelper.getBlockchainHeight;
        this.registerBlockEventListener = this.eventsHelper.registerBlockEventListener;
        this.registerTxEventListener = this.eventsHelper.registerTxEventListener;
        this.registerChaincodeEventListener = this.eventsHelper.registerChaincodeEventListener;
    }
    static getInstance(config) {
        return this._instance || (this._instance = new this(config));
    }
}
exports.HfcUtils = HfcUtils;
//# sourceMappingURL=index.js.map