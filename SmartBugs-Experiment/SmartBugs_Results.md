# SmartBugs-Kontrol Experiment Results

## ZeroShot Temperature 0

### Reentrancy

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 28 | 3 | 3 | 0 | 2 | 9.18s | 30 |
| Codestral | 6 | 3 | 3 | 0 | 0 | 3.08s | 30 |
| Deepseek-Reasoner | 6 | 1 | 1 | 0 | 0 | 140.40s | 30 |
| Gemini-3-Pro | 28 | 24 | 24 | 0 | 0 | 76.22s | 30 |

### Predictable Random Number Generation

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 6 | 5 | 2 | 1 | 0 | 18.03s | 7 |
| Codestral | 2 | 0 | 0 | 1 | 0 | 2.02s | 7 |
| Deepseek-Reasoner | 7 | 1 | 0 | 2 | 0 | 185.56s | 7 |
| Gemini-3-Pro | 7 | 4 | 1 | 1 | 1 | 60.10s | 7 |

### Unrestricted Access to a Critical Method

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 9 | 3 | 2 | 5 | 0 | 7.79s | 10 |
| Codestral | 3 | 2 | 2 | 0 | 0 | 1.58s | 10 |
| Deepseek-Reasoner | 5 | 4 | 4 | 0 | 0 | 109.47s | 10 |
| Gemini-3-Pro | 10 | 8 | 6 | 0 | 0 | 69.00s | 10 |

### Total

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 43 | 11 | 7 | 6 | 2 | 10.20s | 47 |
| Codestral | 11 | 5 | 5 | 1 | 0 | 2.60s | 47 |
| Deepseek-Reasoner | 18 | 6 | 5 | 2 | 0 | 140.54s | 47 |
| Gemini-3-Pro | 45 | 36 | 31 | 1 | 1 | 72.28s | 47 |

## ZeroShot Temperature 1

### Reentrancy

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 30 | 18 | 17 | 0 | 1 | 42.70s | 30 |
| Codestral | 5 | 3 | 3 | 0 | 0 | 3.12s | 30 |
| Deepseek-Reasoner | 4 | 1 | 1 | 0 | 0 | 193.83s | 30 |
| GPT-51 | 10 | 9 | 9 | 0 | 0 | 33.32s | 30 |
| Gemini-3-Pro | 30 | 22 | 22 | 0 | 1 | 63.06s | 30 |

### Predictable Random Number Generation

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 6 | 5 | 2 | 1 | 0 | 39.56s | 7 |
| Codestral | 2 | 0 | 0 | 1 | 0 | 2.35s | 7 |
| Deepseek-Reasoner | 5 | 1 | 0 | 1 | 0 | 173.76s | 7 |
| GPT-51 | 7 | 2 | 0 | 2 | 0 | 29.16s | 7 |
| Gemini-3-Pro | 6 | 4 | 2 | 1 | 0 | 53.04s | 7 |

### Unrestricted Access to a Critical Method

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 10 | 8 | 3 | 1 | 0 | 24.09s | 10 |
| Codestral | 3 | 1 | 1 | 0 | 0 | 2.22s | 10 |
| Deepseek-Reasoner | 7 | 5 | 4 | 0 | 0 | 111.99s | 10 |
| GPT-51 | 10 | 7 | 3 | 1 | 0 | 13.60s | 10 |
| Gemini-3-Pro | 10 | 9 | 6 | 0 | 0 | 50.07s | 10 |

### Total

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 46 | 31 | 22 | 2 | 1 | 38.27s | 47 |
| Codestral | 10 | 4 | 4 | 1 | 0 | 2.81s | 47 |
| Deepseek-Reasoner | 16 | 7 | 5 | 1 | 0 | 173.43s | 47 |
| GPT-51 | 27 | 18 | 12 | 3 | 0 | 28.51s | 47 |
| Gemini-3-Pro | 46 | 35 | 30 | 1 | 1 | 58.80s | 47 |

