// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KabiswapERC20 is ERC20 {
    uint256 public immutable CAP;
    address private _owner;
    address private beanDao;
    address private tamaCasino;

    mapping(address => uint256) nonces;
    mapping(address => mapping(address => uint256)) _allowance;

    constructor() ERC20("Kabi Swap Token", "KST") {
        CAP = 1_000_000_000 * (10**decimals());
        _mint(msg.sender, 100_000 ether);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == _owner, "Not owner.");
        require(amount + totalSupply() <= CAP, "Amount is over than total supply.");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
