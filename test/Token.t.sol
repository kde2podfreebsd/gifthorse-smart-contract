// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";

contract TokenTest is Test {
    Token private token;
    address private owner;
    address private recipient;
    IUniswapV2Router02 private uniswapRouter;

    function setUp() public {
        owner = address(this);
        recipient = address(0x1);
        uniswapRouter = IUniswapV2Router02(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008);
        token = new Token(2e27, "Token", "T", address(uniswapRouter));
    }

    function testInitialBalance() public view {
        assertEq(token.balanceOf(owner), 2e27);
    }

    function testInitialSettings() public view {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "T");
        assertEq(token.CASHBACK_RATE(), 1);
        assertEq(token.SILVER_RATE(), 100e18);
        assertEq(token.GOLD_RATE(), 1000e18);
        assertEq(token.PLATINUM_RATE(), 10000e18);
    }

    function testChangeSettings() public {
        vm.prank(owner);

        token.setCASHBACK_RATE(2);
        assertEq(token.CASHBACK_RATE(), 2);

        token.setSILVER_RATE(200e18);
        assertEq(token.SILVER_RATE(), 200e18);

        token.setGOLD_RATE(2000e18);
        assertEq(token.GOLD_RATE(), 2000e18);

        token.setPLATINUM_RATE(20000e18);
        assertEq(token.PLATINUM_RATE(), 20000e18);
    }

    function testFailUnauthorizedSettingsChange() public {
        vm.prank(recipient);

        token.setCASHBACK_RATE(3);
        assertEq(token.CASHBACK_RATE(), 2);

        token.setSILVER_RATE(300e18);
        assertEq(token.SILVER_RATE(), 200e18);

        token.setGOLD_RATE(3000e18);
        assertEq(token.GOLD_RATE(), 2000e18);

        token.setPLATINUM_RATE(30000e18);
        assertEq(token.PLATINUM_RATE(), 20000e18);
    }

    function testTransferWithCashback() public {
        uint256 amountToTransfer = 10e18;
        uint256 expectedRecipientBalance = amountToTransfer - (amountToTransfer * token.CASHBACK_RATE() / 100);
        uint256 expectedOwnerBalance = token.balanceOf(owner) - amountToTransfer + (amountToTransfer * token.CASHBACK_RATE() / 100);

        vm.startPrank(owner);
        bool success = token.transferWithCashback(recipient, amountToTransfer);
        vm.stopPrank();

        assertTrue(success);
        assertEq(token.balanceOf(recipient), expectedRecipientBalance);
        assertEq(token.balanceOf(owner), expectedOwnerBalance);
    }

    function testGetUserStatus() public {
        assertEq(uint(token.getUserStatus(recipient)), uint(Token.UserStatus.Bronze));

        vm.startPrank(owner);
        token.transfer(recipient, 6000e18);
        vm.stopPrank();

        assertEq(uint(token.getUserStatus(recipient)), uint(Token.UserStatus.Gold));
    }

    function testSetSLIPPAGE() public {
        uint256 newRate = 10; 
        token.setSLIPPAGE(newRate);
        
        assertEq(token.SLIPPAGE(), newRate);
    }

    function testBurn() public {
        uint256 initialSupply = token.totalSupply();
        uint256 burnAmount = 100 * 10**18; // Количество токенов для сжигания
        token.burn(burnAmount);
        uint256 finalSupply = token.totalSupply();

        assert(finalSupply < initialSupply);
    }

    function testWithdraw() public {
        uint256 amountToSend = 1 ether;
        payable(address(token)).transfer(amountToSend);
        uint256 contractBalanceBefore = address(token).balance;

        assertEq(contractBalanceBefore, amountToSend);

        uint256 initialBalance = address(this).balance;

        token.withdraw();

        uint256 finalBalance = address(this).balance;
        assert(finalBalance == initialBalance + amountToSend);
    }

    receive() external payable {}
}
