// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "../interfaces/IERC20.sol";

contract UpsideERC20 is IERC20 {
    string public constant _name = "Upside";
    string public constant _symbol = "UPT";
    uint8 public constant decimals = 18;
    uint256 public _totalSupply;

    mapping(address => uint256) nonces;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) _allowance;

    bytes32 public DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_name)),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        )
    );

    function mint() external payable {
        _totalSupply += msg.value;
        balances[msg.sender] += msg.value;
    }

    function burn(uint256 amount) external {
        _totalSupply -= amount;
        balances[msg.sender] -= amount;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(balances[from] >= value, "Insufficient value.");
        balances[from] -= value;
        balances[to] += value;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0) || spender != address(0), "Zero address is not allowed.");
        _allowance[owner][spender] = value;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(_allowance[from][msg.sender] > 0, "Not approved.");
        _transfer(from, to, value);
        return true;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
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
