//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    address private _bridge;

    constructor(
        uint256 _supply,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _supply);
    }

    modifier onlyBridge() {
        require(msg.sender == _bridge, "Access is denied");
        _;
    }

    function setBridgeAddress(address _token) external onlyOwner {
        _bridge = _token;
    }

    function mint(address _to, uint256 _amount) public onlyBridge {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyBridge {
        _burn(_from, _amount);
    }
}
