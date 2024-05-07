// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract Vault is ReentrancyGuard {
    // Interface for the WETH contract
    IWETH public immutable weth;

    // Mapping from user addresses to their ETH and ERC20 token balances
    mapping(address => uint256) public ethBalances;
    mapping(address => mapping(address => uint256)) private tokenBalances;

    // Event declarations
    event DepositETH(address indexed user, uint256 amount);
    event WithdrawETH(address indexed user, uint256 amount);
    event DepositToken(address indexed token, address indexed user, uint256 amount);
    event WithdrawToken(address indexed token, address indexed user, uint256 amount);
    event WrappedETH(address indexed user, uint256 amount);
    event UnwrappedWETH(address indexed user, uint256 amount);

    // Constructor to set the WETH contract address
    constructor(address _wethAddress) {
        weth = IWETH(_wethAddress);
    }

    // Need to implement receive() and fallback() like this to interact with WETH contract
    receive() external payable {}
    fallback() external payable {}

    // Deposit ETH to the vault
    function depositETH() external payable {
        ethBalances[msg.sender] += msg.value;
        emit DepositETH(msg.sender, msg.value);
    }

    // Withdraw ETH from the vault
    function withdrawETH(uint256 _amount) external nonReentrant {
        require(ethBalances[msg.sender] >= _amount, "Insufficient ETH balance");
        ethBalances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "ETH transfer failed");
        emit WithdrawETH(msg.sender, _amount);
    }

    // Deposit ERC20 tokens to the vault
    function depositTokens(address _token, uint256 _amount) external nonReentrant {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        tokenBalances[_token][msg.sender] += _amount;
        emit DepositToken(_token, msg.sender, _amount);
    }

    // Withdraw ERC20 tokens from the vault
    function withdrawTokens(address _token, uint256 _amount) external nonReentrant {
        require(tokenBalances[_token][msg.sender] >= _amount, "Insufficient token balance");
        tokenBalances[_token][msg.sender] -= _amount;
        require(IERC20(_token).transfer(msg.sender, _amount), "Token transfer failed");
        emit WithdrawToken(_token, msg.sender, _amount);
    }

    // Wrap ETH into WETH within the vault
    function wrapETH(uint256 _amount) external nonReentrant {
        require(ethBalances[msg.sender] >= _amount, "Insufficient ETH balance");
        ethBalances[msg.sender] -= _amount;
        weth.deposit{value: _amount}();
        tokenBalances[address(weth)][msg.sender] += _amount;
        emit WrappedETH(msg.sender, _amount);
    }

    // Unwrap WETH into ETH within the vault
    function unwrapWETH(uint256 _amount) external nonReentrant {
        require(tokenBalances[address(weth)][msg.sender] >= _amount, "Insufficient WETH balance");
        tokenBalances[address(weth)][msg.sender] -= _amount;
        weth.withdraw(_amount);
        ethBalances[msg.sender] += _amount;
        emit UnwrappedWETH(msg.sender, _amount);
    }

    // Function to retrieve a user's balance for a specific token
    function getTokenBalance(address token, address user) public view returns (uint256) {
        return tokenBalances[token][user];
    }
}
