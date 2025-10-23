import hre from "hardhat";
const { ethers } = hre;

async function main() {
  console.log("Deploying contracts...");

  const SmartAllowance = await ethers.getContractFactory("SmartAllowance");
  const smartAllowance = await SmartAllowance.deploy();
  await smartAllowance.waitForDeployment();
  console.log("SmartAllowance deployed to:", smartAllowance.target);

 
  const CommunitySavings = await ethers.getContractFactory("CommunitySavings");
  const communitySavings = await CommunitySavings.deploy();
  await communitySavings.waitForDeployment();
  console.log("CommunitySavings deployed to:", communitySavings.target);

const EmployeePayment = await ethers.getContractFactory("EmployeePayment");
const employeePayment = await EmployeePayment.deploy();
await employeePayment.waitForDeployment();
console.log("EmployeePayment deployed to:", employeePayment.target);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
