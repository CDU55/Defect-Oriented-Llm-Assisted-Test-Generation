# SmartBugs Experiment Results

## Zero-Shot Temperature 0

### Predictable Random Number Generation

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 6 | 3 | TBD | 7 | 22.71 |
| Codestral | 1 | 1 | TBD | 7 | 3.09 |
| DeepSeek-Reasoner | 5 | 2 | TBD | 7 | 138.71 |
| Gemini 3 Pro | 6 | 3 | TBD | 7 | 44.87 |
| GPT 5.1 | 7 | 1 | TBD | 7 | 3.29 |
| Grok 4 | 4 | 1 | TBD | 7 | 143.93 |

### Reentrancy

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 29 | 4 | TBD | 30 | 15.45 |
| Codestral | 9 | 0 | TBD | 30 | 4.13 |
| DeepSeek-Reasoner | 6 | 2 | TBD | 30 | 120.65 |
| Gemini 3 Pro | 30 | 24 | TBD | 30 | 67.94 |
| GPT 5.1 | 6 | 2 | TBD | 30 | 3.65 |
| Grok 4 | 5 | 3 | TBD | 30 | 223.87 |

### Unrestricted Access to a Critical Method

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 10 | 4 | TBD | 10 | 13.71 |
| Codestral | 6 | 5 | TBD | 10 | 1.93 |
| DeepSeek-Reasoner | 8 | 3 | TBD | 10 | 89.86 |
| Gemini 3 Pro | 10 | 6 | TBD | 10 | 33.11 |
| GPT 5.1 | 9 | 4 | TBD | 10 | 2.47 |
| Grok 4 | 7 | 4 | TBD | 10 | 99.37 |

### Total

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 45 | 11 | TBD | 47 | 16.16 |
| Codestral | 16 | 6 | TBD | 47 | 3.5 |
| DeepSeek-Reasoner | 19 | 7 | TBD | 47 | 116.79 |
| Gemini 3 Pro | 46 | 33 | TBD | 47 | 57.09 |
| GPT 5.1 | 22 | 7 | TBD | 47 | 3.34 |
| Grok 4 | 16 | 8 | TBD | 47 | 185.47 |

## Zero-Shot Temperature 0.5


This section presents the raw results obtained from the models using Zero-Shot prompting at Temperature 0.5, without any post-processing or manual fixes.


### Predictable Random Number Generation

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 6 | 3 | TBD | 7 | 25.98 |
| Codestral | 2 | 0 | TBD | 7 | 2.41 |
| DeepSeek-Reasoner | 6 | 0 | TBD | 7 | 162.98 |
| Gemini 3 Pro | 7 | 5 | TBD | 7 | 49.85 |
| GPT 5.1 | 7 | 2 | TBD | 7 | 4.26 |
| Grok 4 | 5 | 2 | TBD | 7 | 140.98 |

### Reentrancy

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 30 | 6 | TBD | 30 | 14.84 |
| Codestral | 7 | 0 | TBD | 30 | 3.79 |
| DeepSeek-Reasoner | 6 | 3 | TBD | 30 | 169.64 |
| Gemini 3 Pro | 29 | 20 | TBD | 30 | 75.21 |
| GPT 5.1 | 8 | 2 | TBD | 30 | 4.67 |
| Grok 4 | 2 | 1 | TBD | 30 | 210.34 |

### Unrestricted Access to a Critical Method

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 10 | 4 | TBD | 10 | 14.26 |
| Codestral | 7 | 5 | TBD | 10 | 2.14 |
| DeepSeek-Reasoner | 9 | 4 | TBD | 10 | 102.31 |
| Gemini 3 Pro | 10 | 8 | TBD | 10 | 35.18 |
| GPT 5.1 | 10 | 4 | TBD | 10 | 4.02 |
| Grok 4 | 6 | 5 | TBD | 10 | 89.97 |

### Total

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 46 | 13 | TBD | 47 | 16.38 |
| Codestral | 16 | 5 | TBD | 47 | 3.24 |
| DeepSeek-Reasoner | 21 | 7 | TBD | 47 | 154.32 |
| Gemini 3 Pro | 46 | 33 | TBD | 47 | 62.92 |
| GPT 5.1 | 25 | 8 | TBD | 47 | 4.47 |
| Grok 4 | 13 | 8 | TBD | 47 | 174.4 |

