/*
SPDX-License-Identifier: Apache-2.0
*/

'use strict';

// Helpful utilities class
const Utils = require('./utils.js');

/**
 * StateList provides a virtual container to access all
 * ledger states of a certain type. Each paper has unique key which associates it
 * with the container, rather than the container containing a link to
 * the paper. This is important in Fabric becuase it minimizes
 * collisions for parallel transactions on different papers.
 */
class StateList {

    /**
     * For this sample, it is sufficient to create a commercial paper list
     * using a fixed container prefix. The transaction context is saved to
     * access Fabric APIs when required.
     */
    constructor(ctx) {
        this.api = ctx.stub;
    }

    /**
     * Add a paper to the list. Creates a new state in worldstate with
     * appropriate composite key.  Note that paper defines its own key.
     * Paper object is serialized before writing.
     */
    async addState(state) {
        let key = this.api.createCompositeKey(state.getType(), [state.getKey()]);
        let data = Utils.serialize(cp);
        await this.api.putState(key, data);
    }

    /**
     * Get a paper from the list using issuer and paper number. Forms composite
     * keys to retrieve data from world state. State data is deserialized
     * into paper object before being returned.
     */
    async getPaper([keys]) {
        let key = this.api.createCompositeKey(this.prefix, [keys]);
        let data = await this.api.getState(key);
        let cp = Utils.deserialize(data);
        return cp;
    }

    /**
     * Update a paper in the list. Puts the new state in world state with
     * appropriate composite key.  Note that paper defines its own key.
     * Paper object is serialized before writing. Logic is very similar to
     * addPaper() but kept separate becuase it is semantically distinct, and
     * may change.
     */
    async updatePaper(cp) {
        let key = this.api.createCompositeKey(this.prefix, [cp.getKey()]);
        let data = Utils.serialize(cp);
        await this.api.putState(key, data);
    }

}

module.exports = {
    CommercialPaper,
    CommercialPaperList
};
