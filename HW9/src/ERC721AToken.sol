pragma solidity ^0.8.21;

import {ERC721A} from "@ERC721A/ERC721A.sol";

contract ERC721AToken is ERC721A {
    constructor() ERC721A("ERC721AToken", "EAT") {}

    function mintOne(address to) public {
        _mint(to, 1);
    }

    function mintBatch(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function mintERC2309One(address to) public {
        _mintERC2309(to, 1);
    }

    function mintERC2309Batch(address to, uint256 quantity) public {
        _mintERC2309(to, quantity);
    }

    function transfer25(address from, address to) public {
        transferFrom(from, to, 25);
    }
}