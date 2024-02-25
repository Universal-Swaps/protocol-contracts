// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../interfaces/ILSP7DigitalAsset.sol';

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
   function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(ILSP7DigitalAsset.transfer.selector, address(this), to, value, true, '')
        );
        require(success, 'TF');
   }
}
