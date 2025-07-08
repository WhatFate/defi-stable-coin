// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedStableCoin
 * @author WhatFate
 * @notice ERC20 token representing an algorithmic, exogenously collateralized stablecoin.
 * @dev This contract is controlled by the DSCEngine contract which governs minting and burning.
 *      Only the owner (DSCEngine) can mint and burn tokens.
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    /// @notice Error for minting or burning zero or negative amounts
    error DecentralizedStableCoin__MustBeMoreThanZero();

    /// @notice Error for attempting to burn more tokens than balance
    error DecentralizedStableCoin__BurnAmountExceedsBalance();

    /// @notice Error for using the zero address as target or mint
    error DecentralizedStableCoin__NotZeroAddress();

    /// @notice Immutable owner address set during construction
    address private immutable i_owner;

    /**
     * @notice Constructs the stablecoin and sets the initial owner.
     * @dev Calls ERC20 constructor with name and symbol.
     *      Owner is set via Ownable constructor with msg.sender.
     */
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {
        i_owner = msg.sender;
    }

    /**
     * @notice Burns `_amount` tokens from the owner's balance.
     * @dev Only callable by the owner. Amount must be > 0 and not exceed owner's balance.
     *      Overrides ERC20Burnable's burn with additional checks.
     * @param _amount The amount of tokens to burn.
     */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    /**
     * @notice Mints `_amount` tokens to address `_to`.
     * @dev Only callable by the owner. `_to` must not be zero address. `_amount` must be > 0.
     * @param _to The address to receive minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return bool Returns true if minting succeeded.
     */
    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
