// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SwapProxy {
    address public admin;
    address public proxy;

    constructor(address _implementation, address _token0, address _token1, address _token2) {
        // ProxyAdmin 인스턴스 생성
        ProxyAdmin adminInstance = new ProxyAdmin(msg.sender);
        admin = address(adminInstance);

        // TransparentUpgradeableProxy 생성, data 인자로 initialize 함수 호출
        bytes memory initializeData = abi.encodeWithSignature(
            "initialize(address,address,address)", 
            _token0, 
            _token1, 
            _token2
        );

        TransparentUpgradeableProxy proxyInstance = new TransparentUpgradeableProxy(
            _implementation,  // _implementation 주소
            admin,            // 관리자로 ProxyAdmin 설정
            initializeData    // 초기화 함수 호출을 위한 data
        );
        
        proxy = address(proxyInstance);  // 프록시 주소 저장
    }
}
