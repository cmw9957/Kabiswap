pragma solidity >=0.8.10;

import '../interfaces/IKabiERC20.sol';

abstract contract KabiswapERC20 is IKabiERC20 {
    string public constant _name = "Kabiswap";
    string public constant _symbol = "KST";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1_000_000 * (10**decimals);

    mapping(address => uint256) nonces; 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowance;

    bytes32 public DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0) || spender != address(0), "Zero address is not allowed.");
        allowance[owner][spender] = value;
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _transfer(address from, address to, uint value) internal {
        require(balances[from] >= value, "Insufficient value.");
        balances[from] -= value;
        balances[to] += value;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] > 0, "Not approved.");
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner, 
        address spender, 
        uint value, 
        uint deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
        ) external {
            require(deadline >= block.timestamp, 'deadline is EXPIRED.');
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01', 
                    DOMAIN_SEPARATOR, 
                    keccak256(abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value, nonces[owner]++,
                        deadline
                        ))
                    ));
            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "Invalid Signature.");
            _approve(owner, spender, value);
        }
}