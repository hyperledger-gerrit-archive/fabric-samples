var util = require('util');
var path = require('path');
var hfc = require('fabric-client');

var file = 'network-config%s.yaml';

var env = process.env.TARGET_NETWORK;
if (env)
	file = util.format(file, '-' + env);
else
	file = util.format(file, '');
// indicate to the application where the setup file is located so it able
// to have the hfc load it to initalize the fabric client instance
hfc.setConfigSetting('network-connection-profile-path',path.join(__dirname, 'app', '../artifacts',file));
hfc.setConfigSetting('IEEE-connection-profile-path',path.join(__dirname, 'app', '../artifacts','ieee.yaml'));
hfc.setConfigSetting('Springer-connection-profile-path',path.join(__dirname, 'app', '../artifacts','springer.yaml'));
hfc.setConfigSetting('Elsevier-connection-profile-path',path.join(__dirname, 'app', '../artifacts','elsevier.yaml'));
hfc.setConfigSetting('ACM-connection-profile-path',path.join(__dirname, 'app', '../artifacts','acm.yaml'));
// some other settings the application might need to know
hfc.addConfigFile(path.join(__dirname, 'configphbc.json'));
