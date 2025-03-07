// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Errors.sol";

/**
 * @title TsundereToken
 * @dev A basic ERC-20 token with Tsundere vibes 👺 and advanced functionality
 */
contract TsundereToken {
    // Metadata for the Token
    string public name = "TsundereCoin";
    string public symbol = "TSN";
    uint8 public decimals = 18; // ERC-20 standard to allow the token to be represented as fractions
    uint256 private _totalSupply;
    uint256 private immutable _cap; // Maximum token supply

    // Contract owner with privileged access
    address private _owner;

    // Pause functionality to stop operations in emergency
    bool private _paused;

    // Hashmaps for maintaining balances and allowances
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances; // This address has authorized the following addresses to be able to send x amounts

    // Faucet-related state variables
    uint256 private immutable _faucetAmount;
    mapping(address => bool) private _hasClaimedFaucet;

    // Events to log to blockchain
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event FaucetClaimed(address indexed claimer, uint256 amount);

    // Modifiers for access control and validation
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert ContractPaused();
        _;
    }

    modifier validAmount(uint256 amount) {
        if (amount == 0) revert AmountCannotBeZero();
        _;
    }

    // When the contract is deployed we'll create initial amount of tokens
    constructor(
        uint256 _initialSupply,
        uint256 _capSupply,
        uint256 _faucetTokens
    ) {
        require(_capSupply >= _initialSupply, "Cap must be >= initial supply");

        _owner = msg.sender;
        _cap = _capSupply * 10 ** uint256(decimals);
        _totalSupply = _initialSupply * 10 ** uint256(decimals);
        _balanceOf[msg.sender] = _totalSupply;
        _faucetAmount = _faucetTokens * 10 ** uint256(decimals);

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @notice This method tells the current total supply of tokens
     * @dev It returns the {_totalSupply} private state
     * @return supply The current total amount of tokens
     */
    function totalSupply() external view returns (uint256 supply) {
        return _totalSupply;
    }

    /**
     * @notice Returns the maximum possible token supply
     * @return The cap value
     */
    function cap() external view returns (uint256) {
        return _cap;
    }

    /**
     * @notice Returns the current owner of the contract
     * @return Current owner address
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @notice Checks if the contract is currently paused
     * @return Boolean indicating pause status
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    /**
     * @notice This method returns the amount of tokens owned by a address
     * @dev Returns the value of the {_balanceOf} mapping for the provided account address
     * @param account The address whose token balance needs to be queried
     * @return amount The number of tokens owned by the provided account
     */
    function balanceOf(address account) external view returns (uint256 amount) {
        return _balanceOf[account];
    }

    /**
     * @notice Transfers tokens from your account to another user.
     * @dev This function follows the ERC-20 standard and emits a {Transfer} event.
     *      Ensure `_to` is not the zero address.
     * @param _to The recipient's address.
     * @param _value The amount of tokens to transfer.
     * @return success A boolean indicating whether the transfer was successful.
     */
    function transfer(
        address _to,
        uint256 _value
    ) external whenNotPaused returns (bool success) {
        if (_to == address(0)) revert TransferToZeroAddress();
        if (_value == 0) revert TransferAmountZero();
        if (_balanceOf[msg.sender] < _value)
            revert TransferAmountExceedsBalance(_balanceOf[msg.sender], _value);

        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner_,
        address _spender
    ) public view returns (uint256 amount) {
        return _allowances[owner_][_spender];
    }

    /**
     * @notice Approve other users to spend̉ your tokens on your behalf. Use it carefully!!
     * @dev This function will check if the owner has sufficient funds to allow others to spend them and it emits a {Approval} event.
     * @param _spender The user you're allowing to spend your tokens on your behalf
     * @param _value The amount of tokens you're allowing to be spent on your behalf
     * @return success A boolean that indicates if the approval was successful or not
     */
    function approve(
        address _spender,
        uint256 _value
    ) public whenNotPaused returns (bool success) {
        if (_spender == address(0)) revert ApprovalToZeroAddress();
        if (msg.sender == _spender) revert ApprovalToSelf();
        if (_value > _balanceOf[msg.sender])
            revert ApprovalAmountExceedsBalance(_balanceOf[msg.sender], _value);

        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external whenNotPaused returns (bool success) {
        if (_to == address(0)) revert TransferToZeroAddress();
        if (_from == address(0)) revert TransferFromZeroAddress();
        if (_amount == 0) revert TransferAmountZero();
        // check if the caller is having the authorization and is having the access to funds
        if (_allowances[_from][msg.sender] < _amount)
            revert TransferAmountExceedsAllowance(
                _allowances[_from][msg.sender],
                _amount
            );
        if (_balanceOf[_from] < _amount)
            revert TransferAmountExceedsBalance(_balanceOf[_from], _amount);

        // Else reduce the amount from the allowance, then from the owner's balance then add it to the recepient
        _allowances[_from][msg.sender] -= _amount;
        _balanceOf[_from] -= _amount;

        _balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * @notice Increase the allowance granted to `spender` by the caller
     * @param _spender The address which will spend the funds
     * @param _addedValue The amount to increase the allowance by
     * @return success A boolean indicating whether the operation succeeded
     */
    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) external whenNotPaused validAmount(_addedValue) returns (bool success) {
        if (_spender == address(0)) revert ApprovalToZeroAddress();

        _allowances[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @notice Decrease the allowance granted to `spender` by the caller
     * @param _spender The address which will spend the funds
     * @param _subtractedValue The amount to decrease the allowance by
     * @return success A boolean indicating whether the operation succeeded
     */
    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    )
        external
        whenNotPaused
        validAmount(_subtractedValue)
        returns (bool success)
    {
        if (_spender == address(0)) revert ApprovalToZeroAddress();

        uint256 currentAllowance = _allowances[msg.sender][_spender];
        if (currentAllowance < _subtractedValue)
            revert AllowanceBelowZero(currentAllowance, _subtractedValue);

        _allowances[msg.sender][_spender] = currentAllowance - _subtractedValue;
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @notice Creates new tokens and assigns them to the specified address
     * @param _to Address that will receive the minted tokens
     * @param _amount Amount of tokens to mint
     * @return success A boolean indicating whether the operation succeeded
     */
    function mint(
        address _to,
        uint256 _amount
    )
        external
        onlyOwner
        whenNotPaused
        validAmount(_amount)
        returns (bool success)
    {
        if (_to == address(0)) revert MintToZeroAddress();
        if (_totalSupply + _amount > _cap)
            revert CapExceeded(_totalSupply, _amount, _cap);

        _totalSupply += _amount;
        _balanceOf[_to] += _amount;

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @notice Destroys tokens from the caller's account, reducing total supply
     * @param _amount Amount of tokens to burn
     * @return success A boolean indicating whether the operation succeeded
     */
    function burn(
        uint256 _amount
    ) external whenNotPaused validAmount(_amount) returns (bool success) {
        if (_balanceOf[msg.sender] < _amount)
            revert BurnAmountExceedsBalance(_balanceOf[msg.sender], _amount);

        _balanceOf[msg.sender] -= _amount;
        _totalSupply -= _amount;

        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    /**
     * @notice Pauses all token transfers, to be used in emergency situations
     */
    function pause() external onlyOwner {
        _paused = true;
    }

    /**
     * @notice Unpauses token transfers
     */
    function unpause() external onlyOwner {
        _paused = false;
    }

    /**
     * @notice Transfers ownership of the contract to a new account
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert TransferOwnershipToZeroAddress();
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @notice Returns the amount of tokens a user can claim from the faucet
     * @return The faucet amount in token units
     */
    function faucetAmount() external view returns (uint256) {
        return _faucetAmount;
    }

    /**
     * @notice Checks if an address has already claimed from the faucet
     * @param _claimer The address to check
     * @return Whether the address has claimed from the faucet
     */
    function hasClaimedFaucet(address _claimer) external view returns (bool) {
        return _hasClaimedFaucet[_claimer];
    }

    /**
     * @notice Allows users to claim a preset amount of tokens once per address
     * @return success Boolean indicating whether the claim was successful
     */
    function claimFaucet() external whenNotPaused returns (bool success) {
        // Check if the caller hasn't already claimed
        if (_hasClaimedFaucet[msg.sender]) revert AlreadyClaimedFaucet();

        // Check if minting would exceed the cap
        if (_totalSupply + _faucetAmount > _cap)
            revert CapExceeded(_totalSupply, _faucetAmount, _cap);

        // Update state
        _totalSupply += _faucetAmount;
        _balanceOf[msg.sender] += _faucetAmount;
        _hasClaimedFaucet[msg.sender] = true;

        // Emit events
        emit FaucetClaimed(msg.sender, _faucetAmount);
        emit Mint(msg.sender, _faucetAmount);
        emit Transfer(address(0), msg.sender, _faucetAmount);

        return true;
    }
}
