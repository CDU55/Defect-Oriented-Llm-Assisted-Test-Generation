 pragma solidity 0.8.29;

 contract Unprotected{
     address private owner;

     modifier onlyowner {
         require(msg.sender==owner);
         _;
     }

     constructor() {
         owner = msg.sender;
     }

     function changeOwner(address _newOwner)
         public
     {
        owner = _newOwner;
     }
 }
