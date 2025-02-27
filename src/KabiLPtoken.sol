// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KabiLPtoken is ERC20, ERC20Permit, Ownable {
    event Log(address);
    constructor() ERC20("Kabi Liquidity Pool Token", "KLT") Ownable(msg.sender) ERC20Permit("Kabi Liquidity Pool Token"){}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // 유동성 제거 시 호출되는 burn 함수
    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
