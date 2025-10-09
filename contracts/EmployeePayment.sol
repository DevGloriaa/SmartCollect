// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title EmployeePayment
 * @dev Simple payroll system for small teams.
 */

contract EmployeePayment {
    address public employer;

    struct Employee {
        address wallet;
        uint256 salary;
        bool exists;
    }

    mapping(address => Employee) public employees;

    constructor() {
        employer = msg.sender;
    }

    modifier onlyEmployer() {
        require(msg.sender == employer, "Not authorized");
        _;
    }

    function addEmployee(
        address _wallet,
        uint256 _salary
    ) external onlyEmployer {
        employees[_wallet] = Employee(_wallet, _salary, true);
    }

    function payEmployee(address _wallet) external payable onlyEmployer {
        Employee memory emp = employees[_wallet];
        require(emp.exists, "Employee not found");
        require(address(this).balance >= emp.salary, "Insufficient funds");

        payable(emp.wallet).transfer(emp.salary);
    }

    function fundContract() external payable onlyEmployer {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
