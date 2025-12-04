pragma solidity 0.8.29;

contract Missing_2{
    address private owner;

    modifier onlyowner {
        require(msg.sender==owner);
        _;
    }
    function missing()
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
