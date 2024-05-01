// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract VaultTest is Test {
    Vault vault;
    ERC20Mock weth;
    address user1 = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266); 


    function setUp() public {
        weth = new ERC20Mock();
        vault = new Vault(address(weth));
        vm.label(address(weth), "MockWETH");
        vm.label(address(vault), "Vault");
        vm.label(user1, "User1");
        vm.deal(user1, 10 ether);
        vm.startPrank(user1);
    }

    function testDepositETH() public {
        uint256 amount = 1 ether;
        vm.deal(user1, amount);
        // Send Ether directly to the vault contract (triggers receive)
        (bool success, ) = address(vault).call{value: amount}("");
        // Assert that the transaction was successful
        require(success, "ETH transfer failed");

        // Check user's ETH balance in the vault
        assertEq(vault.ethBalances(user1), amount);
    }

    function testWithdrawETH() public {

        uint256 amount = 1 ether;
        vm.deal(user1, amount);
        (bool success, ) = address(vault).call{value: amount}("");
        require(success, "ETH transfer failed");

        uint256 withdrawAmount = 0.5 ether;
        vault.withdrawETH(withdrawAmount);

        assertEq(vault.ethBalances(user1), 0.5 ether);
    }


    function testDepositAndWithdrawToken() public {
        // Simulate another ERC20 token
        ERC20Mock token = new ERC20Mock();
        uint256 tokenAmount = 100;
        token.mint(address(user1), tokenAmount);
        token.approve(address(vault), tokenAmount);

        // Deposit tokens
        vault.depositTokens(address(token), tokenAmount);

        // Withdraw tokens
        vault.withdrawTokens(address(token), tokenAmount);
        assertEq(token.balanceOf(address(user1)), tokenAmount, "Token balance should be unchanged after deposit and withdrawal");
    }

    // TODO More tests

}
