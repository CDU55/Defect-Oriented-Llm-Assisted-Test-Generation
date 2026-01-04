
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide simpleSuicide;

    function setUp() public {
        simpleSuicide = new SimpleSuicide();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // No privileged roles to exclude - function is completely unprotected

        // Fund the contract to demonstrate value transfer
        deal(address(simpleSuicide), 1 ether);
        uint256 initialContractBalance = address(simpleSuicide).balance;
        assertEq(initialContractBalance, 1 ether);

        uint256 initialCallerBalance = caller.balance;

        vm.prank(caller);
        simpleSuicide.sudicideAnyone();

        // Verify contract is destroyed (no code at address)
        uint256 codeSize = address(simpleSuicide).code.length;
        assertEq(codeSize, 0, "Contract should be destroyed");

        // Verify caller received the contract's balance
        uint256 finalCallerBalance = caller.balance;
        assertEq(finalCallerBalance, initialCallerBalance + initialContractBalance, "Caller should receive contract balance");
    }

    receive() external payable {}

    fallback() external payable {}
}
