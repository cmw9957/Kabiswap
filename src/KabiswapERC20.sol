// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KabiswapERC20 is ERC20 {
    uint256 public immutable CAP;
    address private owner;
    address private beanDao;
    address private tamaCasino;

    mapping(address => uint256) nonces;
    mapping(address => mapping(address => uint256)) _allowance;

    bytes32 public DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name())),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        )
    );

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        CAP = 1_000_000_000 * (10**decimals());
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Not owner.");
        require(amount + totalSupply() <= CAP, "Amount is over than total supply.");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(deadline >= block.timestamp, "deadline is EXPIRED.");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Invalid Signature.");
        _approve(owner, spender, value);
    }
}
