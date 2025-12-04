 pragma solidity 0.8.29;

contract SimpleSuicide {

  function sudicideAnyone() public {
    selfdestruct(payable(msg.sender));
  }

}
