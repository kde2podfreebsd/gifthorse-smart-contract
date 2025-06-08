// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Token.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";

contract TokenScript is Script {
    IUniswapV2Router02 public uniswapRouter;

    function setUp() public {}

    function run() public {
        uint privKey = vm.envUint("DEV_PRIV_KEY");
        address account = vm.addr(privKey);

        console.log(account);

        vm.startBroadcast(privKey);

        uint256 initialSupply = 2e27; // 2 billion tokens with 18 decimal places
        string memory name = 'Token';
        string memory symbol = 'T';
        uniswapRouter = IUniswapV2Router02(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008);

        uint256 tokensToAddToLiquidity = 500000e18;
        uint256 ethToAddToLiquidity = 0.01e18;

        Token token = new Token(initialSupply, name, symbol, address(uniswapRouter));

        token.approve(address(uniswapRouter), tokensToAddToLiquidity);

        uint256 deadline = block.timestamp + 20 minutes;

        uniswapRouter.addLiquidityETH{value: ethToAddToLiquidity}(
            address(token),
            tokensToAddToLiquidity,
            tokensToAddToLiquidity,
            ethToAddToLiquidity,
            account,
            deadline
        );

        vm.stopBroadcast();
    }
}