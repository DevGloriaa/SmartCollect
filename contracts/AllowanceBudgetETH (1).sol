// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract AllowanceBudgetETH {
    struct AllowancePlan {
        address funder;              
        uint totalAmount;           
        uint allowancePerInterval;  
        uint interval;             
        uint lastClaimed;          
        uint remainingBalance;      
    }

    mapping(address => AllowancePlan) public plans;

    event PlanCreated(address indexed funder, address indexed beneficiary, uint totalAmount, uint allowancePerInterval, uint interval);
    event AllowanceClaimed(address indexed beneficiary, uint amount, uint time);

    
    function createPlan(address beneficiary, uint allowancePerInterval, uint interval) external payable {
        require(msg.value > 0, "Must send ETH to fund plan");
        require(plans[beneficiary].funder == address(0), "Plan already exists for this beneficiary");
        require(interval > 0, "Interval must be greater than 0");

        plans[beneficiary] = AllowancePlan({
            funder: msg.sender,
            totalAmount: msg.value,
            allowancePerInterval: allowancePerInterval,
            interval: interval,
            lastClaimed: block.timestamp,
            remainingBalance: msg.value
        });

        emit PlanCreated(msg.sender, beneficiary, msg.value, allowancePerInterval, interval);
    }

    
    function claimAllowance() external {
        AllowancePlan storage plan = plans[msg.sender];
        require(plan.funder != address(0), "No plan exists for this beneficiary");
        require(block.timestamp >= plan.lastClaimed + plan.interval, "Allowance not ready yet");
        require(plan.remainingBalance >= plan.allowancePerInterval, "Not enough balance left");

        plan.lastClaimed = block.timestamp;
        plan.remainingBalance -= plan.allowancePerInterval;

        payable(msg.sender).transfer(plan.allowancePerInterval);

        emit AllowanceClaimed(msg.sender, plan.allowancePerInterval, block.timestamp);
    }

  
    function getPlan(address beneficiary) external view returns (
        address funder,
        uint totalAmount,
        uint allowancePerInterval,
        uint interval,
        uint lastClaimed,
        uint remainingBalance
    ) {
        AllowancePlan memory plan = plans[beneficiary];
        return (
            plan.funder,
            plan.totalAmount,
            plan.allowancePerInterval,
            plan.interval,
            plan.lastClaimed,
            plan.remainingBalance
        );
    }
}
