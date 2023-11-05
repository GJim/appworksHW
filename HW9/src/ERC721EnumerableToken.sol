pragma solidity ^0.8.21;

import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ERC721EnumerableToken is ERC721Enumerable {
    constructor() ERC721("ERC721EnumerableToken", "EET") {}

    function mintOne(address to) public {
        uint256 startTokenId = totalSupply();
        _mint(to, startTokenId);
    }

    function mintBatch(address to, uint256 quantity) public {
        uint256 startTokenId = totalSupply();
        unchecked {
            uint256 end = startTokenId + quantity;
            do {
                _mint(to, startTokenId);
            } while (++startTokenId != end);
        }
    }

    function transfer25(address from, address to) public {
        transferFrom(from, to, 25);
    }
}