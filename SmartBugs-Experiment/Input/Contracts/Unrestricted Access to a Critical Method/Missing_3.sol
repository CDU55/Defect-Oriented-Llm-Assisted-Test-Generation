 pragma solidity 0.8.29;

contract Missing_3{
    address private owner;

    modifier onlyowner {
        require(msg.sender==owner);
        _;
    }
    
    function Constructor()
        public
    {
        owner = msg.sender;
    }

    receive() external payable {}

    function withdraw()
        public
        onlyowner
    {
       payable(owner).transfer(address(this).balance);
    }

}
