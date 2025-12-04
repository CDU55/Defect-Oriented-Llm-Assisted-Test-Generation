pragma solidity 0.8.29;
contract EtherBank{
	mapping (address => uint) userBalances;
	function getBalance(address user) public view returns(uint) {
		return userBalances[user];
	}

	function addToBalance() public payable {
		userBalances[msg.sender] += msg.value;
	}

	function withdrawBalance() public {
		uint amountToWithdraw = userBalances[msg.sender];
		(bool success, ) = msg.sender.call{value: amountToWithdraw}("");
		if (!success) { revert(); }
		userBalances[msg.sender] = 0;
	}

	receive() external payable {
	}
}
