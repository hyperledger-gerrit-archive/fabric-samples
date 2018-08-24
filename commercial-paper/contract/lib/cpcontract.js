/*
SPDX-License-Identifier: Apache-2.0
*/

'use strict';

// Smart contract API brought into scope
const {Contract} = require('fabric-contract-api');

// Commercial paper classes brought into scope
const {CommercialPaperState, CommercialPaperListing} = require('./cpstate.js');

/**
 * Define the commercial paper smart contract extending Fabric Contract class
 */
class CommericalPaperContract extends Contract {

    /**
     * Each smart contract can have a unique namespace; useful when multiple
     * smart contracts per file.
     * Use transaction context (ctx) to store commercial paper listing, as
     * ctx is available to all subsequence contract transaction invocations.
     * @param {TxContext} ctx the transaction context
     */
    constructor(ctx) {
        super('org.papernet.commercialpaper');
        this.setBeforeFn = (ctx)=>{
            ctx.cpListing = new CommercialPaperListing(ctx,'PAPERS');
        };
    }

    /**
     * Issue commercial paper
     * @param {TxContext} ctx the transaction context
     * @param {String} issuer commercial paper issuer
     * @param {Integer} paperNumber paper number for this issuer
     * @param {String} issueDate paper issue Date
     * @param {String} maturityDate paper maturity date
     * @param {Integer} faceValue face value of paper
    */
    async issue(ctx, issuer, paperNumber, issueDate, maturityDate, faceValue) {

        let cp = new CommercialPaperState(issuer, paperNumber, issueDate, maturityDate, faceValue);

        // {issuer:"MagnetoCorp", paperNumber:"00001", "May31 2020", "Dec 31 2020", "5M USD"}

        await ctx.cpListing.addPaper(cp);
    }

    /**
     * Buy commercial paper
     * @param {TxContext} ctx the transaction context
     * @param {String} issuer commercial paper issuer
     * @param {Integer} paperNumber paper number for this issuer
     * @param {String} currentOwner current owner of paper
     * @param {String} newOwner new owner of paper
     * @param {Integer} price price paid for this paper
     * @param {String} purchaseTime time paper was purchased (i.e. traded)
    */
    async buy(ctx, issuer, paperNumber, currentOwner, newOwner, price, purchaseTime) {

        let cp = ctx.cpListing.getPaper(issuer, paperNumber);

        if (cp.isIssued()) {
            cp.setTrading();
        }

        if (cp.IsTrading()) {
            cp.setOwner(newOwner);
        } else {
            throw new Error('Paper '+issuer+paperNumber+' is not trading. Current state = '+cp.getCurrentState());
        }

        await ctx.cpListing.updatePaper(cp);
    }

    /**
     * Redeem commercial paper
     * @param {TxContext} ctx the transaction context
     * @param {String} issuer commercial paper issuer
     * @param {Integer} paperNumber paper number for this issuer
     * @param {String} redeemingOwner current owner of paper
     * @param {String} redeemTime time paper was redeemed
    */
    async redeem(ctx, issuer, paperNumber, redeemingOwner, redeemTime) {

        let cp = ctx.cpListing.getPaper(issuer, paperNumber);
        // Verify that the redeemer owns the commercial paper before redeeming it
        if (cp.getOwner() === redeemingOwner) {
            cp.setOwner(cp.getIssuer());
            cp.setRedeemed();
        } else {
            throw new Error('Redeeming owner does not own paper'+issuer+paperNumber);
        }

        await ctx.cpListing.updatePaper(cp);
    }

}

module.exports = CommericalPaperContract;
