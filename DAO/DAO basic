pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAOToken is ERC20 {
    constructor() ERC20("DAO Token", "DAO") {
        _mint(msg.sender, 1000000); // Initial token distribution
    }
}