## Zero-Shot Temperature 0.5 - Compilation Fix


For the initial experiment, we excluded tests that did not compile. After obtaining the initial results, we fixed compilation errors that could also be easily fixed automatically:

1. Import errors
2. Using address instead of address payable
3. Shadowing elements from Forge by declaring variables/attributes in the test with the same name.


### Predictable Random Number Generation

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 6 | 3 | TBD | 7 | 25.98 |
| Codestral | 3 | 0 | TBD | 7 | 2.41 |
| DeepSeek-Reasoner | 6 | 0 | TBD | 7 | 162.98 |
| Gemini 3 Pro | 7 | 5 | TBD | 7 | 49.85 |
| GPT 5.1 | 7 | 2 | TBD | 7 | 4.26 |
| Grok 4 | 6 | 2 | TBD | 7 | 140.98 |

### Reentrancy

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 30 | 6 | TBD | 30 | 14.84 |
| Codestral | 19 | 0 | TBD | 30 | 3.79 |
| DeepSeek-Reasoner | 27 | 12 | TBD | 30 | 169.64 |
| Gemini 3 Pro | 30 | 20 | TBD | 30 | 75.21 |
| GPT 5.1 | 29 | 3 | TBD | 30 | 4.67 |
| Grok 4 | 25 | 12 | TBD | 30 | 210.34 |

### Unrestricted Access to a Critical Method

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 10 | 4 | TBD | 10 | 14.26 |
| Codestral | 8 | 6 | TBD | 10 | 2.14 |
| DeepSeek-Reasoner | 10 | 3 | TBD | 10 | 102.31 |
| Gemini 3 Pro | 10 | 8 | TBD | 10 | 35.18 |
| GPT 5.1 | 10 | 4 | TBD | 10 | 4.02 |
| Grok 4 | 8 | 5 | TBD | 10 | 89.97 |

### Total

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 46 | 13 | TBD | 47 | 16.38 |
| Codestral | 30 | 6 | TBD | 47 | 3.24 |
| DeepSeek-Reasoner | 43 | 15 | TBD | 47 | 154.32 |
| Gemini 3 Pro | 47 | 33 | TBD | 47 | 62.92 |
| GPT 5.1 | 46 | 9 | TBD | 47 | 4.47 |
| Grok 4 | 39 | 19 | TBD | 47 | 174.4 |

## Zero-Shot Temperature 0.5 - Receive


After fixing compilation errors, if the tests did not already define "fallback" and "receive", we added empty definitions to them so that we are sure that the test contracts can receive Ether.


### Predictable Random Number Generation

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 6 | 4 | TBD | 7 | 25.98 |
| Codestral | 3 | 0 | TBD | 7 | 2.41 |
| DeepSeek-Reasoner | 6 | 0 | TBD | 7 | 162.98 |
| Gemini 3 Pro | 7 | 6 | TBD | 7 | 49.85 |
| GPT 5.1 | 7 | 2 | TBD | 7 | 4.26 |
| Grok 4 | 6 | 4 | TBD | 7 | 140.98 |

### Reentrancy

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 30 | 6 | TBD | 30 | 14.84 |
| Codestral | 19 | 0 | TBD | 30 | 3.79 |
| DeepSeek-Reasoner | 27 | 12 | TBD | 30 | 169.64 |
| Gemini 3 Pro | 30 | 20 | TBD | 30 | 75.21 |
| GPT 5.1 | 29 | 3 | TBD | 30 | 4.67 |
| Grok 4 | 25 | 12 | TBD | 30 | 210.34 |

### Unrestricted Access to a Critical Method

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 10 | 6 | TBD | 10 | 14.26 |
| Codestral | 8 | 7 | TBD | 10 | 2.14 |
| DeepSeek-Reasoner | 10 | 3 | TBD | 10 | 102.31 |
| Gemini 3 Pro | 10 | 9 | TBD | 10 | 35.18 |
| GPT 5.1 | 10 | 4 | TBD | 10 | 4.02 |
| Grok 4 | 8 | 5 | TBD | 10 | 89.97 |

