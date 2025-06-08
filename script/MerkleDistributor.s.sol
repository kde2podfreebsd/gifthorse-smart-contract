// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/MerkleDistributor.sol";

contract MerkleDistributorDeploy is Script {
    function run() external {
        vm.startBroadcast();

        address token_ = address(0x96e65c1DE006bD2bd6af26349BC3ACECcbB5f0f2);
        bytes32 merkleRoot_ = bytes32(0x723e263122340db4f1480a9156d854689c901b1677a5828af23b7bcc53e4a654); // from merkle.py
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 1 weeks;
        address initialOwner = msg.sender;

        MerkleDistributor distributor = new MerkleDistributor(token_, merkleRoot_, startTime_, endTime_, initialOwner);

        vm.stopBroadcast();
    }
}