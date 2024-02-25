// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;

/**
 * @title Interface of the LSP1 - Universal Receiver Delegate standard.
 * @dev This interface allows contracts implementing the LSP1UniversalReceiver function to delegate the reaction logic to another contract or account. By doing so, the main logic doesn't need to reside within the `universalReceiver` function itself, offering modularity and flexibility.
 */
interface ILSP1UniversalReceiver {
    /**
     * @dev Generic function that can be used to notify the contract about specific incoming transactions or events like asset transfers, vault transfers, etc. Allows for custom on-chain and off-chain reactions based on the `typeId` and `data`.
     * @notice Reacted on received notification with `typeId` & `data`.
     *
     * @param typeId The hash of a specific standard or a hook.
     * @param data The arbitrary data received with the call.
     */
    function universalReceiver(
        bytes32 typeId,
        bytes calldata data
    ) external payable returns (bytes memory);
}
