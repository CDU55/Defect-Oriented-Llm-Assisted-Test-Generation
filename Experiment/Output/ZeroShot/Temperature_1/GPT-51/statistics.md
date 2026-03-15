# Statistics — GPT-51

**Prompting Technique:** ZeroShot  
**Temperature:** Temperature_1  

| Defect Category | Test File | Generation Time | Input Tokens | Output Tokens | Reasoning Tokens |
|---|---|---|---|---|---|
| Assert, Require, or Revert Violation - Always-Incorrect Control Flow | Validator.t.sol | 8,84s | 1480 | 132 | 1077 |
| Bad Random Number Generation | QuestGame.t.sol | 15,75s | 1647 | 278 | 2108 |
| Division By Zero | Calculator.t.sol | 10,06s | 1460 | 262 | 1159 |
| Gas Costly Pattern - Complex Fallback | Crowdfund.t.sol | 5,19s | 1826 | 259 | 457 |
| Reentrancy | MiniBank.t.sol | 18,03s | 2520 | 452 | 2211 |
| Unrestricted Access to a Critical Method | SalaryManager.t.sol | 11,74s | 1995 | 259 | 1509 |
| **Average** | **—** | **11.60s** | **1821** | **274** | **1420** |
