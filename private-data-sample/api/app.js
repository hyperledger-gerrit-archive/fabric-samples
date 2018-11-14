/*
* Copyright Persistent Systems 2018. All Rights Reserved.
* 
* SPDX-License-Identifier: Apache-2.0
*/
		
'use strict';

var log4js = require('log4js');
var logger = log4js.getLogger('AuctionApp');

var express = require('express');
var session = require('express-session');
var cookieParser = require('cookie-parser');
var bodyParser   = require('body-parser');

var http = require('http');
var util = require('util');
var path = require('path');

var app         = express();
var expressJWT  = require('express-jwt');
var jwt         = require('jsonwebtoken');
var bearerToken = require('express-bearer-token');
var cors        = require('cors');

var auction = require('./auction.js');

var hfc         = require('fabric-client');
hfc.addConfigFile(path.join(__dirname, 'config/config.json'));

var lib = require('./initial.js');

var host = process.env.HOST || hfc.getConfigSetting('host');
var port = 4000||process.env.PORT || hfc.getConfigSetting('port');


app.options('*', cors());
app.use(cors());
//support parsing of application/json type post data
app.use(bodyParser.json());
//support parsing of application/x-www-form-urlencoded post data
app.use(bodyParser.urlencoded({
	extended: false
}));
// set secret variable
app.set('secret', 'thisismysecret');
app.use(expressJWT({
	secret: 'thisismysecret'
}).unless({
	path: ['/auction/users', '/auction/login']
}));
app.use(bearerToken());
app.use(function(req, res, next) {
	logger.debug(' ------>>>>>> new request for %s',req.originalUrl);

	if (req.originalUrl.indexOf('/auction/users') >= 0) {
		logger.debug("======== here ===" + req.originalUrl);
		return next();
	}else if (req.originalUrl.indexOf('/auction/login') >= 0) {
		logger.debug("======== here ===" + req.originalUrl);
		return next();
	}

	var token = req.token;
	jwt.verify(token, app.get('secret'), function(err, decoded) {
		if (err) {
			res.send({
				result: 400,
				errMsg: 'Failed to authenticate token. Make sure to include the ' +
					'token returned from /auction/users call in the authorization header ' +
					' as a Bearer token'
			});
			return;
		} else {
			// add the decoded user name and org name to the request object
			// for the downstream code to use
			req.loginId = decoded.loginId;
			req.orgName = decoded.loginId.split("-")[0];
			logger.debug(util.format('Decoded from JWT token: username - %s, orgname - %s', decoded.loginId));
			return next();
		}
	});
});

//////////////////////////////// START SERVER /////////////////////////////////
var server = http.createServer(app).listen(port, function() {});
logger.info('****************** SERVER STARTED ************************');
logger.info('***************  http://%s:%s  ******************',host,port);
server.timeout = 240000;

function getErrorMessage(field) {
	var response = {
		success: false,
		message: field + ' field is missing or Invalid in the request'
	};
	return response;
}

