// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Test, console} from "forge-std/Test.sol";
import {KabiswapPool} from "../src/KabiswapPool.sol";
import {KabiswapERC20} from "../src/KabiswapERC20.sol";
import {UpsideERC20} from "../src/UpsideERC20.sol";
import {KabiLPtoken} from "../src/KabiLPtoken.sol";
import {SwapProxy} from "../src/SwapProxy.sol";

contract KabiswapPoolTest is Test {
    KabiswapPool public pool;
    KabiswapERC20 public kabiToken;
    UpsideERC20 public upsideToken;
    KabiLPtoken public LPToken;
    SwapProxy public proxyContract;

    address public user;
    address public user2;

    event Log(address);

    function setUp() public {
        user = address(0x123);
        user2 = address(0x456);

        vm.deal(address(user), 10000 ether);
        vm.deal(address(user2), 10000 ether);
        // 배포 및 초기화
        kabiToken = new KabiswapERC20();
        upsideToken = new UpsideERC20();
        LPToken = new KabiLPtoken();

        pool = new KabiswapPool();
        pool.initialize(address(kabiToken), address(upsideToken), address(LPToken));
        proxyContract = new SwapProxy(address(pool), address(kabiToken), address(upsideToken), address(LPToken));

        // KabiswapPool에서 사용할 ERC20 토큰을 사용자에게 배포
        kabiToken.mint(user, 1000 * 10 ** 18);
        vm.startPrank(user);
        upsideToken.deposit{value: 1000 ether}();  // 1 ether를 보내면서 deposit 호출
        vm.stopPrank();

        kabiToken.mint(user2, 1000 * 10 ** 18);
        vm.startPrank(user2);
        upsideToken.deposit{value: 1000 ether}();  // 1 ether를 보내면서 deposit 호출
        vm.stopPrank();
    }

    function testProxyInitialize() public {
        vm.startPrank(user);

        pool = new KabiswapPool();

        proxyContract = new SwapProxy(address(pool), address(kabiToken), address(upsideToken), address(LPToken));

        // bytes memory data = abi.encodeWithSignature(
        //     "addLiquidity(uint256,uint256)", 
        //     1, 2
        // );

        // address(proxyContract.proxy()).call(data);
        
        vm.stopPrank();
    }

    // swap 함수 테스트
    function testSwapKabiToUpside() public {
        vm.startPrank(user);

        uint256 amountKabi = 1000 * 10 ** 18;
        uint256 amountUpside = 1000 * 10 ** 18;

        kabiToken.approve(proxyContract.proxy(), amountKabi);
        upsideToken.approve(proxyContract.proxy(), amountUpside);

        // pool.addLiquidity(amountKabi, amountUpside);
        bytes memory data = abi.encodeWithSignature(
            "addLiquidity(uint256,uint256)", 
            amountKabi,
            amountUpside
        );

        address(proxyContract.proxy()).call(data);

        vm.stopPrank();

        vm.startPrank(user2);
        uint256 amountIn = 100 * 10 ** 18;

        // uint256 initialReserveKabi = pool.reserve0();
        // uint256 initialReserveUpside = pool.reserve1();
        (, bytes memory initialReserveKabi) = address(proxyContract.proxy()).call(abi.encodeWithSignature("reserve0()"));
        (, bytes memory initialReserveUpside) = address(proxyContract.proxy()).call(abi.encodeWithSignature("reserve1()"));

        kabiToken.balanceOf(user2);

        kabiToken.approve(proxyContract.proxy(), amountKabi);
        upsideToken.approve(proxyContract.proxy(), amountUpside);

        // swap 실행
        // uint256 amountOut = pool.swap(address(kabiToken), amountIn);
        data = abi.encodeWithSignature(
            "swap(address,uint256)", 
            address(kabiToken),
            amountIn
        );
        (, bytes memory amountOut) = address(proxyContract.proxy()).call(data);

        (, bytes memory finalReserveKabi) = address(proxyContract.proxy()).call(abi.encodeWithSignature("reserve0()"));
        (, bytes memory finalReserveUpside) = address(proxyContract.proxy()).call(abi.encodeWithSignature("reserve1()"));

        kabiToken.balanceOf(user2);
        upsideToken.balanceOf(user2);

        // 수수료를 고려한 기대되는 값 비교
        assertEq(abi.decode(finalReserveKabi, (uint256)), abi.decode(initialReserveKabi, (uint256)) + amountIn, "Kabi token reserve mismatch");
        assertTrue(abi.decode(finalReserveUpside, (uint256)) < abi.decode(initialReserveUpside, (uint256)), "Upside token reserve should increase");
        assertTrue(abi.decode(amountOut, (uint256)) > 0, "Swap output amount should be greater than 0");
        vm.stopPrank();
    }

    function testSwapUpsideToKabi() public {
        vm.startPrank(user);

        uint256 amountKabi = 1000 * 10 ** 18;
        uint256 amountUpside = 1000 * 10 ** 18;

        kabiToken.approve(proxyContract.proxy(), amountKabi);
        upsideToken.approve(proxyContract.proxy(), amountUpside);

        // pool.addLiquidity(amountKabi, amountUpside);
        bytes memory data = abi.encodeWithSignature(
            "addLiquidity(uint256,uint256)", 
            amountKabi,
            amountUpside
        );

        address(proxyContract.proxy()).call(data);

        vm.stopPrank();

        vm.startPrank(user2);
        uint256 amountIn = 100 * 10 ** 18;

        // uint256 initialReserveKabi = pool.reserve0();
        // uint256 initialReserveUpside = pool.reserve1();
        (, bytes memory initialReserveKabi) = address(proxyContract.proxy()).call(abi.encodeWithSignature("reserve0()"));
        (, bytes memory initialReserveUpside) = address(proxyContract.proxy()).call(abi.encodeWithSignature("reserve1()"));

        kabiToken.approve(proxyContract.proxy(), amountKabi);
        upsideToken.approve(proxyContract.proxy(), amountUpside);

        // swap 실행
        // uint256 amountOut = pool.swap(address(upsideToken), amountIn);
        data = abi.encodeWithSignature(
            "swap(address,uint256)", 
            address(upsideToken),
            amountIn
        );
        (, bytes memory amountOut) = address(proxyContract.proxy()).call(data);

        // uint256 finalReserveKabi = pool.reserve0();
        // uint256 finalReserveUpside = pool.reserve1();
        (, bytes memory finalReserveKabi) = address(proxyContract.proxy()).call(abi.encodeWithSignature("reserve0()"));
        (, bytes memory finalReserveUpside) = address(proxyContract.proxy()).call(abi.encodeWithSignature("reserve1()"));

        kabiToken.balanceOf(user2);
        upsideToken.balanceOf(user2);

        // 수수료를 고려한 기대되는 값 비교
        assertEq(abi.decode(finalReserveUpside, (uint256)), abi.decode(initialReserveUpside, (uint256)) + amountIn, "Kabi token reserve mismatch");
        assertTrue(abi.decode(finalReserveKabi, (uint256)) < abi.decode(initialReserveKabi, (uint256)), "Upside token reserve should increase");
        assertTrue(abi.decode(amountOut, (uint256)) > 0, "Swap output amount should be greater than 0");
        vm.stopPrank();
    }

    // addLiquidity 함수 테스트
    function testAddLiquidity() public {
        vm.startPrank(user);

        uint256 amountKabi = 1000 * 10 ** 18;
        uint256 amountUpside = 1000 * 10 ** 18;

        uint256 lpTokensBefore = LPToken.balanceOf(user);

        kabiToken.approve(proxyContract.proxy(), 10000 ether);
        upsideToken.approve(proxyContract.proxy(), 10000 ether);

        // addLiquidity 실행
        // pool.addLiquidity(amountKabi, amountUpside);
        bytes memory data = abi.encodeWithSignature(
            "addLiquidity(uint256,uint256)", 
            amountKabi,
            amountUpside
        );
        address(proxyContract.proxy()).call(data);

        uint256 lpTokensAfter = LPToken.balanceOf(user);

        // LP 토큰 발행 여부 확인
        assertTrue(lpTokensAfter > lpTokensBefore, "LP tokens should be issued after liquidity addition");
        vm.stopPrank();
    }

    // removeLiquidity 함수 테스트
    function testRemoveLiquidity() public {
        vm.startPrank(user);

        uint256 amountKabi = 100 * 10 ** 18;
        uint256 amountUpside = 100 * 10 ** 18;

        kabiToken.approve(proxyContract.proxy(), amountKabi);
        upsideToken.approve(proxyContract.proxy(), amountUpside);

        // 유동성 추가
        // pool.addLiquidity(amountKabi, amountUpside);
        bytes memory data = abi.encodeWithSignature(
            "addLiquidity(uint256,uint256)", 
            amountKabi,
            amountUpside
        );
        address(proxyContract.proxy()).call(data);

        uint256 lpTokens = LPToken.balanceOf(user);

        // 유동성 제거
        uint256 initialKabiBalance = kabiToken.balanceOf(user);
        uint256 initialUpsideBalance = upsideToken.balanceOf(user);

        // pool.removeLiquidity(lpTokens);
        data = abi.encodeWithSignature(
            "removeLiquidity(uint256)", 
            lpTokens
        );
        address(proxyContract.proxy()).call(data);

        uint256 finalKabiBalance = kabiToken.balanceOf(user);
        uint256 finalUpsideBalance = upsideToken.balanceOf(user);

        // Kabi와 Upside가 적절히 반환되었는지 확인
        assertTrue(finalKabiBalance > initialKabiBalance, "Kabi token balance should increase");
        assertTrue(finalUpsideBalance > initialUpsideBalance, "Upside token balance should increase");

        vm.stopPrank();
    }

    // 예외 처리 테스트: 유동성 추가 시 비율이 맞지 않으면 실패
    function testAddLiquidityWithInvalidProportion() public {
        vm.startPrank(user);

        uint256 amountKabi = 1000 * 10 ** 18;
        uint256 amountUpside = 1000 * 10 ** 18;

        kabiToken.approve(proxyContract.proxy(), amountKabi);
        upsideToken.approve(proxyContract.proxy(), amountUpside);

        // pool.addLiquidity(amountKabi, amountUpside);
        bytes memory data = abi.encodeWithSignature(
            "addLiquidity(uint256,uint256)", 
            amountKabi,
            amountUpside
        );
        address(proxyContract.proxy()).call(data);

        vm.stopPrank();

        vm.startPrank(user2);
        
        uint256 amountKabi2 = 1000 * 10 ** 18;
        uint256 amountUpside2 = 500 * 10 ** 18; // 비율이 맞지 않음

        kabiToken.approve(proxyContract.proxy(), amountKabi2);
        upsideToken.approve(proxyContract.proxy(), amountUpside2);

        data = abi.encodeWithSignature(
            "addLiquidity(uint256,uint256)", 
            amountKabi2,
            amountUpside2
        );
        // 비율이 맞지 않으므로 예외가 발생해야 합니다.
        // vm.expectRevert("Liquidity proportion is off");
        // pool.addLiquidity(amountKabi2, amountUpside2);
        (bool success, ) = address(proxyContract.proxy()).call(data);
        require(!success, "Call to proxy contract successed");
        vm.stopPrank();
    }

    // 예외 처리 테스트: swap 시 0보다 작은 값이 들어오면 실패
    function testSwapInvalidAmount() public {
        uint256 invalidAmount = 0;

        // pool.swap(address(kabiToken), invalidAmount);
        bytes memory data = abi.encodeWithSignature(
            "swap(uint256)", 
            invalidAmount
        );
        (bool success, ) = address(proxyContract.proxy()).call(data);
        require(!success, "failed");
    }
}