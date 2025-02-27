// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UpsideERC20 is ERC20, ERC20Permit, Ownable {
    constructor() ERC20("Upside Pegging Token", "UPT") Ownable(msg.sender) ERC20Permit("Kabi Liquidity Pool Token") {
        _mint(msg.sender, 100 ether);
    }

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external payable {
        require(balanceOf(msg.sender) > amount, "Amount is insufficient.");
        _burn(msg.sender, amount);
        payable(address(msg.sender)).transfer(amount);
    }
}