// USER functions
// Register and enroll user
app.post('/auction/users', async function(req, res) {
    logger.debug('==================== INVOKE BY CHAINCODE; Register User ==================');

	var username    = req.body.username;
    var orgName     = req.body.orgName;
    var password    = req.body.password;
    var avlBalance  = req.body.avlBalance;
    var currency    = req.body.currency;

    var resultObj = {};

	logger.debug('End point : /auction/users');
    logger.debug('User parameters : ' );
    logger.debug(req.body);
	
	if (!username || !orgName || !password || !avlBalance || !currency) {
        resultObj.result = 400;
		resultObj.errMsg = "Expected Parameters are username, orgName, password, initial balance, currency";        
        res.json(resultObj);	
    }
    
    var admins = hfc.getConfigSetting('admins');

    /* is admin enrolled; if not then enrol admin before enrolling users */
    var admin;   
    var orgAdmin = admins[0][orgName]
    
    admin = await lib.myHfcUtils.fetchAdmin(        
                    orgAdmin.username,
                    orgName
    );
    
    logger.debug("fetched admin ...", admin);

    if (admin == null){
        admin = await lib.myHfcUtils.enrollAdmin(         
            orgAdmin.username,
            orgAdmin.secret, 
            orgName
        );         
    }

    logger.debug("enroled admin ...", admin);

    //we have admin; now we can enroll users
    var secret = await lib.myHfcUtils.registerUser(
                            admin,
                            orgName,
                            orgName +"-"+username,
                            orgAdmin.affiliation,
                            orgAdmin.attributesForRegister);

    var user = JSON.parse((await lib.myHfcUtils.enrollUser(       
                        orgName +"-"+username,
                        orgName,
                        secret,
                        orgAdmin.affiliation,        
                        orgAdmin.attributesForEnroll)
                    ).toString());

    logger.debug("user is now enrolled::", user);

    //once user is enrolled add the user details on stateDB
    if (user !=null){
        var user1 = await lib.myHfcUtils.fetchUser(orgName +"-"+username, orgName);

        logger.debug("once user is enrolled add the user details on stateDB");

        const invokeChaincodeResult = await lib.myHfcUtils.invokeChaincode(
                                        user1,        
                                        orgName,
                                        hfc.getConfigSetting('channelName'),       
                                        hfc.getConfigSetting('chaincodeId'),
                                        "registerUser",
                                        [orgName +"-"+username, avlBalance, currency, admins[0][orgName].attributesForRegister[0].value], 
                                        orgAdmin.peers      );

        logger.debug("invokeChaincodeResult ::", invokeChaincodeResult);

        logger.debug('-- returned from registering the username %s for organization %s',username,orgName);

        const ccRespObj = JSON.parse(invokeChaincodeResult);
        logger.debug("ccRespObj ::", ccRespObj);
        

        if ("errCode" in ccRespObj){
            logger.debug("-------" + ccRespObj.errCode);
            logger.debug("ErrorCodes :: " + lib.ErrorCodes)
            
            // TODO :: user should be removed from fabric-ca db
            resultObj.result = lib.ErrNum + lib.ErrorCodes.indexOf(ccRespObj.errCode);
            resultObj.errMsg = ccRespObj.errMessage;            
            
            logger.debug("Error from chaincode::" + ccRespObj.errMessage)
        }else{
            //TODO:: This is place where the user should be registered with off-chain DB
            
            logger.debug('Successfully registered the username %s for organization %s',username,orgName);                  
            resultObj.result    = 200;
            resultObj.loginid   = orgName +"-"+username;
        }
        
    }else{
        resultObj.result = ErrNum;
        resultObj.errMsg = "User could not be registered to Blockchain Certificate Authority";
    }

    res.json(resultObj);	
});


app.post('/auction/login', async function(req, res) {
    logger.debug('==================== QUERY BY CHAINCODE; Login User ==================');

    var loginId     = req.body.loginId;
    var password    = req.body.password;
    var resultObj = {};
    
    logger.debug('End point : /auction/users');
    logger.debug('User parameters : ' );
    logger.debug(req.body);
    
    if (!loginId || !password) {
        resultObj.result = 400;
        resultObj.errMsg = "Expected Parameters are loginId, password";        
        return resultObj;
    }

    // TODO: make a call to off-chain DB to verify password
	var token = jwt.sign({
		exp: Math.floor(Date.now() / 1000) + parseInt(hfc.getConfigSetting('jwt_expiretime')),
		loginId: loginId
	}, app.get('secret'));


    logger.debug('Successfully logged in with login %s',loginId);
    resultObj.token     = token;           
    resultObj.result    = 200;
    resultObj.loginid   = loginId;

    res.json(resultObj);
});


// =========== ITEM functions ============
//----- CREATE ITEM -----
app.post('/auction/items', async function(req, res) {
    logger.debug('==================== Create New Item ==================');
    let respObj = await auction.createItem(req, res);
	res.send(respObj);
});

//----- LIST ITEMS -----
app.get('/auction/items', async function(req, res) {
    logger.debug('==================== List items ==================');
    let respObj = await auction.listItems(req, res);
	res.send(respObj);
});

//----- AUCTION ITEM -----
app.patch('/auction/items', async function(req, res) {
    logger.debug('=================== AUCTION item ==================');
    let respObj = await auction.auction(req, res);
	res.send(respObj);
});

// =========== BID functions ============
//----- PLACE/UPDATE BID -----
app.post('/auction/bids', async function(req, res) {
    logger.debug('==================== Place new bid ==================');
    let respObj = await auction.placeBid(req, res);
	res.send(respObj);
});

//----- LIST BID -----
app.get('/auction/bids', async function(req, res) {
    logger.debug('==================== list bids  ==================');
});