# Build Your First Network (BYFN)

This directory should be added to a compressed tar file named:
  hyperledger-fabric-byfn-$(VERSION).tar.gz

and made available from a publicly accessible Nexus location e.g.:
  https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/examples/

## Testing

To test this locally, copy the contents of this directory to a new directory. Then,
run 'make dist' from the root directory of the Fabric repository clone and
then extract the created tarfile into the directory you created previously.

e.g. from root of fabric repo clone on a Mac:
cp release/darwin-amd64/hyperledger-fabric-darwin-amd64.1.0.0-rc1.tar.gz ~/dev/byfntest && cd ~/dev/byfntest && tar xzf hyperledger-fabric-darwin-amd64.1.0.0-rc1.tar.gz
To run the sample:
./byfn.sh -m generate && ./byfn.sh -m up
