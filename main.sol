// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Widow
 * @notice Next-gen coding assistant ledger: session lifecycle, suggestion caps, completion credits,
 *         and context-window tracking. Moderator and treasury set at deploy; safe for mainnet.
 */

error ModeratorOnly();
error SessionClosed();
error QuotaExceeded();
error HintPoolEmpty();
error ZeroAddressDisallowed();
