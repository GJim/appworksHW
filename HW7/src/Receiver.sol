// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NotUseful is ERC721 {
    uint256 public totalSupply = 10;
    uint256 private _currentMint = 0;

    error NoAnyNFT();

    constructor() ERC721("Not Useful NFT", "NUNFT") {}

    function mint(address to) public {
        if(_currentMint >= totalSupply) {
            revert NoAnyNFT();
        }
        _safeMint(to, _currentMint, "");
        _currentMint += 1;
    }
}

contract Homework is ERC721 {
    string public constant baseURI = "https://imgur.com/IBDi02f";
    uint256 public totalSupply = 500;
    uint256 private _currentMint = 0;

    error NoAnyNFT();

    // create a ERC721 token with name and symbol
    constructor() ERC721("Homework NFT", "HWNFT") {}

    // have a mint function
    function mint(address to) public {
        if(_currentMint >= totalSupply) {
            revert NoAnyNFT();
        }
        _safeMint(to, _currentMint, "");
        _currentMint += 1;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        // no need to check tokenId because always the same
        return baseURI;
    }
}

contract NFTReceiver is IERC721Receiver {
    address private _hwnft;

    constructor(address hwnft) {
        _hwnft = hwnft;
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        if(msg.sender != _hwnft) {
            // transfer current received NFT back to original user
            IERC721(msg.sender).safeTransferFrom(address(this), operator, tokenId);
            // mint homework token for original operator
            Homework(_hwnft).mint(operator);
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
