# Statistics — Claude-Opus-45

**Prompting Technique:** MultiShot  
**Temperature:** Temperature_0  

| Defect Category | Test File | Generation Time | Input Tokens | Output Tokens | Reasoning Tokens |
|---|---|---|---|---|---|
| Assert, Require, or Revert Violation - Always-Incorrect Control Flow | Validator.t.sol | 10,24s | 2115 | 613 | 0 |
| Bad Random Number Generation | QuestGame.t.sol | 15,70s | 2635 | 1470 | 0 |
| Division By Zero | Calculator.t.sol | 10,05s | 2041 | 906 | 0 |
| Gas Costly Pattern - Complex Fallback | Crowdfund.t.sol | 6,66s | 2484 | 500 | 0 |
| Reentrancy | MiniBank.t.sol | 8,52s | 3594 | 658 | 0 |
| Unrestricted Access to a Critical Method | SalaryManager.t.sol | 11,22s | 2718 | 725 | 0 |
| **Average** | **—** | **10.40s** | **2598** | **812** | **0** |
