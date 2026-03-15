# Statistics — Gemini-3-Pro

**Prompting Technique:** ZeroShot  
**Temperature:** Temperature_0  

| Defect Category | Test File | Generation Time | Input Tokens | Output Tokens | Reasoning Tokens |
|---|---|---|---|---|---|
| Assert, Require, or Revert Violation - Always-Incorrect Control Flow | Validator.t.sol | 37,75s | 1825 | 644 | 3308 |
| Bad Random Number Generation | QuestGame.t.sol | 32,88s | 2094 | 997 | 2772 |
| Division By Zero | Calculator.t.sol | 50,17s | 1808 | 933 | 5347 |
| Gas Costly Pattern - Complex Fallback | Crowdfund.t.sol | 22,68s | 2313 | 912 | 2003 |
| Reentrancy | MiniBank.t.sol | 28,37s | 3114 | 1017 | 2752 |
| Unrestricted Access to a Critical Method | SalaryManager.t.sol | 35,53s | 2492 | 708 | 3378 |
| **Average** | **—** | **34.56s** | **2274** | **868** | **3260** |
