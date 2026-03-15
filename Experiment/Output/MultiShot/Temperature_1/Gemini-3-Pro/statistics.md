# Statistics — Gemini-3-Pro

**Prompting Technique:** MultiShot  
**Temperature:** Temperature_1  

| Defect Category | Test File | Generation Time | Input Tokens | Output Tokens | Reasoning Tokens |
|---|---|---|---|---|---|
| Assert, Require, or Revert Violation - Always-Incorrect Control Flow | Validator.t.sol | 41,41s | 1957 | 533 | 3701 |
| Bad Random Number Generation | QuestGame.t.sol | 38,40s | 2495 | 703 | 2835 |
| Division By Zero | Calculator.t.sol | 46,94s | 1883 | 825 | 3760 |
| Gas Costly Pattern - Complex Fallback | Crowdfund.t.sol | 21,90s | 2344 | 914 | 1258 |
| Reentrancy | MiniBank.t.sol | 29,94s | 3344 | 834 | 2317 |
| Unrestricted Access to a Critical Method | SalaryManager.t.sol | 30,60s | 2580 | 856 | 2282 |
| **Average** | **—** | **34.87s** | **2434** | **778** | **2692** |
