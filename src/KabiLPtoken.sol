// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KabiLPtoken is ERC20 {
    constructor() ERC20("Kabi Liquidity Pool Token", "KLT") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // 유동성 제거 시 호출되는 burn 함수
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
