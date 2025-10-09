// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title CommunitySavings
 * @dev A simple contract for group savings and collective withdrawals.
 */

contract CommunitySavings {
    struct Member {
        address wallet;
        uint256 contribution;
    }

    mapping(address => uint256) public contributions;
    address[] public members;
    uint256 public totalSavings;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function joinGroup() external {
        require(contributions[msg.sender] == 0, "Already a member");
        members.push(msg.sender);
        contributions[msg.sender] = 0;
    }

    function contribute() external payable {
        require(contributions[msg.sender] >= 0, "Not a member");
        contributions[msg.sender] += msg.value;
        totalSavings += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == admin, "Only admin can withdraw");
        require(amount <= address(this).balance, "Insufficient balance");
        payable(admin).transfer(amount);
    }

    function getGroupBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
