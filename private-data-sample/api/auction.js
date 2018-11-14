/*
* Copyright Persistent Systems 2018. All Rights Reserved.
* 
* SPDX-License-Identifier: Apache-2.0
*/

'use strict';

var log4js  = require('log4js');
var logger  = log4js.getLogger('Auction');
var path    = require('path');

var hfc     = require('fabric-client');
hfc.addConfigFile(path.join(__dirname, 'config/config.json'));

var lib = require('./initial.js');

// Create item - allowed for users with seller role
var createItem = async function(req, res) {

    // Check for input parameters
    logger.debug('==================== INVOKE BY CHAINCODE; Create Item with Private Data ==================');
    
    var loginId = req.loginId;
    var orgName = req.orgName;

    var itemName    = req.body.itemName; 
    var itemDesc    = req.body.itemDesc;
    var itemCat     = req.body.itemCat;
    var currency    = req.body.currency;
    var minBidPrice = req.body.minBidPrice;
    var reservePrice= req.body.reservePrice;
    var auctionStartDt  = req.body.auctionStartDt;
    var auctionEndDt    = req.body.auctionEndDt;

    
    var resultObj = {};

    logger.debug('End point : /auction/items');
    logger.debug('User parameters : ' );
    logger.debug(req.body);
    
    if (!itemName || !itemDesc || !itemCat || !currency || !minBidPrice || !reservePrice || !auctionStartDt || !auctionEndDt) {
        resultObj.result = 400;
        resultObj.errMsg = "Expected Parameters are Name, Description , Category, Currency, MinBidPrice, ReservePrice, Creator, AuctionStartDateTime, AuctionEndDateTime";        
        return resultObj;
    }

    var admins = hfc.getConfigSetting('admins');
    var user1  = await lib.myHfcUtils.fetchUser(loginId, orgName);
    
   if (user1==null){
        resultObj.result = 400;
        resultObj.errMsg = "Failed to fetch user  :: " + loginId + " for org ::" + orgName;   
        logger.debug(user1) ;
        return resultObj;
    }
    logger.debug("fetched user ..." , user1);

    // Prepare data to be sent in transientMap
    var privateData = {};
    privateData["reservePrice"] = Buffer(reservePrice).toString('base64');
    

    const invokeChaincodeResult = await lib.myHfcUtils.invokeChaincode(
                                    user1,        
                                    orgName,
                                    hfc.getConfigSetting('channelName'),       
                                    hfc.getConfigSetting('chaincodeId'),
                                    "createItem",
                                    [itemName, itemDesc, itemCat, currency, minBidPrice, loginId, auctionStartDt, auctionEndDt], 
                                    admins[0][orgName].peers,
                                    privateData  );

    logger.debug("invokeChaincodeResult ::", invokeChaincodeResult);

    const ccRespObj = JSON.parse(invokeChaincodeResult);
    logger.debug("ccRespObj ::", ccRespObj);

    // if there is errCode in response then item was not created
    if ("errCode" in ccRespObj){
        logger.debug("-------" + ccRespObj.errCode);
        logger.debug("ErrorCodes :: " + lib.ErrorCodes)
                
        resultObj.result = lib.ErrNum + lib.ErrorCodes.indexOf(ccRespObj.errCode);
        resultObj.errMsg = ccRespObj.errMessage;            
        
        logger.debug("Error from chaincode::" + ccRespObj.errMessage)
    }else{    
        
        logger.debug('Successfully created item on stateDB');
        resultObj.result    = 200;
        resultObj.itemId   = ccRespObj.itemId;
    }

    return resultObj;
};

// List all items created so far
var listItems = async function(req, res) {

    // Check for input parameters
    logger.debug('==================== QUERY BY CHAINCODE; List items ==================');
    
    var loginId = req.loginId;    
    var orgName = req.orgName;
    var resultObj = {};

    logger.debug("orgName from loginId :: ", orgName);

    logger.debug('User parameters : ' );
    logger.debug(req.body);
    

    var admins = hfc.getConfigSetting('admins');
    var user1 = await lib.myHfcUtils.fetchUser(loginId, orgName);
    
    if (user1==null){
        resultObj.result = 400;
        resultObj.errMsg = "Failed to fetch user  :: " + loginId + " for org ::" + orgName;   
        logger.debug(user1) ;
        return resultObj;
    }
    logger.debug("fetched user ..." , user1);

    const queryChaincodeResult = await lib.myHfcUtils.queryChaincode(
                                    user1,        
                                    orgName,
                                    hfc.getConfigSetting('channelName'),       
                                    hfc.getConfigSetting('chaincodeId'),
                                    "listItems",
                                    [loginId], 
                                    admins[0][orgName].peers );

    logger.debug("queryChaincodeResult ::", queryChaincodeResult);

    const ccRespObj = JSON.parse(queryChaincodeResult);
    logger.debug("ccRespObj ::", ccRespObj);

    // if there is errCode in response then item was not created
    if ("errCode" in ccRespObj){
        logger.debug("-------" + ccRespObj.errCode);
        logger.debug("ErrorCodes :: " + lib.ErrorCodes)
                
        resultObj.result = lib.ErrNum + lib.ErrorCodes.indexOf(ccRespObj.errCode);
        resultObj.errMsg = ccRespObj.errMessage;            
        
        logger.debug("Error from chaincode::" + ccRespObj.errMessage)
    }else{    
        
        logger.debug('Successfully listed items');
        resultObj.result    = 200;
        resultObj.list   = ccRespObj;
    }

    return resultObj;
};

