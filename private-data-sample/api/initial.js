var sdk = require('hf_sdk_node_wrapper/dist');

var orgmap = new Map();
orgmap.set('Org1', 'config/org1.yaml');
orgmap.set('Org2', 'config/org2.yaml');

var netConfObj = { networkConfigFile: "config/network-config.yaml",
                orgs: orgmap
    };

var myHfcUtils = sdk.HfcUtils.getInstance(netConfObj);

const ErrNum = 500;
const ErrorCodes = ["IncorrectArgs","LedgerKeyMismatch", "FetchFromLedger","CouchDbQuery","PasswordMismatch","DateParseErr","InvalidPutState","MarshallingErr","InvalidEvent","RoleNotSupported","AmountNotSatisfied","ItemNotOnAuction","KeyNotFound"];

exports.myHfcUtils  = myHfcUtils;
exports.ErrNum      = ErrNum;
exports.ErrorCodes  = ErrorCodes;
