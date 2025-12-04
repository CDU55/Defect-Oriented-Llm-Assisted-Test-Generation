pragma solidity 0.8.29;

contract MyContract {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function sendTo(address payable receiver, uint amount) public {
        require(tx.origin == owner);
        receiver.transfer(amount);
    }

}