## MultiShot Temperature 0

### Reentrancy

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 27 | 4 | 3 | 0 | 2 | 9.04s | 30 |
| Codestral | 3 | 2 | 2 | 0 | 0 | 3.98s | 30 |
| Deepseek-Reasoner | 5 | 1 | 1 | 0 | 0 | 113.99s | 30 |
| Gemini-3-Pro | 28 | 19 | 18 | 0 | 1 | 67.30s | 30 |

### Predictable Random Number Generation

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 6 | 5 | 2 | 1 | 0 | 17.20s | 7 |
| Codestral | 3 | 0 | 0 | 1 | 0 | 2.25s | 7 |
| Deepseek-Reasoner | 5 | 0 | 0 | 0 | 0 | 186.13s | 7 |
| Gemini-3-Pro | 5 | 2 | 1 | 0 | 0 | 70.01s | 7 |

### Unrestricted Access to a Critical Method

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 10 | 6 | 2 | 0 | 1 | 10.21s | 10 |
| Codestral | 1 | 1 | 1 | 0 | 0 | 1.77s | 10 |
| Deepseek-Reasoner | 4 | 3 | 3 | 0 | 0 | 67.88s | 10 |
| Gemini-3-Pro | 10 | 9 | 6 | 0 | 0 | 57.36s | 10 |

### Total

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 43 | 15 | 7 | 1 | 3 | 10.51s | 47 |
| Codestral | 7 | 3 | 3 | 1 | 0 | 3.25s | 47 |
| Deepseek-Reasoner | 14 | 4 | 4 | 0 | 0 | 114.93s | 47 |
| Gemini-3-Pro | 43 | 30 | 25 | 0 | 1 | 65.59s | 47 |

## MultiShot Temperature 1

### Reentrancy

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 30 | 20 | 18 | 0 | 2 | 42.37s | 30 |
| Codestral | 2 | 1 | 1 | 0 | 0 | 3.93s | 30 |
| Deepseek-Reasoner | 4 | 1 | 1 | 0 | 0 | 73.27s | 30 |
| GPT-51 | 7 | 5 | 5 | 0 | 0 | 36.87s | 30 |
| Gemini-3-Pro | 24 | 17 | 16 | 0 | 1 | 67.75s | 30 |

### Predictable Random Number Generation

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 5 | 4 | 2 | 0 | 0 | 37.33s | 7 |
| Codestral | 3 | 0 | 0 | 1 | 0 | 2.50s | 7 |
| Deepseek-Reasoner | 3 | 1 | 0 | 0 | 0 | 193.01s | 7 |
| GPT-51 | 6 | 2 | 1 | 0 | 0 | 28.78s | 7 |
| Gemini-3-Pro | 5 | 4 | 1 | 0 | 0 | 57.43s | 7 |

### Unrestricted Access to a Critical Method

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 10 | 7 | 2 | 0 | 0 | 27.86s | 10 |
| Codestral | 3 | 2 | 2 | 0 | 0 | 1.85s | 10 |
| Deepseek-Reasoner | 8 | 6 | 5 | 0 | 0 | 89.82s | 10 |
| GPT-51 | 9 | 5 | 3 | 0 | 0 | 15.68s | 10 |
| Gemini-3-Pro | 10 | 10 | 8 | 0 | 0 | 50.36s | 10 |

### Total

| Model | Compiled | Forge | Kontrol | Kontrol Timeout | Kontrol Crash | Avg Time | Total Files |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Claude-Opus-45 | 45 | 31 | 22 | 0 | 2 | 38.53s | 47 |
| Codestral | 8 | 3 | 3 | 1 | 0 | 3.28s | 47 |
| Deepseek-Reasoner | 15 | 8 | 6 | 0 | 0 | 94.62s | 47 |
| GPT-51 | 22 | 12 | 9 | 0 | 0 | 31.16s | 47 |
| Gemini-3-Pro | 39 | 31 | 25 | 0 | 1 | 62.51s | 47 |