### Total

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 46 | 16 | TBD | 47 | 16.38 |
| Codestral | 30 | 7 | TBD | 47 | 3.24 |
| DeepSeek-Reasoner | 43 | 15 | TBD | 47 | 154.32 |
| Gemini 3 Pro | 47 | 35 | TBD | 47 | 62.92 |
| GPT 5.1 | 46 | 9 | TBD | 47 | 4.47 |
| Grok 4 | 39 | 21 | TBD | 47 | 174.4 |

## Zero-Shot Temperature 1

### Predictable Random Number Generation

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 6 | 3 | TBD | 7 | 23.8 |
| Codestral | 3 | 0 | TBD | 7 | 2.53 |
| DeepSeek-Reasoner | 3 | 1 | TBD | 7 | 171.25 |
| Gemini 3 Pro | 7 | 5 | TBD | 7 | 48.25 |
| GPT 5.1 | 5 | 0 | TBD | 7 | 7.96 |
| Grok 4 | 4 | 1 | TBD | 7 | 146.78 |

### Reentrancy

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 30 | 5 | TBD | 30 | 14.36 |
| Codestral | 9 | 0 | TBD | 30 | 3.79 |
| DeepSeek-Reasoner | 6 | 0 | TBD | 30 | 198.71 |
| Gemini 3 Pro | 29 | 20 | TBD | 30 | 72.66 |
| GPT 5.1 | 5 | 2 | TBD | 30 | 4.52 |
| Grok 4 | 6 | 4 | TBD | 30 | 171.75 |

### Unrestricted Access to a Critical Method

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 10 | 3 | TBD | 10 | 13.52 |
| Codestral | 4 | 2 | TBD | 10 | 1.92 |
| DeepSeek-Reasoner | 6 | 4 | TBD | 10 | 114.62 |
| Gemini 3 Pro | 10 | 8 | TBD | 10 | 35.52 |
| GPT 5.1 | 9 | 5 | TBD | 10 | 4.29 |
| Grok 4 | 6 | 2 | TBD | 10 | 83.09 |

### Total

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 46 | 11 | TBD | 47 | 15.59 |
| Codestral | 16 | 2 | TBD | 47 | 3.21 |
| DeepSeek-Reasoner | 15 | 5 | TBD | 47 | 176.73 |
| Gemini 3 Pro | 46 | 33 | TBD | 47 | 61.12 |
| GPT 5.1 | 19 | 7 | TBD | 47 | 4.99 |
| Grok 4 | 16 | 7 | TBD | 47 | 149.17 |

## Multi-Shot Temperature 0

### Predictable Random Number Generation

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 7 | 5 | TBD | 7 | 21.63 |
| Codestral | 3 | 0 | TBD | 7 | 2.43 |
| DeepSeek-Reasoner | 6 | 0 | TBD | 7 | 130.03 |
| Gemini 3 Pro | 6 | 4 | TBD | 7 | 53.96 |
| GPT 5.1 | 7 | 0 | TBD | 7 | 4.62 |
| Grok 4 | 4 | 3 | TBD | 7 | 169.96 |

### Reentrancy

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 30 | 5 | TBD | 30 | 12.86 |
| Codestral | 5 | 0 | TBD | 30 | 3.23 |
| DeepSeek-Reasoner | 6 | 1 | TBD | 30 | 161.95 |
| Gemini 3 Pro | 29 | 21 | TBD | 30 | 78.17 |
| GPT 5.1 | 7 | 1 | TBD | 30 | 4.37 |
| Grok 4 | 7 | 1 | TBD | 30 | 170.83 |

### Unrestricted Access to a Critical Method

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 10 | 5 | TBD | 10 | 13.63 |
| Codestral | 1 | 1 | TBD | 10 | 2.33 |
| DeepSeek-Reasoner | 6 | 5 | TBD | 10 | 95.09 |
| Gemini 3 Pro | 10 | 8 | TBD | 10 | 35.88 |
| GPT 5.1 | 10 | 4 | TBD | 10 | 2.48 |
| Grok 4 | 8 | 5 | TBD | 10 | 79.02 |

### Total

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 47 | 15 | TBD | 47 | 14.33 |
| Codestral | 9 | 1 | TBD | 47 | 2.92 |
| DeepSeek-Reasoner | 18 | 6 | TBD | 47 | 142.97 |
| Gemini 3 Pro | 45 | 33 | TBD | 47 | 65.57 |
| GPT 5.1 | 24 | 5 | TBD | 47 | 4 |
| Grok 4 | 19 | 9 | TBD | 47 | 151.17 |

