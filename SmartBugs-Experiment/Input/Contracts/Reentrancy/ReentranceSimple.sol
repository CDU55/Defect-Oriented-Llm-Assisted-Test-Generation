pragma solidity 0.8.29;

 contract ReentranceSimple {
     mapping (address => uint) userBalance;

     function getBalance(address u) public view returns(uint){
         return userBalance[u];
     }

     function addToBalance() public payable{
         userBalance[msg.sender] += msg.value;
     }

     function withdrawBalance() public{
         (bool success, ) = msg.sender.call{value: userBalance[msg.sender]}("");
         if(!success){ revert(); }
         userBalance[msg.sender] = 0;
     }
 }
