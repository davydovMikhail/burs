//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Token.sol";

contract Burse {
    using SafeERC20 for IERC20;
    mapping(uint256 => Order) private orders;
    mapping(address => address) private referrers;
    address tokenACDM;
    uint256 private tokenPrice;
    uint256 private roundNumber;
    uint256 private roundDuration;
    uint256 private timestampStartRound;
    uint256 private idOrder;
    uint256 private tradingVolume;

    struct Order {
        address seller;
        uint256 amount;
        uint256 price;
    }

    enum Mode {
        Sale,
        AfterSale,
        Trade,
        AfterTrade
    }

    Mode public mode;

    constructor(uint256 _tokenPrice, uint256 _tradingVolume) {
        tokenPrice = _tokenPrice;
        tradingVolume = _tradingVolume;
        idOrder = 1;
    }

    function register(address _referrer) public {
        require(referrers[msg.sender] != address(0), "You are registered yet");
        referrers[msg.sender] = _referrer;
    }

    function startSaleRound() public {
        require(
            mode == Mode.Trade,
            "The Sale mode can be set only after the end of the Trade mode"
        );
        require(block.timestamp < timestampStartRound + roundDuration);
        timestampStartRound = block.timestamp;
        mode = Mode.Sale;
    }

    // function startTradeRound() public {

    // }

    function buyAcdm() public payable {
        require(mode == Mode.Sale, "Wait for the sale mode to come");
        // require(
        //     block.timestamp < roundDuration + timestampStartRound,
        //     "Round Finished"
        // );
        require(msg.value > 0, "You sent 0 ETH");
        if (referrers[msg.sender] != address(0)) {
            payable(referrers[msg.sender]).transfer((msg.value * 3) / 100);
            if (referrers[referrers[msg.sender]] != address(0)) {
                payable(referrers[referrers[msg.sender]]).transfer(
                    (msg.value * 2) / 100
                );
            }
        }
        uint256 memory amount = msg.value / tokenPrice;
        IERC20(tokenACDM).safeTransferFrom(msg.sender, address(this), amount);
    }

    function addOrder(uint256 _amount, uint256 _price) public {
        IERC20(tokenACDM).safeTransferFrom(msg.sender, address(this), _amount);
        orders[idOrder] = Order(msg.sender, _amount, _price);
        idOrder += 1;
    }

    function removeOrder(uint256 _id) public {
        require(
            orders[_id].seller == msg.sender,
            "You are not the owner of this order"
        );
        require(orders[_id].amount != 0, "Order redemeed or removed");
        IERC20(tokenACDM).transferFrom(msg.sender, orders[msg.sender].amount);
        orders[_id].amount = 0;
    }

    function redeemOrder(uint256 _id) public payable {
        require(msg.value > 0, "You sent 0 ETH");
        payable(orders[_id].seller).transfer((msg.value * 95) / 100);
        if (referrers[orders[_id].seller] != address(0)) {
            payable(referrers[orders[_id].seller]).transfer(
                (msg.value * 25) / 1000
            );
            if (referrers[referrers[orders[_id].seller]] != address(0)) {
                payable(referrers[referrers[orders[_id].seller]]).transfer(
                    (msg.value * 25) / 1000
                );
            }
        }
    }
}
