#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
    echo
    exit 1
fi

# REST endpoint
CBC_URL="http://localhost:4000"
PHBC_URL="http://localhost:4001"

# Channel names
CBC_Channel="conferenceonechannel"
PHBC_Channel="phbcchannel"

# Chaincode names
CBC_CC_name="conferenceCC"
PHBC_CC_name="phbcCC"

# Language defaults to "golang"
LANGUAGE="golang"

# Conference Blockchain (CBC) and PublishingHouse Blockchain (PHBC) peers/nodes
CBC_Peer1="peer0.pc1.example.com"
PHBC_peer="peer0.ieee.example.com"

# Set chaincode path
CBC_CC_SRC_PATH="github.com/mars_cc/go"
PHBC_CC_SRC_PATH="github.com/phbc_cc/go"

# CBC end user authentication
CBC_ENROLL(){
	CBC_user=$1
	CBC_org=$2

	CBC_TOKEN=$(curl -s -X POST \
	    $CBC_URL/users \
	    -H "content-type: application/x-www-form-urlencoded" \
	    -d 'username='$CBC_user'&orgName='$CBC_org'')

    TOKEN=$(echo $CBC_TOKEN | jq ".token" | sed "s/\"//g")
	echo $TOKEN
    return 0
}

# PHBC end user authentication
PHBC_ENROLL(){
    PHBC_user=$1
    PHBC_org=$2

    PHBC_TOKEN=$(curl -s -X POST \
        $PHBC_URL/users \
        -H "content-type: application/x-www-form-urlencoded" \
        -d 'username='$PHBC_user'&orgName='$PHBC_org'')

    TOKEN=$(echo $PHBC_TOKEN | jq ".token" | sed "s/\"//g")
    echo $TOKEN
    return 0

}

# CBC channel creation
CBC_Channel_Create(){
    CBC_TOKEN=$1

	CBC_Channel_resp=$(curl -s -X POST \
	    $CBC_URL/channels \
	    -H "authorization: Bearer $CBC_TOKEN" \
	    -H "content-type: application/json" \
	    -d '{
		    "channelName":"'$CBC_Channel'",
		    "channelConfigPath":"../artifacts/channel/'$CBC_Channel'.tx"}')
    echo $CBC_Channel_resp
	return 0
}

# PHBC channel creation
PHBC_Channel_Create(){
    PHBC_TOKEN=$1

    PHBC_Channel_resp=$(curl -s -X POST \
        $PHBC_URL/channels \
        -H "authorization: Bearer $PHBC_TOKEN" \
        -H "content-type: application/json" \
        -d '{
            "channelName":"'$PHBC_Channel'",
            "channelConfigPath":"../artifacts/channel/'$PHBC_Channel'.tx"}')
    echo $PHBC_Channel_resp
    return 0
}

# Join peers to CBC channel
CBC_Channel_Join(){
    CBC_TOKEN=$1
    peer1=$2
    peer2=$3

	Join_resp=$(curl -s -X POST \
	    $CBC_URL/channels/$CBC_Channel/peers \
	    -H "authorization: Bearer $CBC_TOKEN" \
	    -H "content-type: application/json" \
	    -d '{
	    "peers": ["'$peer1'","'$peer2'"]}')
    echo $Join_resp
    return 0
}

# Join peers to PHBC channel
PHBC_Channel_Join(){
    PHBC_TOKEN=$1
    peer1=$2
    peer2=$3

    PHBC_Join_resp=$(curl -s -X POST \
        $PHBC_URL/channels/$PHBC_Channel/peers \
        -H "authorization: Bearer $PHBC_TOKEN" \
        -H "content-type: application/json" \
        -d '{
        "peers": ["'$peer1'","'$peer2'"]}')
    echo "$PHBC_Join_resp"
    return 0
}

# Install Conference chaincode on CBC nodes
CBC_CC_Install(){
    CBC_TOKEN=$1
    peer1=$2
    peer2=$3

    CBC_install_resp=$(curl -s -X POST \
	    $CBC_URL/chaincodes \
	    -H "authorization: Bearer $CBC_TOKEN" \
	    -H "content-type: application/json" \
	    -d "{
		    \"peers\": [\"$peer1\",\"$peer2\"],
		    \"chaincodeName\":\"$CBC_CC_name\",
		    \"chaincodePath\":\"$CBC_CC_SRC_PATH\",
		    \"chaincodeType\": \"$LANGUAGE\",
		    \"chaincodeVersion\":\"v0\"
		}")
    echo $CBC_install_resp
	return 0
}

