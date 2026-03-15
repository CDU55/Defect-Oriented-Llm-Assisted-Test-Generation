// Generation Time: 25,83s
// Input Tokens: 2513
// Output Tokens: 1326
// Reasoning Tokens: 746

// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract TestComplexFallbackCrowdfund is Test {

    Crowdfund public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Crowdfund();
    }

    function test_highlightGasNeededIsOver2300(uint256 amount) public {
        
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        vm.deal(address(this), amount * 2);

        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        require(success, "Call to receive() failed");

        uint256 gasUsed = gasBefore - gasAfter;
        
        assertTrue(gasUsed >= 2300, "Gas used does not exceed 2300");
    }
}

contract TransferHelper {
    function sendViaTransfer(address payable recipient, uint256 amount) external {
        recipient.transfer(amount);
    }
}

contract SendHelper {
    function sendViaSend(address payable recipient, uint256 amount) external returns (bool) {
        return recipient.send(amount);
    }
}
