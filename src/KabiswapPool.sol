// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "../interfaces/IKabiswapPool.sol";
import "./KabiswapERC20.sol";
import "./UpsideERC20.sol";
import "./KabiLPtoken.sol";

contract KabiswapPool {
    KabiswapERC20 public immutable kabiToken; // Kabiswap Token
    UpsideERC20 public immutable upsideToken; // Upside Token (ETH)

    uint256 public reserve0; // 풀 내 Kabiswap Token 보유량
    uint256 public reserve1; // 풀 내 Upside Token 보유량

    mapping(address => uint256) public liquidityProviders; // 유동성 제공자 추적

    uint256 public constant FEE_RATE = 997; // 0.3% 수수료 (1000 - 3)
    uint256 public constant FEE_DENOMINATOR = 1000; // 수수료 분모

    constructor(address _token0, address _token1) {
        kabiToken = KabiswapERC20(_token0);
        upsideToken = UpsideERC20(_token1);

        kabiToken.transfer(address(this), 100_000 ether);
        upsideToken.transfer(address(this), 100 ether);

        reserve0 = 100_000 ether;
        reserve1 = 100 ether;
    }

    function swap(address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "Swap amount must be greater than zero.");
        require(tokenIn == address(kabiToken) || tokenIn == address(upsideToken), "Invalid token");

        bool isKabiToUpside = (tokenIn == address(kabiToken));
        (uint256 reserveInput, uint256 reserveOutput) = isKabiToUpside ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 amountInWithFee = (amountIn * FEE_RATE) / FEE_DENOMINATOR;

        uint256 newReserveInput = reserveInput + amountInWithFee;
        uint256 newReserveOutput = (reserveInput * reserveOutput) / newReserveInput;
        amountOut = reserveOutput - newReserveOutput;

        require(amountOut > 0, "Insufficient output amount");

        if (isKabiToUpside) {
            kabiToken.transferFrom(msg.sender, address(this), amountIn);
            
            upsideToken.transfer(msg.sender, amountOut);
            reserve0 += amountIn;
            reserve1 -= amountOut;
        } else {
            upsideToken.transferFrom(msg.sender, address(this), amountIn);

            kabiToken.transfer(msg.sender, amountOut);
            reserve1 += amountIn;
            reserve0 -= amountOut;
        }
    }
}
