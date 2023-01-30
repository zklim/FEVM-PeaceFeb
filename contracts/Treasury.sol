// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract LoanPool {

	uint256 public totalDeposit;
	mapping(address => uint256) public depositBalance;
	address[] public addresses;

	constructor () {}

	function getAddressesLength() public view returns (uint256) {
		return addresses.length;
	}

	function newAddress(address add) public view returns (bool) {
		for (uint256 i = 0; i < addresses.length; i++) {
			if (addresses[i] == add) {
				return false;
			}
		}
		return true;
	}

	function deposit() public payable { 
		require(msg.value > 0, "no amount specified");
		depositBalance[msg.sender] += msg.value;
		totalDeposit += msg.value;

		if (newAddress(msg.sender)) {
			addresses.push(msg.sender);
		}
	}
}

contract Treasury {

	LoanPool public loanContract;
	uint256 public totalInterest;
	mapping(address => uint256) interestBalance;

	constructor (address contractAdd) {
		loanContract = LoanPool(contractAdd);
	}

	function receiveInterest() public payable {
		require(msg.value > 0, "no amount received");
		totalInterest += msg.value;

		uint256 precision = 18;
		uint256 addrCount = loanContract.getAddressesLength();

		for (uint256 i = 0; i < addrCount; i++) {
			address addr = loanContract.addresses(i);
			uint256 deposit = loanContract.depositBalance(addr);
			uint256 totalDeposit = loanContract.totalDeposit();

			uint256 allocation = 
				((deposit * (10 ** precision))
				 / totalDeposit
				 * msg.value)
				 / (10 ** precision);

			interestBalance[addr] += allocation;
		}
	}

	function getAllocation(address addr) public view returns (uint256) {
		return interestBalance[addr];
	}

	function claim() public payable returns (bool) {
		require(!loanContract.newAddress(msg.sender), "not a depositor");
		require(interestBalance[msg.sender] > 0, "no interest earned");

		bool success;
		uint256 amount = interestBalance[msg.sender];
		interestBalance[msg.sender] = 0;
		totalInterest -= amount;

		payable(msg.sender).transfer(amount);

		return success = true;
	}
}