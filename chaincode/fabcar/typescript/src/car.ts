/*
 * SPDX-License-Identifier: Apache-2.0
 */
import { Object, Property } from 'fabric-contract-api';

@Object('Car')
export class Car {

    @Property('type')
    public docType?: string;

    @Property('color')
    public color: string;

    @Property('make')
    public make: string;

    @Property('model')
    public model: string;

    @Property('owner')
    public owner: string;
}
