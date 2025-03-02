// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./KabiswapERC20.sol";
import "./UpsideERC20.sol";
import "./KabiLPtoken.sol";

contract KabiswapPool is Initializable {
    address DONT;
    address USE;
    enum State { Active, Paused }
    State public currentState;
    KabiswapERC20 public kabiToken; // Kabiswap Token
    UpsideERC20 public upsideToken; // Upside Token (ETH)
    KabiLPtoken public LPToken;
    address owner;

    uint256 public reserve0; // 풀 내 Kabiswap Token 보유량
    uint256 public reserve1; // 풀 내 Upside Token 보유량

    mapping(address => uint256) public liquidityProviders; // 유동성 제공자 추적

    uint256 public constant FEE_RATE = 997; // 0.3% 수수료 (1000 - 3)
    uint256 public constant FEE_DENOMINATOR = 1000; // 수수료 분모

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier inState(State expectedState) {
        require(currentState == expectedState, "Invalid state for this action");
        _;
    }

    function initialize(address _token0, address _token1, address _token2) public {
        kabiToken = KabiswapERC20(_token0);
        upsideToken = UpsideERC20(_token1);
        LPToken = KabiLPtoken(_token2);
        currentState = State.Active;
        owner = msg.sender;
    }

    function swap(address tokenIn, uint256 amountIn) external inState(State.Active) returns (uint256 amountOut) {
        require(amountIn > 0, "Swap amount must be greater than zero.");
        require(tokenIn == address(kabiToken) || tokenIn == address(upsideToken), "Invalid token");

        bool isKabiToUpside = (tokenIn == address(kabiToken));
        (uint256 reserveInput, uint256 reserveOutput) = isKabiToUpside ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 amountInWithFee = (amountIn * FEE_RATE) / FEE_DENOMINATOR; // 수수료를 제외한 토큰 양

        uint256 newReserveInput = reserveInput + amountInWithFee; // input token 양과 수수료를 제외한 토큰 양을 더함
        uint256 newReserveOutput = (reserveInput * reserveOutput) / newReserveInput;
        amountOut = reserveOutput - newReserveOutput; // 0.3% 수수료가 적용된 상태

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

    function addLiquidity(uint256 amountKabi, uint256 amountUpside) external inState(State.Active) returns (uint256 lpTokens) {
        require(amountKabi > 0 && amountUpside > 0, "Invalid liquidity amounts");

        if (reserve0 == 0 || reserve1 == 0) {
             // 초기 유동성 공급 처리
            lpTokens = sqrt(amountKabi * amountUpside);
            require(lpTokens > 0, "Initial liquidity must be nonzero");
        } else {
            // 기존 유동성이 존재하는 경우, 비율 유지 확인
            uint256 idealAmountUpside = (reserve1 * amountKabi) / reserve0;
            require(
                idealAmountUpside * 995 / 1000 <= amountUpside && amountUpside <= idealAmountUpside * 1005 / 1000,
                "Liquidity proportion is off"
            );
        }
        require(lpTokens > 0, "LP token calculation error");

        // 토큰 전송 (사용자가 토큰을 보내도록 승인 필요)
        kabiToken.transferFrom(msg.sender, address(this), amountKabi);
        upsideToken.transferFrom(msg.sender, address(this), amountUpside);

        // 유동성 풀 업데이트
        reserve0 += amountKabi;
        reserve1 += amountUpside;

        // LP 토큰 계산 및 발행
        uint256 totalLPsupply = LPToken.totalSupply();
        
        if(totalLPsupply != 0) {
            lpTokens = min((amountKabi * totalLPsupply) / reserve0, (amountUpside * totalLPsupply) / reserve1);
        }

        require(lpTokens > 0, "LP token calculation error");
        LPToken.mint(msg.sender, lpTokens); // 유동성 제공자에게 LP 토큰 발행
    }

    function removeLiquidity(uint256 lpTokens) external inState(State.Active) returns (uint256 amountKabi, uint256 amountUpside) {
        require(lpTokens > 0, "LP tokens must be greater than zero.");
        
        uint256 totalLPsupply = LPToken.totalSupply();
        require(totalLPsupply > 0, "No LP tokens in circulation.");

        // 반환할 Kabi와 Upside 양 계산
        amountKabi = (reserve0 * lpTokens) / totalLPsupply;
        amountUpside = (reserve1 * lpTokens) / totalLPsupply;

        require(amountKabi > 0 && amountUpside > 0, "Invalid liquidity amounts");

        // 유동성 공급자의 LP 토큰을 소각
        LPToken.burn(msg.sender, lpTokens);

        // 유동성 풀에서 Kabi와 Upside 반환
        reserve0 -= amountKabi;
        reserve1 -= amountUpside;

        // 사용자가 반환받을 Kabi와 Upside 토큰 전송
        kabiToken.transfer(msg.sender, amountKabi);
        upsideToken.transfer(msg.sender, amountUpside);
    }

    function pause() external onlyOwner inState(State.Active) {
        currentState = State.Paused;
    }

    function resume() external onlyOwner inState(State.Paused) {
        currentState = State.Active;
    }

    function multicall(bytes[] calldata data) external inState(State.Active) returns (bool[] memory success, bytes[] memory returnData) {
        success = new bool[](data.length);
        returnData = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            (success[i], returnData[i]) = address(this).delegatecall(data[i]);
            require(success[i], "Multicall execution failed");
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
