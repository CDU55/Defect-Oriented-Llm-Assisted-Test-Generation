# Statistics — Gemini-3-Pro

**Prompting Technique:** ZeroShot  
**Temperature:** Temperature_1  

| Defect Category | Test File | Generation Time | Input Tokens | Output Tokens | Reasoning Tokens |
|---|---|---|---|---|---|
| Assert, Require, or Revert Violation - Always-Incorrect Control Flow | Validator.t.sol | 39,33s | 1825 | 736 | 3319 |
| Bad Random Number Generation | QuestGame.t.sol | 43,31s | 2094 | 935 | 3659 |
| Division By Zero | Calculator.t.sol | 59,10s | 1808 | 920 | 5114 |
| Gas Costly Pattern - Complex Fallback | Crowdfund.t.sol | 44,77s | 2313 | 930 | 3859 |
| Reentrancy | MiniBank.t.sol | 35,75s | 3114 | 1081 | 2804 |
| Unrestricted Access to a Critical Method | SalaryManager.t.sol | 39,72s | 2492 | 610 | 3253 |
| **Average** | **—** | **43.66s** | **2274** | **869** | **3668** |
