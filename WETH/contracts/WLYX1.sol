// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/LSP7DigitalAsset.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract WLYX1 is LSP7DigitalAsset {
    // events
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    constructor() LSP7DigitalAsset("WrappedLYX1", "WLYX1", msg.sender, 0, false) {
        // Add metadata and creators post deployment
    }

    receive() external payable override {
        deposit();
    }

    fallback() external payable override {
        deposit();
    }

    function deposit() public payable {
        _tokenOwnerBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(_tokenOwnerBalances[msg.sender] >= wad);
        _tokenOwnerBalances[msg.sender] -= wad;
        (bool success, bytes memory returnedData) = msg.sender.call{value: wad}(
            new bytes(0)
        );

        Address.verifyCallResult(
            success,
            returnedData,
            "WLYX: withdraw failed"
        );
        emit Withdrawal(msg.sender, wad);
    }

    // gas optimization
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    // address.balance here is safe to not be equal to all "_tokenOwnerBalances"
    // in case of seldestruct, won't cause any issues
    function totalSupply() public view override returns (uint) {
        return address(this).balance;
    }
}
