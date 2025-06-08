// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {

    IUniswapV2Router02 public uniswapRouter;
    ERC20Burnable public token;

    uint256 public CASHBACK_RATE = 1;
    uint256 public SILVER_RATE = 100e18;
    uint256 public GOLD_RATE = 1000e18;
    uint256 public PLATINUM_RATE = 10000e18;
    uint256 public SLIPPAGE = 5;

    enum UserStatus { Bronze, Silver, Gold, Platinum }

    event Cashback(address indexed user, uint256 amount);
    event TokensBurned(uint256 amount);

    constructor(uint256 initialSupply, string memory name, string memory symbol, address routerAddress) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        uniswapRouter = IUniswapV2Router02(routerAddress);
        token = ERC20Burnable(address(this));
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        payable(owner()).transfer(balance);
    }

    function setCASHBACK_RATE(uint256 newRate) public onlyOwner {
        CASHBACK_RATE = newRate;
    }

    function setSILVER_RATE(uint256 newRate) public onlyOwner {
        SILVER_RATE = newRate;
    }

    function setGOLD_RATE(uint256 newRate) public onlyOwner {
        GOLD_RATE = newRate;
    }

    function setPLATINUM_RATE(uint256 newRate) public onlyOwner {
        PLATINUM_RATE = newRate;
    }

    function setSLIPPAGE(uint256 newRate) public onlyOwner {
        SLIPPAGE = newRate;
    }

    function buyBack() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH to buy back tokens");

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(this);

        uint256[] memory amountOutMins = uniswapRouter.getAmountsOut(msg.value, path);
        uint256 amountOut = amountOutMins[1];
        uint256 amountOutMin = amountOut - (amountOut * SLIPPAGE / 100);
        uint256 deadline = block.timestamp + 360;

        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            msg.sender,
            deadline
        );

        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output amount");
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    function transferWithCashback(address recipient, uint256 amount) public returns (bool) {
        uint256 cashbackAmount = (amount * CASHBACK_RATE) / 100;
        uint256 transferAmount = amount - cashbackAmount;

        _transfer(_msgSender(), recipient, transferAmount);
        _transfer(_msgSender(), _msgSender(), cashbackAmount);

        emit Cashback(_msgSender(), cashbackAmount);

        return true;
    }

    function getUserStatus(address user) public view returns (UserStatus) {
        uint256 balance = balanceOf(user);

        if (balance >= PLATINUM_RATE) return UserStatus.Platinum;

        if (balance >= GOLD_RATE) return UserStatus.Gold;

        if (balance >= SILVER_RATE) return UserStatus.Silver;

        return UserStatus.Bronze;
    }
}
