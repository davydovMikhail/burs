//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Token.sol";

contract Burse {
    using SafeERC20 for IERC20;
    mapping(uint256 => Order) private orders; // все ордера
    mapping(address => address) private referrers; // участники реферальной программы
    address tokenACDM; // адрес токена
    uint256 private tokenPrice; // цена одного токена в ETH
    uint256 private roundDuration; // продолжительность раунда(секунды)
    uint256 private timestampStartRound; // метка времни начала раунда (любого)
    uint256 private idOrder; // идентификатор раунда
    uint256 private tradingVolume; // объем (ETH) торгов в режиме Trade ()

    struct Order {
        address seller;
        uint256 amount;
        uint256 price;
    }

    enum Mode {
        Sale,
        Trade
    }

    Mode public mode;

    constructor(
        uint256 _primaryTokenPrice,
        uint256 _primaryTradingVolume,
        uint256 _roundDuration
    ) {
        tokenPrice = _primaryTokenPrice;
        tradingVolume = _primaryTradingVolume;
        roundDuration = _roundDuration;
        timestampStartRound = block.timestamp + _roundDuration;
        idOrder = 0;
        mode = Mode.Trade;
    }

    function register(address _referrer) public {
        require(referrers[msg.sender] != address(0), "You are registered yet");
        require(
            _referrer != msg.sender,
            "You cannot refer yourself as a referral"
        );
        referrers[msg.sender] = _referrer;
    }

    function startSaleRound() public {
        require(
            mode == Mode.Trade,
            "The Sale mode can be set only after the end of the Trade mode"
        );
        require(
            block.timestamp > timestampStartRound + roundDuration,
            "Round trade while lasts"
        );
        timestampStartRound = block.timestamp;
        mode = Mode.Sale;
        if (tradingVolume != 0) {
            Token(tokenACDM).mint(address(this), tradingVolume / tokenPrice);
            tradingVolume = 0;
        }
    }

    function startTradeRound() public {
        require(
            mode == Mode.Sale,
            "The Trade mode can be set only after the end of the Sale mode"
        );
        require(
            block.timestamp > roundDuration + timestampStartRound,
            "Round sale while lasts"
        );
        timestampStartRound = block.timestamp;
        mode = Mode.Trade;
        tokenPrice = (tokenPrice * 1030000 + 4) / 1000000;
        if (tradingVolume != 0) {
            Token(tokenACDM).burn(
                address(this),
                Token(tokenACDM).balanceOf(address(this))
            );
        }
    }

    function buyAcdm() public payable {
        require(mode == Mode.Sale, "Wait for the sale mode to come");
        require(
            block.timestamp < roundDuration + timestampStartRound,
            "Round Sale Finished"
        );
        require(msg.value > 0, "You sent 0 ETH");
        require(
            msg.value / tokenPrice <= Token(tokenACDM).balanceOf(address(this)),
            "You want to buy more tokens than we have"
        );
        if (referrers[msg.sender] != address(0)) {
            payable(referrers[msg.sender]).transfer((msg.value * 3) / 100);
            if (
                referrers[referrers[msg.sender]] != address(0) &&
                referrers[referrers[msg.sender]] != msg.sender
            ) {
                payable(referrers[referrers[msg.sender]]).transfer(
                    (msg.value * 2) / 100
                );
            }
        }
        IERC20(tokenACDM).safeTransferFrom(
            address(this),
            msg.sender,
            msg.value / tokenPrice
        );
    }

    function addOrder(uint256 _amount, uint256 _price)
        public
        returns (uint256)
    {
        IERC20(tokenACDM).safeTransferFrom(msg.sender, address(this), _amount);
        idOrder += 1;
        orders[idOrder] = Order(msg.sender, _amount, _price);
        return idOrder;
    }

    function removeOrder(uint256 _id) public {
        require(
            orders[_id].seller == msg.sender,
            "You are not the owner of this order"
        );
        require(orders[_id].amount != 0, "Order redemeed or removed");
        IERC20(tokenACDM).transfer(msg.sender, orders[_id].amount);
        orders[_id].amount = 0;
    }

    function redeemOrder(uint256 _id) public payable {
        require(mode == Mode.Trade, "Wait for the Trade mode to come");
        require(msg.value > 0, "You sent 0 ETH");
        require(
            msg.value / orders[_id].price <= orders[_id].amount,
            "You sent more than the order price"
        );
        payable(orders[_id].seller).transfer((msg.value * 95) / 100);
        if (referrers[orders[_id].seller] != address(0)) {
            payable(referrers[orders[_id].seller]).transfer(
                (msg.value * 25) / 1000
            );
            if (
                referrers[referrers[orders[_id].seller]] != address(0) &&
                referrers[referrers[orders[_id].seller]] != orders[_id].seller
            ) {
                payable(referrers[referrers[orders[_id].seller]]).transfer(
                    (msg.value * 25) / 1000
                );
            }
        }
        IERC20(tokenACDM).transfer(msg.sender, msg.value / orders[_id].price);
        orders[_id].amount -= msg.value / orders[_id].price;
        tradingVolume += msg.value;
    }
}
