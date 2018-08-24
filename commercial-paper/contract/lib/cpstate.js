/*
SPDX-License-Identifier: Apache-2.0
*/

'use strict';

// Helpful utilities class
const Utils = require('./utils.js');

// Enumeration of commercial paper state values
const cpState = {
    ISSUED : 1,
    TRADING : 2,
    REDEEMED : 3
};

/**
 * CommercialPaperState class defines a commercial paper state
 */
class CommercialPaperState {

    /**
     * Construct a commercial paper.  Initial state is issued.
     */
    constructor(issuer, paperNumber, owner, issueDate, maturityDate, faceValue){
        this.issuer = issuer;
        this.paperNumber = paperNumber;
        this.owner = owner;
        this.issueDate = issueDate;
        this.maturityDate = maturityDate;
        this.faceValue = faceValue;
        this.currentState = cpState.ISSUED;
    }

    /**
     * The commercial paper is uniquely identified by its key.
     * The key is a simple composite of issuer and paper number as strings.
     */
    getKey(){
        return JSON.stringify(this.issuer)+JSON.stringify(this.paperNumber);
    }

    /**
     * Basic getters and setters
     */
    getIssuer(){
        return this.issuer;
    }

    setIssuer(newIssuer){
        this.issuer = newIssuer;
    }

    getOwner(){
        return this.owner;
    }

    setOwner(newOwner){
        this.owner = newOwner;
    }

    /**
     * Useful methods to encapsulate commercial paper states
     */
    setTrading(){
        this.currentState = cpState.TRADING;
    }

    setRedeemed(){
        this.currentState = cpState.REDEEMED;
    }

    isTrading(){
        return this.currentState === cpState.TRADING;
    }

    isRedeemed(){
        return this.currentState === cpState.REDEEMED;
    }

}

/**
 * CommercialPaperListing provides a virtual container to access all
 * commercial papers. Each paper has unique key which associates it
 * with the container, rather than the container containing a link to
 * the paper. This is important in Fabric becuase it minimizes
 * collisions for parallel transactions on different papers.
 */
class CommercialPaperListing {

    /**
     * For this sample, it is sufficient to create a commercial paper listing
     * using a fixed container prefix. The transaction context is saved to
     * access Fabric APIs when required.
     */
    constructor(ctx){
        this.ctx = ctx;
        this.prefix = 'PAPERS';
    }

    /**
     * Add a paper to the listing. Creates a new state in worldstate with
     * appropriate composite key.  Note that paper defines its own key.
     * Paper object is serialized before writing.
     */
    addPaper(cp) {
        let key = this.ctx.stub.createCompositeKey(this.prefix, [cp.getKey()]);
        let data = Utils._serialize(cp);
        this.ctx.stub.putState(key, data);
    }

    /**
     * Get a paper from the listing. Gets the appropriate state from the
     * world state using issuer and paperNumber. State data is deserialized
     * into paper object before being returned.
     */
    getPaper(issuer, paperNumber) {
        let key = this.ctx.stub.createCompositeKey(this.prefix, [issuer, paperNumber]);
        let data = this.ctx.stub.getState(key);
        let cp = Utils._deserialize(data);
        return cp;
    }

    /**
     * Update a paper in the listing. Puts the new state in world state with
     * appropriate composite key.  Note that paper defines its own key.
     * Paper object is serialized before writing. Logic is very similar to
     * addPaper() but kept separate becuase it is semantically distinct, and
     * may change.
     */
    updatePaper(cp) {
        let key = this.ctx.stub.createCompositeKey(this.prefix, [cp.getKey()]);
        let data = Utils._serialize(cp);
        this.ctx.stub.putState(key, data);
    }

}

module.exports = {
    CommercialPaperState,
    CommercialPaperListing
};
