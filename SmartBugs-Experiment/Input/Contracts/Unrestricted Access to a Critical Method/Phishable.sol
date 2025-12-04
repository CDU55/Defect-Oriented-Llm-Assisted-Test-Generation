 pragma solidity 0.8.29;

 contract Phishable {
    address public owner;

    constructor (address _owner) {
        owner = _owner;
    }

    receive() external payable {} 

    function withdrawAll(address payable _recipient) public {
        require(tx.origin == owner);
        payable(_recipient).transfer(address(this).balance);
    }
}
