//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    address private _burse;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    modifier onlyBurse() {
        require(msg.sender == _burse, "Access is denied");
        _;
    }

    function setBurseAddress(address _token) external onlyOwner {
        _burse = _token;
    }

    function mint(address _to, uint256 _amount) public onlyBurse {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyBurse {
        _burn(_from, _amount);
    }
}
