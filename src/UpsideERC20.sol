// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UpsideERC20 is ERC20 {
    constructor() ERC20("Upside Pegging Token", "UPT") {
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