# Install Publishinghouse chaincode on PHBC nodes
PHBC_CC_Install(){
    PHBC_TOKEN=$1
    PHBC_peer1=$2
    PHBC_peer2=$3

    PHBC_CC_Install_result=$(curl -s -X POST \
        $PHBC_URL/chaincodes \
        -H "authorization: Bearer $PHBC_TOKEN" \
        -H "content-type: application/json" \
        -d "{
            \"peers\": [\"$PHBC_peer1\",\"$PHBC_peer2\"],
            \"chaincodeName\":\"$PHBC_CC_name\",
            \"chaincodePath\":\"$PHBC_CC_SRC_PATH\",
            \"chaincodeType\": \"$LANGUAGE\",
            \"chaincodeVersion\":\"v0\"
        }")
    echo $PHBC_CC_Install_result
    return 0
}

# Instantiate Conference chaincode on CBC channel
CBC_CC_Instantiate(){
    CBC_TOKEN=$1

    CBC_CC_Instantiate_result=$(curl -s -X POST \
        $CBC_URL/channels/$CBC_Channel/chaincodes \
        -H "authorization: Bearer $CBC_TOKEN" \
        -H "content-type: application/json" \
        -d "{
            \"chaincodeName\":\"$CBC_CC_name\",
            \"chaincodeVersion\":\"v0\",
            \"chaincodeType\": \"$LANGUAGE\",
            \"args\":[]
        }")
    echo "$CBC_CC_Instantiate_result"
    return 0
}


# Instantiate Publishinghouse chaincode on PHBC channel
PHBC_CC_Instantiate(){
    PHBC_TOKEN=$1

    PHBC_CC_Instantiate_result=$(curl -s -X POST \
        $PHBC_URL/channels/$PHBC_Channel/chaincodes \
        -H "authorization: Bearer $PHBC_TOKEN" \
        -H "content-type: application/json" \
        -d "{
            \"chaincodeName\":\"$PHBC_CC_name\",
            \"chaincodeVersion\":\"v0\",
            \"chaincodeType\": \"$LANGUAGE\",
            \"args\":[]
        }")
    echo $PHBC_CC_Instantiate_result
    return 0
}

# Query Publishinghouse chaincode
PHBC_GET(){

    # PHBC chaincode function name, arguments and authorization token
    PHBC_get_fcn_name=$1
    PHBC_get_fcn_args=$2
	PHBC_TOKEN=$3

    PHBC_get_result=$(curl -s -X GET \
        "$PHBC_URL/channels/$PHBC_Channel/chaincodes/$PHBC_CC_name?peer=$PHBC_peer&fcn=$PHBC_get_fcn_name&args=%5B%22$PHBC_get_fcn_args%22%5D" \
        -H "authorization: Bearer $PHBC_TOKEN" \
        -H "content-type: application/json")
    echo "$PHBC_get_result"
    return 0
}

# Call Publishinghouse chaincode functions
PHBC_POST(){

    # PHBC chaincode function name, arguments and authorization token
    PHBC_post_fcn_name=$1
    PHBC_post_fcn_args=$2
	PHBC_TOKEN=$3

    PHBC_post_result=$(curl -s -X POST \
        $PHBC_URL/channels/$PHBC_Channel/chaincodes/$PHBC_CC_name \
        -H "authorization: Bearer $PHBC_TOKEN" \
        -H "content-type: application/json" \
        -d '{
             "fcn":"'"$PHBC_post_fcn_name"'",
             "args":'"$PHBC_post_fcn_args"'}')
    echo "$PHBC_post_result"
    return 0
}

# Call Conference chaincode functions
CBC_POST(){

    # CBC chaincode function name, arguments and authorization token
    CBC_post_fcn_name=$1
    CBC_post_fcn_args=$2
    CBC_TOKEN=$3

    CBC_post_result=$(curl -s -X POST \
        $CBC_URL/channels/$CBC_Channel/chaincodes/$CBC_CC_name \
        -H "authorization: Bearer $CBC_TOKEN" \
        -H "content-type: application/json" \
        -d '{
             "fcn":"'"$CBC_post_fcn_name"'",
             "args":'"$CBC_post_fcn_args"'}')
    #"args":["'"$CBC_post_fcn_args"'"]}')
    echo $CBC_post_result
    return 0
}

# Query Conference chaincode
CBC_GET(){

    # CBC chaincode function name, arguments and authorization token
    CBC_get_fcn_name=$1
    CBC_get_fcn_args=$2
    CBC_TOKEN=$3

    CBC_get_result=$(curl -s -X GET \
        "$CBC_URL/channels/$CBC_Channel/chaincodes/$CBC_CC_name?peer=$CBC_Peer1&fcn=$CBC_get_fcn_name&args=%5B%22$CBC_get_fcn_args%22%5D" \
        -H "authorization: Bearer $CBC_TOKEN" \
        -H "content-type: application/json")
    echo $CBC_get_result
    return 0
}
