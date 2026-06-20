# Defect-Oriented-Llm-Assisted-Test-Generation

This repository contains the artifacts for our empirical study regarding the potential of Large Language Models (LLMs) to generate valid Solidity Forge/Kontrol tests from test templates.

## Defect Categories
The experiment targets the following vulnerability classes:
* **Assert, Require, or Revert Violation**: Errors arising from mathematically impossible assertions or incorrect logic flow (e.g., checks that can never be true).
* **Bad Random Number Generation**: Vulnerabilities stemming from the use of deterministic chain attributes (e.g., `block.timestamp`, `block.number`) for pseudo-randomness, which can be predicted or manipulated.
* **Division By Zero**: Missing validation for the denominator in division operations, leading to potential transaction reverts.
* **Gas Costly Pattern - Complex Fallback**: `fallback` or `receive` functions that perform expensive operations (e.g., storage writes), causing failures when receiving Ether via methods with a fixed gas stipend (2300 gas).
* **Reentrancy**: Flaws where an external call is made before a state update, allowing the callee to re-enter the function and manipulate the state (e.g., draining funds).
* **Unrestricted Access to a Critical Method**: High-privilege functions (e.g., `selfdestruct` or administrative setters) that lack proper access control checks, allowing unauthorized execution.

## Models Evaluated

The following Large Language Models (LLMs) were evaluated in this study:

* **GPT 5.1**
* **Gemini 3 Pro**
* **Codestral**
* **Claude Opus 4.5**
* **DeepSeek-V 3.2**

## Experiment Prompts

Two prompt variations were used depending on the scope of the vulnerability (Method-level vs Contract-level).

### Method-Level Prompt

> You are an expert Smart Contract Security Engineer and SDET specialized in the Foundry/Forge framework.
>
> Your task is to generate a Solidity test file that reproduces a specific vulnerability in a given contract.
> I will provide the Defect Definition, the Target Contract, and a Test Template.
>
> **Instructions**
>
> Analyze the [TARGET_CONTRACT] contract to identify the [METHOD_NAME] and its dependencies.
>
> Using the template, fill in the logic required to prove the existence of [ISSUE_NAME].
>
> **Strict Constraints:**
>
> *   **No Additional Tests:** Do not generate any additional test functions or test files beyond what is required by the template.
> *   **Preserve Naming:** Do not rename the test function existing in the template. The name of the test function must remain exactly as defined in the template.
>
> **Strict Output Format:** Return ONLY the Solidity code within Markdown code blocks. Do not provide explanations, introductions, or conclusions.
>
> **Comment Handling:**
>
> Delete all comments starting with // [LLM_INSTRUCTION] or similar template markers from the final output.
>
> The generated code should be clean and ready to compile, containing only the necessary logic and standard Solidity comments (like SPDX licenses or logic explanations).
>
> **Input Data**
>
> Issue Name: [ISSUE_NAME]
> Defect Definition: [DEFECT_DEFINITION]
> Method to Test: [METHOD_NAME]
>
> **Target Contract:**
>
> [CONTRACT_CODE]
>
>
> **Test Template:**
>
> [TEST_TEMPLATE]

### Contract-Level Prompt

> You are an expert Smart Contract Security Engineer and SDET specialized in the Foundry/Forge framework.
>
> Your task is to generate a Solidity test file that reproduces a specific vulnerability in a given contract.
> I will provide the Defect Definition, the Target Contract, and a Test Template.
>
> **Instructions**
>
> Analyze the [TARGET_CONTRACT] contract to identify the relevant state variables, invariants, and contract-level logic.
>
> Using the template, fill in the logic required to prove the existence of [ISSUE_NAME].
>
> **Strict Constraints:**
>
> *   **No Additional Tests:** Do not generate any additional test functions or test files beyond what is required by the template.
> *   **Preserve Naming:** Do not rename the test function existing in the template. The name of the test function must remain exactly as defined in the template.
>
> **Strict Output Format:** Return ONLY the Solidity code within Markdown code blocks. Do not provide explanations, introductions, or conclusions.
>
> **Comment Handling:**
>
> Delete all comments starting with // [LLM_INSTRUCTION] or similar template markers from the final output.
>
> The generated code should be clean and ready to compile, containing only the necessary logic and standard Solidity comments (like SPDX licenses or logic explanations).
>
> **Input Data**
>
> Issue Name: [ISSUE_NAME]
> Defect Definition: [DEFECT_DEFINITION]
>
> **Target Contract:**
>
> [CONTRACT_CODE]
>
>
> **Test Template:**
>
> [TEST_TEMPLATE]

