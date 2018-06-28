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
hfc.setConfigSetting('PC1-connection-profile-path',path.join(__dirname, 'app', '../artifacts','pc1.yaml'));
hfc.setConfigSetting('PC2-connection-profile-path',path.join(__dirname, 'app', '../artifacts','pc2.yaml'));
hfc.setConfigSetting('PC3-connection-profile-path',path.join(__dirname, 'app', '../artifacts','pc3.yaml'));
hfc.setConfigSetting('PC4-connection-profile-path',path.join(__dirname, 'app', '../artifacts','pc4.yaml'));
// some other settings the application might need to know
hfc.addConfigFile(path.join(__dirname, 'config.json'));
