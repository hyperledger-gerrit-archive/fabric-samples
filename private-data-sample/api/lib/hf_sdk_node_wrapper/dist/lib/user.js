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
const helper = require("./helper");
let networkConfig;
class UserHelper {
    constructor(config) {
        this.enrollUser = enrollUser;
        this.fetchUser = fetchUser;
        this.registerUser = registerUser;
        networkConfig = config;
    }
    static getInstance(config) {
        return this._instance || (this._instance = new this(config));
    }
}
exports.UserHelper = UserHelper;
const enrollUser = (userEnrollmentID, orgName, userEnrollmentSecret, userAffiliation, userAttributesForEnroll = null) => {
    return fetchUser(userEnrollmentID, orgName)
        .then(user => {
        if (user) {
            return Promise.resolve(null);
        }
        return enrollUser();
    });
    function enrollUser() {
        return __awaiter(this, void 0, void 0, function* () {
            const fabricClient = yield helper.getClientForOrg(orgName, networkConfig);
            const fabricCaClient = fabricClient.getCertificateAuthority();
            return fabricCaClient.enroll({
                enrollmentID: userEnrollmentID,
                enrollmentSecret: userEnrollmentSecret,
                attr_reqs: userAttributesForEnroll
            })
                .then((enrollment) => {
                return fabricClient.createUser({
                    username: userEnrollmentID,
                    mspid: fabricClient.getMspid(),
                    cryptoContent: {
                        privateKeyPEM: enrollment.key.toBytes(),
                        signedCertPEM: enrollment.certificate
                    },
                    skipPersistence: false
                });
            })
                .then((user) => {
                return fabricClient.setUserContext(user);
            })
                .catch(err => {
                console.error('Failed to enroll user: ' + err);
                return Promise.reject(err);
            });
        });
    }
};
const fetchUser = (userEnrollmentID, orgName) => __awaiter(this, void 0, void 0, function* () {
    try {
        const fabricClient = yield helper.getClientForOrg(orgName, networkConfig);
        const fabricCaClient = fabricClient.getCertificateAuthority();
        return yield fabricClient.getUserContext(userEnrollmentID, true);
    }
    catch (err) {
        console.error('Failed to fetch user: ' + err);
        return Promise.reject(err);
    }
});
const registerUser = (admin, orgName, userEnrollmentID, userAffiliation, userAttributesForRegister = null) => __awaiter(this, void 0, void 0, function* () {
    const fabricClient = yield helper.getClientForOrg(orgName, networkConfig);
    const fabricCaClient = fabricClient.getCertificateAuthority();
    return fabricCaClient.register({
        enrollmentID: userEnrollmentID,
        affiliation: userAffiliation,
        attrs: userAttributesForRegister
    }, admin)
        .catch(err => {
        console.error('Failed to register user: ' + err);
        return Promise.reject(err);
    });
});
//# sourceMappingURL=user.js.map