# Statistics — Deepseek-Reasoner

**Prompting Technique:** MultiShot  
**Temperature:** Temperature_0  

| Defect Category | Test File | Generation Time | Input Tokens | Output Tokens | Reasoning Tokens |
|---|---|---|---|---|---|
| Assert, Require, or Revert Violation - Always-Incorrect Control Flow | Validator.t.sol | 40,67s | 1993 | 176 | 1629 |
| Bad Random Number Generation | QuestGame.t.sol | 86,83s | 2484 | 548 | 2956 |
| Division By Zero | Calculator.t.sol | 66,50s | 1915 | 339 | 2495 |
| Gas Costly Pattern - Complex Fallback | Crowdfund.t.sol | 30,91s | 2361 | 299 | 1092 |
| Reentrancy | MiniBank.t.sol | 59,20s | 3393 | 454 | 2194 |
| Unrestricted Access to a Critical Method | SalaryManager.t.sol | 58,01s | 2610 | 291 | 2309 |
| **Average** | **—** | **57.02s** | **2459** | **351** | **2112** |
