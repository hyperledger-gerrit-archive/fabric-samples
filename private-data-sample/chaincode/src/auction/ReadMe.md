To use Cid library
---------------------

- install govendor
go get -u github.com/kardianos/govendor 

- add $GOPATH/bin to $PATH
GOPATH=/root/hyperledger/go-pkgs
export PATH=$PATH:$GOPATH/bin

- add chaincode folder to GOPATH
export GOPATH=/root/hyperledger/go-pkgs/:/root/hyperledger/auction_private_data/chaincode
 
- govendoring steps 
 - govendor init
 - govendor fetch "github.com/golang/protobuf/proto"
 - govendor fetch "github.com/hyperledger/fabric/common/attrmgr"
 - govendor fetch "github.com/pkg/errors"


- now vendor folder is update-to-date

- place the vendor folder as under the CC_SRC_PATH ()

