/*
SPDX-License-Identifier: Apache-2.0
*/

'use strict';

// Helpful utilities class
const Utils = require('./asset.js');

// Enumeration of commercial paper state values
const cpState = {
    ISSUED: 1,
    TRADING: 2,
    REDEEMED: 3
};

/**
 * Asset class
 * Assets have a type and a unique key
 */
class State {
    constructor(type, [keyParts]) {
        this.type = JSON.stringify(type);
        this.key = makeKey([keyParts]);
    }

    getType() {
        return this.type;
    }

    static makeKey([keyParts]) {
        return keyParts.map(part => JSON.stringify(part)).join('');
    }

    getKey() {
        return this.key;
    }

}

/**
 * CommercialPaper class defines a commercial paper state
 */
class CommercialPaper extends State {

    /**
     * Construct a commercial paper.
     */
    constructor(issuer, paperNumber, issueDateTime, maturityDateTime, faceValue) {
        super(`$org.papernet.commercialpaper`, [issuer, paperNumber]);
        this.issuer = issuer;
        this.paperNumber = paperNumber;
        this.owner = issuer;
        this.issueDateTime = issueDateTime;
        this.maturityDateTime = maturityDateTime;
        this.faceValue = faceValue;
    }
 
    _serialize()
    _deserialize()

    /**
     * Basic getters and setters
    */
    getIssuer() {
        return this.issuer;
    }

    setIssuer(newIssuer) {
        this.issuer = newIssuer;
    }

    getOwner() {
        return this.owner;
    }

    setOwner(newOwner) {
        this.owner = newOwner;
    }

    /**
     * Useful methods to encapsulate commercial paper states
     */
    setIssued() {
        this.currentState = cpState.ISSUED;
    }

    setTrading() {
        this.currentState = cpState.TRADING;
    }

    setRedeemed() {
        this.currentState = cpState.REDEEMED;
    }

    isIssued() {
        return this.currentState === cpState.ISSUED;
    }

    isTrading() {
        return this.currentState === cpState.TRADING;
    }

    isRedeemed() {
        return this.currentState === cpState.REDEEMED;
    }

}

module.exports = {
    CommercialPaper,
};
