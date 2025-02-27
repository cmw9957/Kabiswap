// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KabiswapERC20 is ERC20, ERC20Permit, Ownable {
    uint256 public immutable CAP;
    address private beanDao;

    constructor() ERC20("Kabi Swap Token", "KST") Ownable(msg.sender) ERC20Permit("Kabi Swap Token") {
        CAP = 1_000_000_000 ether;
        _mint(msg.sender, 100_000 ether);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(amount + totalSupply() <= CAP, "Amount is over than total supply.");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
