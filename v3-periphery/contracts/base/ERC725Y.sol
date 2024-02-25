// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IERC725Y.sol';
import './OwnableUnset.sol';
/**
 * @title Core implementation of ERC725Y sub-standard, a general data key/value store.
 * @author Fabian Vogelsteller <fabian@lukso.network>
 * @dev ERC725Y provides the ability to set arbitrary data key/value pairs that can be changed over time.
 * It is intended to standardise certain data key/value pairs to allow automated read and writes from/to the contract storage.
 */
abstract contract ERC725Y is OwnableUnset, IERC725Y {
    /**
     * @dev Map `bytes32` data keys to their `bytes` data values.
     */
    mapping(bytes32 => bytes) internal _store;

    /**
     * @inheritdoc IERC725Y
     */
    function getData(
        bytes32 dataKey
    ) public view virtual override returns (bytes memory dataValue) {
        dataValue = _getData(dataKey);
    }

    /**
     * @inheritdoc IERC725Y
     */
    function getDataBatch(
        bytes32[] memory dataKeys
    ) public view virtual override returns (bytes[] memory dataValues) {
        dataValues = new bytes[](dataKeys.length);

        for (uint256 i = 0; i < dataKeys.length; i++ ) {
            dataValues[i] = _getData(dataKeys[i]);
        }

        return dataValues;
    }

    function setData(
        bytes32 dataKey,
        bytes memory dataValue
    ) public payable virtual override onlyOwner {
        _setData(dataKey, dataValue);
    }

    function setDataBatch(
        bytes32[] memory /*dataKeys*/,
        bytes[] memory /*dataValues*/
    ) public payable virtual override {
        revert();
    }

    /**
     * @dev Read the value stored under a specific `dataKey` inside the underlying ERC725Y storage,
     *  represented as a mapping of `bytes32` data keys mapped to their `bytes` data values.
     *
     * ```solidity
     * mapping(bytes32 => bytes) _store
     * ```
     *
     * @param dataKey A bytes32 data key to read the associated `bytes` value from the store.
     * @return dataValue The `bytes` value associated with the given `dataKey` in the ERC725Y storage.
     */
    function _getData(
        bytes32 dataKey
    ) internal view virtual returns (bytes memory dataValue) {
        return _store[dataKey];
    }

    /**
     * @dev Write a `dataValue` to the underlying ERC725Y storage, represented as a mapping of
     * `bytes32` data keys mapped to their `bytes` data values.
     *
     * ```solidity
     * mapping(bytes32 => bytes) _store
     * ```
     *
     * @param dataKey A bytes32 data key to write the associated `bytes` value to the store.
     * @param dataValue The `bytes` value to associate with the given `dataKey` in the ERC725Y storage.
     */
    function _setData(
        bytes32 dataKey,
        bytes memory dataValue
    ) internal virtual {
        _store[dataKey] = dataValue;
        emit DataChanged(dataKey, dataValue);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == 0x629aa694 || interfaceId == 0x01ffc9a7;
    }
}