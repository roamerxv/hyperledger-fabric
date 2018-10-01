#!/bin/bash
cd "/root/fabric/fabric-deploy/users/User1@org1.alcor.com"
PATH=`pwd`/../../bin:$PATH
export FABRIC_CFG_PATH=`pwd`
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
export CORE_PEER_TLS_KEY_FILE=./tls/client.key
export CORE_PEER_MSPCONFIGPATH=./msp
export CORE_PEER_ADDRESS=peer1.org1.alcor.com:7051
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
export CORE_PEER_ID=peer1.org1.alcor.com
export CORE_LOGGING_LEVEL=DEBUG
peer $*
