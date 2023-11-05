pragma solidity ^0.8.21;

import {ERC721, ERC721Consecutive} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Consecutive.sol";

contract ERC721ConsecutiveToken is ERC721Consecutive {
    constructor() ERC721("ERC721ConsecutiveToken", "ECT") {}

    function mint(address to, uint96 quantity) public {
        _mintConsecutive(to, quantity);
    }
}