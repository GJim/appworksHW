// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract RNDNFT is ERC721, VRFConsumerBaseV2 {
    // support toString library
    using Strings for uint256;

    // contract variables
    address private _owner;
    uint256 public totalSupply = 500;
    uint256 private _currentMint = 0;
    uint256 public _rnd;
    bool private _unblinding;
    string public constant baseURI = "https://localhost/collections/";
    string public constant defaultURI = "https://localhost/collections/default.jpg";

    // chainlink variables
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 constant CALLBACK_GAS_LIMIT = 100000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 1;

    // contract error
    error BlockNumberNotEnough();
    error AlreadyUnblinding();
    error NotOwner();
    error NoAnyNFT();

    // event
    event ReturnedRandomness(uint256[] randomWords);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) ERC721("Random NFT Collection", "RNDNFT")
      VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        _owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    modifier onlyOwner() {
        if(msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    function getRndForTest() view public returns(uint256) {
        return _rnd;
    }

    function unblind() onlyOwner public {
        if(block.number < 15000) {
            revert BlockNumberNotEnough();
        }
        if(_unblinding) {
            revert AlreadyUnblinding();
        }
        COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        _unblinding = true;
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        _rnd = randomWords[0];
        emit ReturnedRandomness(randomWords);
    }

    function tokenURI(uint256 tokenId) public view override virtual returns (string memory) {
        if(_unblinding) {
            uint256 number = (tokenId+_rnd)%totalSupply;
            return string.concat(baseURI, number.toString());
        }
        // no need to check tokenId because always the same
        return defaultURI;
    }

    function mint() public {
        if(_currentMint >= totalSupply) {
            revert NoAnyNFT();
        }
        _safeMint(msg.sender, _currentMint, "");
        _currentMint += 1;
    }
}