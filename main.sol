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
uint256 constant TREASURY_SHARE_BPS = 90;
uint256 constant ORACLE_SHARE_BPS = 10;

contract Widow {
    struct SessionRecord {
        address user;
        uint256 createdAtBlock;
        uint256 suggestionCount;
        uint256 completionCredits;
        uint256 contextTokens;
        uint256 hintsClaimed;
        bool closed;
    }

    struct SuggestionSlot {
        uint256 submittedAtBlock;
        bool filled;
    }

    address public immutable moderator_;
    address public immutable treasury_;
    address public immutable oracle_;

    uint256 private _sessionCounter;
    uint256 private _totalCreditsDisbursed;
    bool private _paused;

    mapping(uint256 => SessionRecord) private _sessions;
    mapping(address => uint256[]) private _userSessionIds;
    mapping(uint256 => mapping(uint256 => SuggestionSlot)) private _sessionSuggestions;
    mapping(uint256 => bool) private _completionRecorded;

    modifier onlyModerator() {
        if (msg.sender != moderator_) revert ModeratorOnly();
        _;
    }

    modifier onlyTreasury() {
        if (msg.sender != treasury_) revert TreasuryOnly();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert ContractPaused();
        _;
    }

    constructor() {
        moderator_ = address(0x2A8c4E6f1B3d9F0a5C7e2B4d6F8a0c2E4a6C8e0F);
        treasury_ = address(0x6F1b3D9e5A7c0E2f4B6d8A0c2E4f6A8b0C2d4E6);
        oracle_ = address(0xB4d6F8a0C2e4A6c8E0f2B4d6F8a0C2e4A6c8E0);
        _paused = false;
    }

    function createSession(address user) external onlyModerator whenNotPaused returns (uint256 sessionId) {
        if (user == address(0)) revert ZeroAddressDisallowed();
        uint256[] storage ids = _userSessionIds[user];
        if (ids.length >= MAX_USER_SESSIONS) revert QuotaExceeded();
        sessionId = ++_sessionCounter;
        _sessions[sessionId] = SessionRecord({
            user: user,
            createdAtBlock: block.number,
            suggestionCount: 0,
            completionCredits: 0,
            contextTokens: 0,
            hintsClaimed: 0,
            closed: false
        });
        ids.push(sessionId);
        emit SessionCreated(user, sessionId, block.number);
        return sessionId;
    }

    function submitSuggestion(uint256 sessionId) external onlyModerator whenNotPaused {
        SessionRecord storage s = _sessions[sessionId];
        if (s.user == address(0)) revert InvalidSessionId();
        if (s.closed) revert SessionClosed();
        if (s.suggestionCount >= PROMPT_CAP_PER_SESSION) revert SuggestionCapReached();
        s.suggestionCount++;
        _sessionSuggestions[sessionId][s.suggestionCount] = SuggestionSlot({
            submittedAtBlock: block.number,
            filled: true
        });
        emit SuggestionSubmitted(sessionId, s.suggestionCount, block.number);
    }

    function recordCompletion(uint256 sessionId, address user) external onlyModerator whenNotPaused {
        SessionRecord storage s = _sessions[sessionId];
        if (s.user == address(0)) revert InvalidSessionId();
        if (s.closed) revert SessionClosed();
        if (_completionRecorded[sessionId]) revert CompletionAlreadyRecorded();
        _completionRecorded[sessionId] = true;
        uint256 credits = CREDIT_UNIT;
        s.completionCredits += credits;
        _totalCreditsDisbursed += credits;
        emit CompletionCredited(user, sessionId, credits);
    }

    function updateContextWindow(uint256 sessionId, uint256 newTokens) external onlyModerator whenNotPaused {
        SessionRecord storage s = _sessions[sessionId];
        if (s.user == address(0)) revert InvalidSessionId();
        if (s.closed) revert SessionClosed();
        if (newTokens > CONTEXT_SIZE) revert ContextWindowExceeded();
        s.contextTokens = newTokens;
        emit ContextWindowUpdated(sessionId, newTokens);
    }

    function claimHint(uint256 sessionId) external onlyModerator whenNotPaused {
        SessionRecord storage s = _sessions[sessionId];
        if (s.user == address(0)) revert InvalidSessionId();
        if (s.closed) revert SessionClosed();
        if (s.hintsClaimed >= MAX_HINTS_PER_SESSION) revert HintPoolEmpty();
