// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SmartAllowanceV2 {
    struct AllowancePlan {
        uint id;
        address funder;
        address beneficiary;
        string name;
        string category;
        uint totalAmount;            // wei
        uint allowancePerInterval;   // wei unlocked each interval
        uint interval;               // seconds
        uint lastClaimed;            // timestamp
        uint remainingBalance;       // wei
        bool active;
    }

    uint private nextPlanId = 1;
    mapping(uint => AllowancePlan) public plans;                          // planId -> Plan
    mapping(address => uint[]) public plansByFunder;                      // funder -> planIds
    mapping(address => uint[]) public plansByBeneficiary;                 // beneficiary -> planIds

    event PlanCreated(uint indexed planId, address indexed funder, address indexed beneficiary, uint totalAmount, uint allowancePerInterval, uint interval, string name, string category);
    event AllowanceClaimed(uint indexed planId, address indexed beneficiary, uint amount, uint time);
    event PlanFunded(uint indexed planId, uint amount, uint time);
    event PlanClosed(uint indexed planId, uint time);

    modifier onlyFunder(uint planId) {
        require(plans[planId].funder == msg.sender, "Only funder");
        _;
    }

    modifier onlyBeneficiary(uint planId) {
        require(plans[planId].beneficiary == msg.sender, "Only beneficiary");
        _;
    }

    /// @notice Create a new named allowance plan and fund it (msg.value).
    /// @param beneficiary The address that can claim from this plan.
    /// @param allowancePerInterval Amount (wei) allowed each interval.
    /// @param interval Seconds between allowed claims.
    /// @param name Human name for the plan.
    /// @param category Category label (e.g. "Clothes", "Birthday").
    function createPlan(
        address beneficiary,
        uint allowancePerInterval,
        uint interval,
        string calldata name,
        string calldata category
    ) external payable returns (uint) {
        require(msg.value > 0, "Must send ETH to fund plan");
        require(beneficiary != address(0), "Invalid beneficiary");
        require(interval > 0, "Interval must be > 0");
        require(allowancePerInterval > 0, "Allowance must be > 0");

        uint pid = nextPlanId++;
        AllowancePlan storage p = plans[pid];
        p.id = pid;
        p.funder = msg.sender;
        p.beneficiary = beneficiary;
        p.name = name;
        p.category = category;
        p.totalAmount = msg.value;
        p.allowancePerInterval = allowancePerInterval;
        p.interval = interval;
        p.lastClaimed = block.timestamp;
        p.remainingBalance = msg.value;
        p.active = true;

        plansByFunder[msg.sender].push(pid);
        plansByBeneficiary[beneficiary].push(pid);

        emit PlanCreated(pid, msg.sender, beneficiary, msg.value, allowancePerInterval, interval, name, category);
        return pid;
    }

    /// @notice Add funds to existing plan (only funder).
    function addFunds(uint planId) external payable onlyFunder(planId) {
        require(plans[planId].active, "Plan not active");
        require(msg.value > 0, "Send ETH to add");
        plans[planId].totalAmount += msg.value;
        plans[planId].remainingBalance += msg.value;
        emit PlanFunded(planId, msg.value, block.timestamp);
    }

    /// @notice Claim the allowance for a plan. Fixed amount per interval.
    function claimAllowance(uint planId) external {
        AllowancePlan storage p = plans[planId];
        require(p.active, "Plan not active");
        require(p.beneficiary == msg.sender, "Not beneficiary");
        require(block.timestamp >= p.lastClaimed + p.interval, "Allowance not ready yet");
        require(p.remainingBalance >= p.allowancePerInterval, "Not enough balance left");

        p.lastClaimed = block.timestamp;
        p.remainingBalance -= p.allowancePerInterval;

        // transfer unlocked amount
        payable(msg.sender).transfer(p.allowancePerInterval);

        emit AllowanceClaimed(planId, msg.sender, p.allowancePerInterval, block.timestamp);
    }

    /// @notice Close a plan and withdraw remaining funds to funder. Only funder.
    function closePlan(uint planId) external onlyFunder(planId) {
        AllowancePlan storage p = plans[planId];
        require(p.active, "Plan not active");
        uint remaining = p.remainingBalance;
        p.remainingBalance = 0;
        p.active = false;

        if (remaining > 0) {
            payable(p.funder).transfer(remaining);
        }

        emit PlanClosed(planId, block.timestamp);
    }

    /// @notice Returns plan IDs for a funder
    function getPlansByFunder(address funder) external view returns (uint[] memory) {
        return plansByFunder[funder];
    }

    /// @notice Returns plan IDs for a beneficiary
    function getPlansByBeneficiary(address beneficiary) external view returns (uint[] memory) {
        return plansByBeneficiary[beneficiary];
    }

    /// @notice Return full plan details
    function getPlan(uint planId) external view returns (
        uint id,
        address funder,
        address beneficiary,
        string memory name,
        string memory category,
        uint totalAmount,
        uint allowancePerInterval,
        uint interval,
        uint lastClaimed,
        uint remainingBalance,
        bool active
    ) {
        AllowancePlan memory p = plans[planId];
        return (
            p.id,
            p.funder,
            p.beneficiary,
            p.name,
            p.category,
            p.totalAmount,
            p.allowancePerInterval,
            p.interval,
            p.lastClaimed,
            p.remainingBalance,
            p.active
        );
    }

    receive() external payable {
        revert("Direct deposits not allowed; call createPlan or addFunds");
    }
}
