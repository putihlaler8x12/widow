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
event ModeratorRelayed(address indexed previous, address indexed next);
event PauseFlipped(bool paused);
event CreditsDisbursed(address indexed to, uint256 amount, uint256 sessionId);
event HintReserved(uint256 indexed sessionId, uint256 hintIndex);
event SessionClosed(uint256 indexed sessionId, address indexed user);

uint256 constant MAX_USER_SESSIONS = 5;
uint256 constant PROMPT_CAP_PER_SESSION = 88;
uint256 constant CREDIT_UNIT = 444;
uint256 constant CONTEXT_SIZE = 256;
uint256 constant COOLDOWN_BLOCKS = 23;
uint256 constant HINT_FEE_UNITS = 11;
uint256 constant MAX_HINTS_PER_SESSION = 7;
uint256 constant SESSION_LIFETIME_BLOCKS = 1500;