### Token Definitions

The placeholders enclosed in square brackets were replaced programmatically as follows:

* **`[ISSUE_NAME]`**: A placeholder for the type of vulnerability that the test aims to demonstrate.
* **`[DEFECT_DEFINITION]`**: A brief explanation of the issue, intended to provide more context to the model.
* **`[METHOD_NAME]`**: The method from the contract being targeted for test generation.
* **`[TARGET_CONTRACT]`**: The name of the contract being targeted for test generation.
* **`[CONTRACT_CODE]`**: The source code of the smart contract under test.
* **`[TEST_TEMPLATE]`**: The test template implemented for the specific issue to be detected.


## Repository Structure

This repository is organized into the following main directories:

### Templates Directory
Contains the Foundry/Kontrol test templates used for generating tests.

* **`Templates/`**:
    * **`MultiShot/`**: Test templates (`.t.sol`) designed for the "Multi-Shot" prompting strategy.
    * **`ZeroShot/`**: Test templates (`.t.sol`) designed for the "Zero-Shot" prompting strategy.

### Specifications Directory
Contains the formal specifications and defect definitions for each vulnerability class.

* **`Specifications/`**: Markdown documents detailing the formal specifications and defect definitions for each vulnerability class (e.g., `Reentrancy.md`, `Division by Zero.md`).

Each specification document follows a structured format regarding the defect:
*   **Defect Definition**: A high-level textual description of the vulnerability.
*   **Specification Primitives**: A set of predicates and functions specific to the defect, which is used to formally describe the contract's state and behavior.
*   **Domain Conceptual Model**: A breakdown of the necessary conditions for a contract to be considered vulnerable.
*   **Formal Specification**: A mathematical definition of the defect using the defined primitives.
*   **Test Template Design**: A mapping of the formal specification into a concrete testing strategy, detailing the *Setup*, *Action*, and *Assertion* phases required to detect the defect.
*   **Template Derivation and LLM Instantiation**: Describes how the conceptual test designs are materialized into standardized Foundry test files (including the actual template code) and outlines how explicit `[LLM_INSTRUCTION]` comments guide the model.

### General Experiment Folder Structure

Both experiment directories (`Experiment/` and `SmartBugs-Experiment/`) follow a standardized structure:

* **`Input/Contracts/`**: Contains the source code for target smart contracts (`.sol`).
* **`Output/`**: Contains the generated test artifacts, organized hierarchically by:
    * **Strategy**: `ZeroShot` or `MultiShot`
        * **Temperature**: `Temperature_0` or `Temperature_1`
            * **Model Name** (e.g., `Gemini-3-Pro`, `GPT-51`)
                * **Defect Category**: Subfolders for each vulnerability class (e.g., `Reentrancy/`).

### Experiment Directory
The core folder for the LLM generation study using the primary dataset.

> **Results Summary**: A comprehensive summary of the initial experiment results can be found in [Experiment_Results.md](Experiment/Experiment_Results.md).

### SmartBugs-Experiment Directory
This directory contains an extension of the study applied to the **SmartBugs dataset**. 

> **Results Summary**: A comprehensive summary of the SmartBugs experiment results can be found in [SmartBugs_Results.md](SmartBugs-Experiment/SmartBugs_Results.md).

### Observations for SmartBugs-Experiment

* **Token Limits**: The initial experiment was conducted with a token budget of **8192**. However, this limit proved insufficient for models with verbose reasoning chains. **Gemini 3 Pro** exhausted the token budget in **47 queries**, and **GPT-51** hit the limit in **3 queries**. Consequently, the token budget was increased to **16384** for the final results to ensure complete code generation.
* **Schema Constraints**: The explicit constraints regarding preserving test function names and prohibiting additional tests were added to the prompt after initial trials. In those trials, **Claude Opus 4.5** altered the template's test function name in 28 generated files, and **Codestral** did the same in 20 files.