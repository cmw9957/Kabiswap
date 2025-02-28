// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "forge-std/Script.sol";
import "../src/KabiswapERC20.sol";
import "../src/UpsideERC20.sol";
import "../src/KabiLPtoken.sol";
import "../src/KabiswapPool.sol";
import "../src/SwapProxy.sol";

// api-key : EYY38QU8ZBHY8Z1V4CJW88KVAMSNGUKWEQ
// 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
contract DeployKabiswap is Script {
    function run() external {
        vm.startBroadcast();
        // KabiswapERC20 kabiswapToken = new KabiswapERC20();
        // UpsideERC20 upsideToken = new UpsideERC20();
        // KabiLPtoken LPtoken = new KabiLPtoken();

        // string memory addLiquiditySignature = "addLiquidity(uint256,uint256)";
        // string memory swapSignature = "swap(address,uint256)";
        // string memory removeLiquidity = "removeLiquidity(uint256)";

        // KabiswapPool pool = new KabiswapPool();
        // SwapProxy proxyContract = new SwapProxy(address(pool), address(kabiswapToken), address(upsideToken), address(LPtoken));
        
        // address proxy = proxyContract.proxy();
        // address me = 0x97A008FE1887b1448313b69F4324194a8e2a739D;

        // uint256 amountKabi = KabiswapERC20(kabiswapToken).balanceOf(me);
        // uint256 amountUpside = UpsideERC20(upsideToken).balanceOf(me);

        // KabiswapERC20(kabiswapToken).approve(proxy, amountKabi);
        // UpsideERC20(upsideToken).approve(proxy, amountUpside);

        // proxy.call(abi.encodeWithSignature(
        //     addLiquiditySignature, 
        //     amountKabi,
        //     amountUpside
        // ));

        // KabiLPtoken(LPtoken).balanceOf(me);

        // console.log("Proxy address : ", proxy);
        // console.log("Kabitoken address : ", address(kabiswapToken));
        // console.log("Upsidetoken address : ", address(upsideToken));
        // console.log("LPtoken address : ", address(LPtoken));

        address me = 0x97A008FE1887b1448313b69F4324194a8e2a739D;

        KabiswapERC20 kabiswapToken = KabiswapERC20(0x3b001C70e386BFAfc8053b2851Ccd400A67d61e4);
        UpsideERC20 upsideToken = UpsideERC20(0x2420e1F5DD223716fAa51BCf51196F7555cAD229);
        KabiLPtoken LPtoken = KabiLPtoken(0xE880e43C440100E1A24Ce1d2B468Da62B31fD53a);

        string memory addLiquiditySignature = "addLiquidity(uint256,uint256)";
        string memory swapSignature = "swap(address,uint256)";
        string memory removeLiquiditySignature = "removeLiquidity(uint256)";
        string memory resumeSignature = "resume()";

        kabiswapToken.mint(me, 1 ether);

        address proxy = 0xBC2FEba25F0C9585624CE7f809316C37E17dC1c9;

        console.log("before My Kabitoken balance : ", kabiswapToken.balanceOf(me));
        console.log("before My Upsidetoken balance : ", upsideToken.balanceOf(me));
        console.log("before My LPtoken balance : ", LPtoken.balanceOf(me));

        kabiswapToken.approve(proxy, 1 ether);

        proxy.call(abi.encodeWithSignature(swapSignature, address(kabiswapToken), 1 ether));

        bytes memory test = abi.encodeWithSignature(swapSignature, address(kabiswapToken), 1 ether);

        console.logBytes(test);

        console.log("after My Kabitoken balance : ", kabiswapToken.balanceOf(me));
        console.log("after My Upsidetoken balance : ", upsideToken.balanceOf(me));
        console.log("after My LPtoken balance : ", LPtoken.balanceOf(me));

        vm.stopBroadcast();
    }
}