// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

// Command implementations
import {Dispatcher} from './base/Dispatcher.sol';
import {RewardsCollector} from './base/RewardsCollector.sol';
import {RouterParameters} from './base/RouterImmutables.sol';
import {PaymentsImmutables, PaymentsParameters} from './modules/PaymentsImmutables.sol';
import {NFTImmutables, NFTParameters} from './modules/NFTImmutables.sol';
import {UniswapImmutables, UniswapParameters} from './modules/uniswap/UniswapImmutables.sol';
import {Commands} from './libraries/Commands.sol';
import {IUniversalRouter} from './interfaces/IUniversalRouter.sol';
import {BytesLib} from './modules/uniswap/v3/BytesLib.sol';

interface ILSP7 {
    function authorizedAmountFor(address operator, address tokenOwner) external view returns (uint256);
    function transferBatch(address[] memory from, address[] memory to, uint256[] memory amount, bool[] memory force, bytes[] memory data) external;
    function transfer(address from, address to, uint256 amount, bool force, bytes memory data) external;
    function balanceOf(address account) external view returns (uint256);
}

contract UniversalRouter is IUniversalRouter, Dispatcher, RewardsCollector {
    uint256 private _allowance;
    using BytesLib for *;

    bytes4 internal constant _EXECUTE_SELECTOR = 0x24856bc3; // execute(bytes,bytes[])

    bytes4 internal constant _EXECUTE_SELECTOR_WITH_DEADLINE = 0x3593564c; // execute(bytes,bytes[],uint256)

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert TransactionDeadlinePassed();
        _;
    }

    constructor(RouterParameters memory params)
        UniswapImmutables(
            UniswapParameters(params.v2Factory, params.v3Factory, params.pairInitCodeHash, params.poolInitCodeHash)
        )
        PaymentsImmutables(PaymentsParameters(params.permit2, params.weth9, params.openseaConduit, params.sudoswap))
        NFTImmutables(
            NFTParameters(
                params.seaportV1_5,
                params.seaportV1_4,
                params.nftxZap,
                params.x2y2,
                params.foundation,
                params.sudoswap,
                params.elementMarket,
                params.nft20Zap,
                params.cryptopunks,
                params.looksRareV2,
                params.routerRewardsDistributor,
                params.looksRareRewardsDistributor,
                params.looksRareToken
            )
        )
    {}

    /// @inheritdoc IUniversalRouter
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        payable
        checkDeadline(deadline)
    {
        execute(commands, inputs);
    }

    /// @inheritdoc Dispatcher
    function execute(bytes calldata commands, bytes[] calldata inputs) public payable override isNotLocked(msg.sender) {
        bool success;
        bytes memory output;
        uint256 numCommands = commands.length;
        if (inputs.length != numCommands) revert LengthMismatch();

        // loop through all given commands, execute them and pass along outputs as defined
        for (uint256 commandIndex = 0; commandIndex < numCommands;) {
            bytes1 command = commands[commandIndex];

            bytes calldata input = inputs[commandIndex];

            (success, output) = dispatch(command, input);

            if (!success && successRequired(command)) {
                revert ExecutionFailed({commandIndex: commandIndex, message: output});
            }

            unchecked {
                commandIndex++;
            }
        }
    }

    function successRequired(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_ALLOW_REVERT == 0;
    }

    /// @notice To receive ETH from WETH and NFT protocols
    receive() external payable {}

    function _execute(
        bytes calldata commands,
        bytes[] calldata inputs,
        address from
    ) internal isNotLocked(from) {
        bool success;
        bytes memory output;
        uint256 numCommands = commands.length;
        if (inputs.length != numCommands) revert LengthMismatch();

        // loop through all given commands, execute them and pass along outputs as defined
        for (uint256 commandIndex = 0; commandIndex < numCommands; ) {
            bytes1 command = commands[commandIndex];

            bytes calldata input = inputs[commandIndex];

            (success, output) = dispatch(command, input);

            if (!success && successRequired(command)) {
                revert ExecutionFailed({commandIndex: commandIndex, message: output});
            }

            unchecked {
                commandIndex++;
            }
        }
    }

    /**
     * @param typeId TypeId related to performing a swap
     * @param data The `lsp1Data` sent by the function `authorizeOperator(address,uint256,bytes)` when the internal hook below was triggered:
     *
     * User --> calls `authorizeOperator(...)` on LSP7 token to swap with parameters:
     *  | address: router contract
     *  | uint256: amount to swap
     *  | bytes: operatorNotificationData -> abi-encoded function call of `execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)`
     *  V
     *
     * Triggered internally by the function `_notifyTokenOperator(...)` with lsp1Data
     *
     * ```
     * abi.encode(address msg.sender (user), uint256 amount, bytes memory operatorNotificationData)
     * ```
     *
     * execute(bytes,bytes[],uint256) selector -> 0x3593564c
     *
     * Tokens that authorize and dont call the universalReceiver on authorization, will get front-runned
     */
    function universalReceiver(bytes32 typeId, bytes calldata data) public returns (bytes memory) {
        if (typeId == 0x386072cc5a58e61263b434c722725f21031cd06e7c552cfaa06db5de8a320dbc) {
            // `authorizeOperator(address,uint256,bytes)` calldata (example)
            // --------------------
            address from = address(uint160(uint256(bytes32(data[:32]))));

            // The `lsp1Data` sent by `authorizeOperator(...)` contains 3 arguments:
            // - address: msg.sender (user) -> 32 bytes
            // - uint256: amount authorize -> 32 bytes
            // - bytes: operatorNotificationData -> which starts with bytes4 selector of `execute(bytes,bytes[],uint256)`
            // 32 + 32 + 4 = 68 (take the next 32 bytes from it)
            uint256 operationNotificationDataOffset = uint256(bytes32(data[64:96]));

            // if no data then revert
            if (uint256(bytes32(data[96:128])) == 0) revert("Authorization and Swap must happen in the same tx");
            // excluding the selector (+4)
            bytes calldata callDataForSwap = data[operationNotificationDataOffset + 32 + 4:];

            bytes4 executeSelectorToRun = bytes4(data[128:132]);
            bytes calldata commands = callDataForSwap.toBytes(0);
            bytes[] calldata inputs = callDataForSwap.toBytesArray(1);

            if (executeSelectorToRun == _EXECUTE_SELECTOR_WITH_DEADLINE) {
                uint256 deadline = uint256(bytes32(callDataForSwap[64:96]));
                if (block.timestamp > deadline) revert TransactionDeadlinePassed();
                _execute(commands, inputs, from);
            } else if (executeSelectorToRun == _EXECUTE_SELECTOR) {
                _execute(commands, inputs, from);
            } else {
                revert('Invalid selector');
            }

            // making sure that there are no authorized amount left over and send it back to owner if that is the case
            uint256 remainingAuthorizedAmount = ILSP7(msg.sender).authorizedAmountFor(address(this), from);
            if(remainingAuthorizedAmount != 0) {
                // We can use batchCalls but lets use explicit calls for now
                ILSP7(msg.sender).transfer(from, address(this), remainingAuthorizedAmount, true, "");
                uint256 remainingBalance = ILSP7(msg.sender).balanceOf(address(this));
                ILSP7(msg.sender).transfer(address(this), from, remainingBalance, true, "");
            }

        }
        return abi.encodePacked(true);
    }
}
