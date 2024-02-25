// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ILSP7DigitalAsset {

    function transfer(address from, address to, uint256 amount, bool force, bytes memory data) external;
    function authorizeOperator(address operator, uint256 amount, bytes memory data) external;
}

import {ERC20} from 'solmate/src/tokens/ERC20.sol';

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library LSP7SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
       (bool success, ) = address(token).call(abi.encodeWithSelector(ILSP7DigitalAsset.transfer.selector, from, to, amount, true, ""));
        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
       (bool success, ) = address(token).call(abi.encodeWithSelector(ILSP7DigitalAsset.transfer.selector, address(this), to, amount, true, ""));
        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
       (bool success, ) = address(token).call(abi.encodeWithSelector(ILSP7DigitalAsset.authorizeOperator.selector, to, amount, ""));
        require(success, "APPROVE_FAILED");
    }
}