// Place bid on items for auction
var placeBid = async function(req, res) {
    
    // Check for input parameters
    logger.debug('==================== INVOKE BY CHAINCODE; Place Bid for item ==================');
    
    var loginId = req.loginId;
    var orgName = req.orgName;

    var itemId    = req.body.itemId; 
    var bidAmt    = req.body.bidAmount;
    
    var resultObj = {};
  

    logger.debug('User parameters : ' );
    logger.debug(req.body);
    
    if (!itemId || !bidAmt) {
        resultObj.result = 400;
        resultObj.errMsg = "Expected Parameters are ItemId and BidAmount";        
        return resultObj;
    }

    var admins = hfc.getConfigSetting('admins');
    var user1  = await lib.myHfcUtils.fetchUser(loginId, orgName);
    
    if (user1==null){
        resultObj.result = 400;
        resultObj.errMsg = "Failed to fetch user  :: " + loginId + " for org ::" + orgName;   
        logger.debug(user1) ;
        return resultObj;
    }
    logger.debug("fetched user ..." , user1);

    const invokeChaincodeResult = await lib.myHfcUtils.invokeChaincode(
                                    user1,        
                                    orgName,
                                    hfc.getConfigSetting('channelName'),       
                                    hfc.getConfigSetting('chaincodeId'),
                                    "placeBid",
                                    [itemId, bidAmt, loginId], 
                                    admins[0][orgName].peers      );

    logger.debug("invokeChaincodeResult ::", invokeChaincodeResult);

    const ccRespObj = JSON.parse(invokeChaincodeResult);
    logger.debug("ccRespObj ::", ccRespObj);

    // if there is errCode in response then item was not created
    if ("errCode" in ccRespObj){
        logger.debug("-------" + ccRespObj.errCode);
        logger.debug("ErrorCodes :: " + lib.ErrorCodes)
                
        resultObj.result = lib.ErrNum + lib.ErrorCodes.indexOf(ccRespObj.errCode);
        resultObj.errMsg = ccRespObj.errMessage;            
        
        logger.debug("Error from chaincode::" + ccRespObj.errMessage)
    }else{    
        
        logger.debug('Successfully placed bid on item');
        resultObj.result    = 200;
        resultObj.bidId   = ccRespObj.bidId;
    }

    return resultObj;
};
    
// Carry out auction for items
var auction = async function(req, res) {

    // call the listItems SC
    let respObj = await listItems(req, res);

    var loginId = req.loginId;    
    var orgName = req.orgName;// to be derived from loginId

    // for every item.status = created; call auction SC
    var admins = hfc.getConfigSetting('admins');
    var user1 = await lib.myHfcUtils.fetchUser(loginId, orgName);
    var resultObj = {};

    logger.debug("loginId in auction :: ", loginId);

   if (user1==null){
        resultObj.result = 400;
        resultObj.errMsg = "Failed to fetch user  :: " + loginId + " for org ::" + orgName;   
        logger.debug(user1) ;
        return resultObj;
    }
    logger.debug("fetched user ..." , user1);

    var resultList = [];

    respObj.list.forEach(async function(itemObj){

        const invokeChaincodeResult = await lib.myHfcUtils.invokeChaincode(
            user1,        
            orgName,
            hfc.getConfigSetting('channelName'),       
            hfc.getConfigSetting('chaincodeId'),
            "auction",
            [itemObj.itemId], 
            admins[0][orgName].peers
        );

        logger.debug("auction result ::", invokeChaincodeResult);

        const ccRespObj = JSON.parse(invokeChaincodeResult);
        logger.debug("ccRespObj ::", ccRespObj);

        var auctionResult = {};
        // if there is errCode in response then item was not created
        if ("errCode" in ccRespObj){
            logger.debug("-------" + ccRespObj.errCode);
            
            auctionResult.itemId = itemObj.itemId
            auctionResult.result = lib.ErrNum + lib.ErrorCodes.indexOf(ccRespObj.errCode);
            auctionResult.errMsg = ccRespObj.errMessage;            

            logger.debug("Error from chaincode::" + ccRespObj.errMessage)
        }else{    
            logger.debug('Successfully auctioned item');
            auctionResult.itemId = itemObj.itemId
            auctionResult.result = 200;
            //resultObj.itemId   = ccRespObj.itemId;
        }
        resultList.push(auctionResult);
    });

    return resultList;
};
    
    
exports.createItem = createItem;
exports.listItems = listItems;
exports.placeBid = placeBid;
exports.auction = auction;
