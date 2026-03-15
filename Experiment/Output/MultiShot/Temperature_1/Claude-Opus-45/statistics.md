# Statistics — Claude-Opus-45

**Prompting Technique:** MultiShot  
**Temperature:** Temperature_1  

| Defect Category | Test File | Generation Time | Input Tokens | Output Tokens | Reasoning Tokens |
|---|---|---|---|---|---|
| Assert, Require, or Revert Violation - Always-Incorrect Control Flow | Validator.t.sol | 17,97s | 2144 | 947 | 519 |
| Bad Random Number Generation | QuestGame.t.sol | 51,53s | 2664 | 1078 | 814 |
| Division By Zero | Calculator.t.sol | 14,74s | 2070 | 709 | 353 |
| Gas Costly Pattern - Complex Fallback | Crowdfund.t.sol | 25,83s | 2513 | 1326 | 746 |
| Reentrancy | MiniBank.t.sol | 32,39s | 3623 | 1358 | 1137 |
| Unrestricted Access to a Critical Method | SalaryManager.t.sol | 28,76s | 2747 | 1403 | 815 |
| **Average** | **—** | **28.54s** | **2627** | **1137** | **731** |
