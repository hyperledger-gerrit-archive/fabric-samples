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
const getClientForOrg = (orgName, networkConfig, username, cache, additionalConfig) => __awaiter(this, void 0, void 0, function* () {
    let client;
    if (cache && username) {
        client = yield cache.get(username);
        if (client) {
            return client;
        }
    }
    const userOrg = orgName;
    client = FabricClient.loadFromConfig(networkConfig.networkConfigFile);
    client.loadFromConfig(networkConfig.orgs.get(orgName));
    yield client.initCredentialStores();
    if (cache && username) {
        client = yield cache.put(username, client);
    }
    return client;
});
exports.getClientForOrg = getClientForOrg;
function getClientForUser(user, orgName, networkConfig, cache, additionalConfig) {
    return __awaiter(this, void 0, void 0, function* () {
        let username, userObj;
        if (typeof user == 'string') {
            username = user;
        }
        else {
            username = user.getName();
            userObj = user;
        }
        const client = yield getClientForOrg(orgName, networkConfig, username, cache, additionalConfig);
        if (userObj) {
            yield client.setUserContext(userObj, true);
        }
        else {
            const user = yield client.getUserContext(username, true);
            if (!user) {
                throw new Error('User was not found :' + username);
            }
            else {
            }
        }
        return client;
    });
}
exports.getClientForUser = getClientForUser;
//# sourceMappingURL=helper.js.map