## Multi-Shot Temperature 0.5

### Predictable Random Number Generation

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 7 | 5 | TBD | 7 | 18.51 |
| Codestral | 4 | 0 | TBD | 7 | 6.87 |
| DeepSeek-Reasoner | 6 | 1 | TBD | 7 | 141.8 |
| Gemini 3 Pro | 6 | 4 | TBD | 7 | 53.21 |
| GPT 5.1 | 6 | 0 | TBD | 7 | 3.39 |
| Grok 4 | 6 | 1 | TBD | 7 | 126.46 |

### Reentrancy

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 29 | 5 | TBD | 30 | 13.54 |
| Codestral | 4 | 0 | TBD | 30 | 8.72 |
| DeepSeek-Reasoner | 4 | 0 | TBD | 30 | 188.36 |
| Gemini 3 Pro | 29 | 21 | TBD | 30 | 77.48 |
| GPT 5.1 | 9 | 2 | TBD | 30 | 4.1 |
| Grok 4 | 6 | 1 | TBD | 30 | 176.03 |

### Unrestricted Access to a Critical Method

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 10 | 5 | TBD | 10 | 13.89 |
| Codestral | 1 | 1 | TBD | 10 | 3.39 |
| DeepSeek-Reasoner | 8 | 3 | TBD | 10 | 96.93 |
| Gemini 3 Pro | 10 | 8 | TBD | 10 | 35.65 |
| GPT 5.1 | 10 | 4 | TBD | 10 | 2.68 |
| Grok 4 | 5 | 1 | TBD | 10 | 78.84 |

### Total

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 46 | 15 | TBD | 47 | 14.35 |
| Codestral | 9 | 1 | TBD | 47 | 7.31 |
| DeepSeek-Reasoner | 18 | 4 | TBD | 47 | 161.97 |
| Gemini 3 Pro | 45 | 33 | TBD | 47 | 64.96 |
| GPT 5.1 | 25 | 6 | TBD | 47 | 3.69 |
| Grok 4 | 17 | 3 | TBD | 47 | 147.97 |

## Multi-Shot Temperature 1

### Predictable Random Number Generation

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 7 | 4 | TBD | 7 | 22.25 |
| Codestral | 3 | 1 | TBD | 7 | 3.8 |
| DeepSeek-Reasoner | 6 | 0 | TBD | 7 | 148.15 |
| Gemini 3 Pro | 6 | 4 | TBD | 7 | 52.83 |
| GPT 5.1 | 7 | 0 | TBD | 7 | 4.67 |
| Grok 4 | 6 | 1 | TBD | 7 | 125.41 |

### Reentrancy

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 29 | 4 | TBD | 30 | 12.57 |
| Codestral | 3 | 0 | TBD | 30 | 5.6 |
| DeepSeek-Reasoner | 5 | 2 | TBD | 30 | 179.35 |
| Gemini 3 Pro | 29 | 21 | TBD | 30 | 77.88 |
| GPT 5.1 | 8 | 2 | TBD | 30 | 4.95 |
| Grok 4 | 6 | 3 | TBD | 30 | 158.46 |

### Unrestricted Access to a Critical Method

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 10 | 4 | TBD | 10 | 12.58 |
| Codestral | 3 | 2 | TBD | 10 | 2.68 |
| DeepSeek-Reasoner | 4 | 1 | TBD | 10 | 77.79 |
| Gemini 3 Pro | 10 | 7 | TBD | 10 | 34.7 |
| GPT 5.1 | 10 | 6 | TBD | 10 | 3.08 |
| Grok 4 | 8 | 3 | TBD | 10 | 75.19 |

### Total

| Model Name | Compilation | Concrete Testing | Symbolic Testing | Tests | Average Time (s) |
|---|---|---|---|---|---|
| Claude Opus 4.5 | 46 | 12 | TBD | 47 | 14.01 |
| Codestral | 9 | 3 | TBD | 47 | 4.71 |
| DeepSeek-Reasoner | 15 | 3 | TBD | 47 | 153.09 |
| Gemini 3 Pro | 45 | 32 | TBD | 47 | 64.96 |
| GPT 5.1 | 25 | 8 | TBD | 47 | 4.51 |
| Grok 4 | 20 | 7 | TBD | 47 | 135.82 |


