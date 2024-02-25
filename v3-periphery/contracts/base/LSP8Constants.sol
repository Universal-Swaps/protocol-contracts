// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP8 = 0x3a271706;

// --- ERC725Y Data Keys

// keccak256('LSP8TokenIdFormat')
bytes32 constant _LSP8_TOKENID_FORMAT_KEY = 0xf675e9361af1c1664c1868cfa3eb97672d6b1a513aa5b81dec34c9ee330e818d;

// --- Token Hooks

// keccak256('LSP8Tokens_SenderNotification')
bytes32 constant _TYPEID_LSP8_TOKENSSENDER = 0xb23eae7e6d1564b295b4c3e3be402d9a2f0776c57bdf365903496f6fa481ab00;

// keccak256('LSP8Tokens_RecipientNotification')
bytes32 constant _TYPEID_LSP8_TOKENSRECIPIENT = 0x0b084a55ebf70fd3c06fd755269dac2212c4d3f0f4d09079780bfa50c1b2984d;

// keccak256('LSP8Tokens_OperatorNotification')
bytes32 constant _TYPEID_LSP8_TOKENOPERATOR = 0x8a1c15a8799f71b547e08e2bcb2e85257e81b0a07eee2ce6712549eef1f00970;

// --- Token IDs Format

uint256 constant _LSP8_TOKENID_FORMAT_NUMBER = 0;