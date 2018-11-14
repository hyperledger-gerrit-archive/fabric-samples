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
const path = require("path");
const helper = require("./helper");
let networkConfig;
class AdminHelper {
    constructor(config) {
        this.enrollAdmin = enrollAdmin;
        this.getAdmin = getAdmin;
        this.fetchAdmin = fetchAdmin;
        networkConfig = config;
    }
    static getInstance(config) {
        return this._instance || (this._instance = new this(config));
    }
}
exports.AdminHelper = AdminHelper;
const enrollAdmin = (adminEnrollmentID, adminEnrollmentSecret, orgName) => __awaiter(this, void 0, void 0, function* () {
    let adminUser;
    try {
        adminUser = yield fetchAdmin(adminEnrollmentID, orgName);
        if (adminUser && adminUser.isEnrolled()) {
            return null;
        }
        const fabricClient = yield helper.getClientForOrg(orgName, networkConfig);
        adminUser = yield fabricClient.setUserContext({
            username: adminEnrollmentID,
            password: adminEnrollmentSecret
        }, false);
        return adminUser;
    }
    catch (err) {
        console.error('Failed to enroll and persist admin. Error: ' + err.stack ? err.stack : err);
        throw err;
    }
});
const fetchAdmin = (adminEnrollmentID, orgName) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForOrg(orgName, networkConfig);
        return yield fabricClient.getUserContext(adminEnrollmentID, true);
    }
    catch (err) {
        console.error('Failed to fetch admin: ' + err);
        return Promise.reject(err.toString());
    }
});
const getAdmin = (username, orgName, mspID, mspDirPath, skipPersistence = false) => __awaiter(this, void 0, void 0, function* () {
    const keyPath = mspDirPath + '/keystore';
    const keyPEM = readAllFiles(keyPath)[0].toString();
    const certPath = mspDirPath + '/signcerts';
    const certPEM = readAllFiles(certPath)[0];
    const fabricClient = yield helper.getClientForOrg(orgName, networkConfig);
    return Promise.resolve(fabricClient.createUser({
        username,
        mspid: mspID,
        cryptoContent: {
            privateKeyPEM: keyPEM.toString(),
            signedCertPEM: certPEM.toString()
        },
        skipPersistence: skipPersistence
    }));
    function readAllFiles(mspDir) {
        const files = fs.readdirSync(mspDir);
        const certs = [];
        files.map(fileName => {
            const filePath = path.join(mspDir, fileName);
            const data = fs.readFileSync(filePath);
            certs.push(data);
        });
        return certs;
    }
});
//# sourceMappingURL=admin.js.map