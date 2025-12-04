pragma solidity 0.8.29;

contract Reentrance {

  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] += msg.value;
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    require(balances[msg.sender] >= _amount, "Insufficient balance");
    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "Transfer failed");
    balances[msg.sender] -= _amount;
  }

  receive() external payable {}
}
