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
error ContractPaused();
error InvalidSessionId();
error SuggestionCapReached();
error ContextWindowExceeded();
error CompletionAlreadyRecorded();
error HintAlreadyClaimed();
error SessionNotActive();
error CooldownNotElapsed();
error TreasuryOnly();

event SessionCreated(address indexed user, uint256 sessionId, uint256 atBlock);
event SuggestionSubmitted(uint256 indexed sessionId, uint256 suggestionIndex, uint256 atBlock);
event CompletionCredited(address indexed user, uint256 sessionId, uint256 creditUnits);
event ContextWindowUpdated(uint256 indexed sessionId, uint256 newSize);
