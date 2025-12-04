pragma solidity 0.8.29;

contract PENNY_BY_PENNY  
{
    struct Holder   
    {
        uint unlockTime;
        uint balance;
    }
    
    mapping (address => Holder) public Acc;
    
    uint public MinSum;
    
    LogFile Log;
    
    bool intitalized;
    
    function SetMinSum(uint _val)
    public
    {
        require(!intitalized);
        MinSum = _val;
    }
    
    function SetLogFile(address _log)
    public
    {
        require(!intitalized);
        Log = LogFile(_log);
    }
    
    function Initialized()
    public
    {
        intitalized = true;
    }
    
    function Put(uint _lockTime)
    public
    payable
    {
        Holder storage acc = Acc[msg.sender];
        acc.balance += msg.value;
        if(block.timestamp + _lockTime > acc.unlockTime) acc.unlockTime = block.timestamp + _lockTime;
        Log.AddMessage(msg.sender,msg.value,"Put");
    }
    
    function Collect(uint _am)
    public
    payable
    {
        Holder storage acc = Acc[msg.sender];
        if( acc.balance>=MinSum && acc.balance>=_am && block.timestamp>acc.unlockTime)
        {
            (bool success, ) = msg.sender.call{value: _am}("");
            if(success)
            {
                acc.balance-=_am;
                Log.AddMessage(msg.sender,_am,"Collect");
            }
        }
    }
    
    receive() external payable {
        Put(0);
    }
    
}


contract LogFile
{
    struct Message
    {
        address Sender;
        string  Data;
        uint Val;
        uint  Time;
    }
    
    Message[] public History;
    
    Message LastMsg;
    
    function AddMessage(address _adr,uint _val,string memory _data) public {
        LastMsg.Sender = _adr;
        LastMsg.Time = block.timestamp;
        LastMsg.Val = _val;
        LastMsg.Data = _data;
        History.push(LastMsg);
    }
}