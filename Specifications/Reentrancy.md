# Reentrancy

Reentrancy is probably the most studied vulnerability in the smart contract field. The main idea behind it is that smart contracts can interact with other smart contracts within a function via a $\tt call$ statement. It is recommended to have such interactions with other smart contracts *after* making changes to the current state of the calling smart contract. The main reason is that a $\tt call$ from a contract $c$ to a contract $c'$ may give control to $c'$, and thus $c'$ can call $c$ again. The classical example here is a simple deposit/withdraw contract $c$ that allows a malicious smart contract $c'$ to first deposit some cryptocurrency and then withdraw it. If $c$ makes state changes *after* the $\tt call$ (which performs the actual withdrawal transfer), such as setting the balance of $c'$ to 0 after the withdrawal, these changes occurring too late can be exploited to drain the funds out of $c$.

## Specification primitives

Our defect specifications rely on standard Solidity datatypes— $\tt Contract$, $\tt Method$, $\tt Address$, $\tt Env$(ironment), and $\tt State$, together with the Booleans $\mathbb{B} = \{\mathit{true}, \mathit{false}\}$. The signature is *order-sorted* with the subsort relation $\tt Contract \sqsubseteq \tt Address$ (a contract account is an address with code, as in Solidity, where $\mathit{msg.sender}$ ranges over $\tt Address$), so a $\tt Contract$ witness — such as the attacker $c'$ — may be used wherever an $\tt Address$ is expected, with no explicit coercion. A brief description of the necessary predicates and functions over these types is included in the table below. The evaluation of these primitives is stratified: structural properties are derived statically via Slither, while behavioral properties are verified at runtime via Forge/Kontrol assertions within the LLM-generated test harness.

| Symbol | Semantics |
|--------|-----------|
| ***Static Analysis (Slither)*** | |
| $\texttt{methods}(c)$ | The set of externally-callable functions (entry points) of contract *c*, which includes its public/external functions and the special $\tt receive$ and $\tt fallback$ functions. Each $\texttt{Method}$ value is contract-qualified, so $m \in \texttt{methods}(c)$ fixes *c* as the contract on which *m* runs (hence $\texttt{Exec}$ needs no separate callee argument). |
| $\texttt{YieldsControl}(c, c', m)$ | Holds if method *m* of contract *c* contains an instruction (e.g., CALL, STATICCALL, or DELEGATECALL) that transfers execution flow to an external contract *c'*, creating a window for a callback. |
| ***Runtime Verification (LLM-generated based on specific template)*** | |
| $\texttt{Interm}(\sigma_i, a, \sigma, m)$ | Holds if σᵢ is an intermediate state for the execution of method *m* invoked by caller *a* from state σ. The caller *a* (and, where inputs matter, the applied form $m(x)$) identifies the specific run. |
| $\texttt{Exec}(a, m, \sigma, \sigma')$ | Holds if caller *a* invoking *m* in state σ successfully transitions to σ'. When the call inputs bear on run identity we write the applied form $\texttt{Exec}(a,m(x),\sigma,\sigma')$ ($m(x)$ sugar for the pair $(m,x)$). EVM execution is *deterministic*, so $\texttt{Exec}$ is functional in $\langle a, m(x), \sigma\rangle$; hence $\texttt{Interm}(\sigma_i,a,\sigma,m(x))$ and $\texttt{Exec}(a,m(x),\sigma,\sigma_b)$ refer to the same run. |
| $\texttt{Exploit}(\sigma)$ | Holds if state σ records a trace-based indicator that the defect was successfully triggered (e.g., a reentrancy counter exceeding 1 or an unauthorized state change). $\texttt{Exploit}$ is a *monotone* (persistent) trace property — its indicators are only ever set, never reset, within a transaction — so it may be read at any later state $\succeq$ the firing state and still faithfully witness it there. |


## Formal Specification

Reentrancy is defined as the existence of a "Callback Window" where a transient invariant is suspended, allowing attackers to exploit an inconsistent state via any method:

$$\begin{aligned}
\mathsf{Reentrant}_{\mathcal{I}}(c) \equiv {}& \exists m, m' \in \mathsf{methods}(c).\ \exists c' \neq c.\ \exists x \in \mathsf{Dom}(m).\ \exists \sigma, \sigma_i, \sigma'_f, \sigma_b \in \mathsf{State}.\\
&\mathcal{I}(\sigma) \land \mathsf{Interm}(\sigma_i, c', \sigma, m(x)) \land \neg \mathcal{I}(\sigma_i) \land
\mathsf{YieldsControl}(c, c', m) \land \mathsf{Exec}(c', m', \sigma_i, \sigma'_f) \land {}\\
&\mathsf{Exploit}(\sigma'_f) \wedge \mathsf{Exec}(c', m(x), \sigma, \sigma_b) \wedge \neg \mathcal{I}(\sigma_b)
\end{aligned}$$

where $\mathcal{I}:\mathsf{State}\to \mathbb{B}$ represents a global consistency property (e.g., "Total Supply = Sum of Balances") that is expected to hold at transaction boundaries but may be temporarily suspended during external calls. The invariant $\mathcal{I}$ is supplied by the LLM as a meta-level parameter, so $\mathsf{Reentrant}_{\mathcal{I}}(c)$ is a first-order schema — one sentence per choice of $\mathcal{I}$. Soundness requires only that $\mathcal{I}$ be a genuine consistency invariant of $c$: a property the contract is intended to preserve across transaction boundaries. This choice is the framework's only trusted input and its sole false-positive mode: a passing test certifies that $\mathcal{I}$ holds at $\sigma$ and is broken at $\sigma_b$, which corresponds to a genuine defect only if $\mathcal{I}$ is indeed such an invariant. The defect is witnessed by a genuine *transition* of the invariant — holding at $\sigma$ ($C_1$), broken at the boundary $\sigma_b$ ($C_8$): we need it to hold initially only so that its later violation is a *change* effected by the exploit rather than a pre-existing inconsistency. Finally, $\sigma_b$ is the *outer-call boundary* — the post-state of $m$, which we treat as the transaction boundary because the attacker's outer call to $m$ models the exploit transaction: the conjunct $\mathsf{Exec}(c',m(x),\sigma,\sigma_b)$ records that the outer invocation of $m$ (by the attacker $c'$) begun in the consistent state $\sigma$ ultimately returns in $\sigma_b$, of which $\sigma_i$ is the intermediate state ($\mathsf{Interm}(\sigma_i,c',\sigma,m(x))$). Here $\mathsf{Dom}(m)$ is the input domain of $m$, $m(x)$ abbreviates the applied call, and the outer input $x$ is reified as a prefix witness shared by $\mathsf{Interm}$ ($C_2$) and the outer $\mathsf{Exec}$ ($C_7$); the inner re-entrant call ($C_5$) carries no separate input witness, as $m'$ and its arguments are fixed together by $h_{\mathit{reenter}}$. We state the invariant violation at this boundary $\sigma_b$ rather than at the inner post-state $\sigma'_f$: a genuine exploit leaves the consistency invariant broken at the transaction boundary (the drained value is irreversibly gone), whereas a violation that the suspended method repairs before $m$ returns is correctly *not* flagged.

The vulnerability is defined as the ability to execute *any* method (including view functions for read-only reentrancy) while the global consistency property is false, provided that has yielded control to an external contract.

## Specific test template design

A test template for the reentrancy defect follows the standard Arrange–Act–Assert methodology, with the *Act* stage split into two sub-phases because of the callback window: *Setup* (Arrange), *Action* and *Callback Logic* (Act), and *Assertion* (Assert).

**Testing Goal** — Prove that execution control can be hijacked to perform recursive calls, thereby breaking the intended atomicity of a sensitive method.

**Setup** — The LLM generates a malicious attacker contract that tracks the number of re-entries with a dedicated counter. The arrange phase deploys and funds both parties, performs the attacker's deposit, and records whether the consistency invariant $\mathcal{I}$ holds at the resulting initial state $\sigma$.

**Action** — The test triggers the exploit by invoking the attacker, which calls the victim's vulnerable method and thereby issues the external call that yields control back to the attacker.

**Callback Logic** — Within the attacker's callback function, the LLM instantiates logic to re-invoke the victim's vulnerable method. The callback increments the re-entry counter on each entry and, because it runs while the victim's method is still suspended, records whether the consistency invariant is broken at that intermediate state $\sigma_i$, giving a trace-based proof of the exploit.

**Assertion** — The defect is validated by three checks run by the test contract: that the invariant held at the initial state $\sigma$; that re-entry occurred while the invariant was violated during the callback at $\sigma_i$; and that the invariant is still broken at the transaction boundary $\sigma_b$ once the outer call returns. Together they give a deterministic, trace-based verification that the intermediate state was reached and the contract's atomicity invariant was broken.

## Template Derivation and LLM Instantiation

The conceptual test design is materialized into a standardized Foundry test template (e.g., $\tt Reentrancy.t.sol$). This template consists of two primary architectural components: a main test harness inheriting from Foundry's $\tt Test$ contract, and an $\tt Attacker$ contract designed to execute the exploit. To bridge the gap between static analysis and generation, the template embeds explicit $\tt [LLM\_INSTRUCTION]$ comments alongside structural markers for the Setup, Action, Assertion, and Callback phases.

Each hole is assigned to either Slither or the LLM for resolution, as summarized in the table below.
The specification $\mathsf{Reentrant}_{\mathcal{I}}(c)$ contains eight existential witnesses, together with the meta-level invariant parameter $\mathcal{I}$ (resolved as the hole $h_{\mathcal{I}}$ by the LLM).
Each maps to a typed hole in the template schema, to a state witnessed at runtime, or to the LLM-generated attacker contract that realizes the external callee $c'$:

| Spec witness | Hole | Sort | Resolved by |
|---|---|---|---|
| $\exists m \in \mathsf{methods}(c)$ | $h_m$ | $\mathsf{Method}$ | Slither |
| $\exists m' \in \mathsf{methods}(c)$ | $h_{\mathit{reenter}}$ | $\mathsf{CallExpr}$ | LLM |
| $\exists x \in \mathsf{Dom}(m)$ (outer input) | folded into attacker's `attack` call | | LLM |
| $\mathcal{I} : \mathsf{State} \to \mathbb{B}$ (schema parameter) | $h_{\mathcal{I}}$ | $\mathsf{BoolExpr}$ | LLM |
| $\exists \sigma \in \mathsf{State}$ | $h_{\mathit{init}}$ | $\mathsf{State}$ | LLM |
| $\exists \sigma_i \in \mathsf{State}$ | witnessed at runtime | | Forge/Kontrol |
| $\exists c' \neq c$ (external callee) | attacker contract (CALL target) | | Slither + LLM |
| $\exists \sigma'_f \in \mathsf{State}$ | witnessed at runtime | | Forge/Kontrol |
| $\exists \sigma_b \in \mathsf{State}$ (boundary) | witnessed at runtime | | Forge/Kontrol |

The intermediate state $\sigma_i$ carries no explicit hole: its *existence* is witnessed at runtime by the callback being entered ($\mathsf{reentrancyCount} \geq 1$), making it an implicit existential that is *verified* rather than *filled*.

**Assumption (CALL-target precision).** We assume Slither is precise on $\mathsf{YieldsControl}(c,c',m)$ not merely as to call *existence* but as to the *CALL-target identity*: the callee $c'$ it reports is the external contract that receives control at runtime. Hence the static witness for $\exists c'$ in $C_4$ coincides with the runtime callee bound in $C_5$ and $C_7$ (the LLM-deployed attacker sits at the resolved target by construction). Like the other static $\mathcal{P}_0$ facts, $\mathsf{YieldsControl}$ is never confirmed on the trace, so this precision is a standing premise of the derivation.

Before stating the derivation rules, we record how each conjunct of $\mathsf{Reentrant}(c)$ maps to exactly one test phase and its concrete template realization:

| Spec conjunct | Phase | Template realization |
|---|---|---|
| $\mathcal{I}(\sigma)$ | *setUp* | $\tt vm.deal(victim,\cdot);\ vm.deal(attacker,\cdot);$ $h_{\mathit{init}}$; flag inits; $\tt attacker.setupAttack\{value:\cdot\}(\cdot);$ (deposit completes $\sigma$); $\tt bool\ initialInvariantHolds = $$h_{\mathcal{I}}$ (records $C_1$, asserted in *assert*) |
| $\mathsf{Interm}(\sigma_i,c',\sigma,m(x))$ | *action* | $\tt attacker.attack(\cdot);$ where $\tt attack$ runs $\tt victim.$$h_m$$\tt(\cdot)$ (issues the external CALL, reaching $\sigma_i$), then $\tt exploitSucceeded = (reentrancyCount > 1\ \&\&\ invariantBroken)$ |
| $\neg\mathcal{I}(\sigma_i)$ | *callback* | $\tt invariantBroken = !$$h_{\mathcal{I}}$ (evaluated at $\sigma_i$ inside $\tt receive()$) |
| $\mathsf{YieldsControl}(c,c',m)$ | *action* | CALL inside $h_m$ (identified by Slither) |
| $\mathsf{Exec}(c',m',\sigma_i,\sigma'_f)$ | *callback* | $\tt receive()$ executes $h_{\mathit{reenter}}$; increments $\tt reentrancyCount$ |
| $\mathsf{Exploit}(\sigma'_f)$ | *action* | $\tt reentrancyCount > 1$ recorded after the callback unwinds (re-entry occurred) |
| $\mathsf{Exec}(c',m(x),\sigma,\sigma_b)$ | *assert* | the outer $\tt attack$ call returns, reaching the transaction boundary $\sigma_b$ (post-state of $m$) |
| $\neg\mathcal{I}(\sigma_b)$ | *assert* | $\tt assertTrue(initialInvariantHolds);\ assertTrue(attacker.exploitSucceeded());\ bool\ invariantBrokenAtBoundary = !$$h_{\mathcal{I}}$$\tt;\ assertTrue(invariantBrokenAtBoundary)$ ($C_8$ at the boundary $\sigma_b$; the outer $\mathsf{Exec}$, $C_7$, is witnessed by $\tt attack$ returning) |

## Derivation Rules for $\vdash$

This section gives a rigorous definition of the relation $\Phi(c) \vdash \tau$, read "defect specification $\Phi$ derives template schema $\tau$". We develop it through the Reentrancy running example.

The relation $\Phi(c) \vdash \tau$ is defined by the following six rules.

Witnesses become typed holes:

$$\dfrac{}{\displaystyle \Phi \vdash \bigl\{ h_m : \mathsf{Method},\; h_{\mathit{reenter}} : \mathsf{CallExpr},\; h_{\mathcal{I}} : \mathsf{BoolExpr},\; h_{\mathit{init}} : \mathsf{State} \bigr\}} \quad \text{[Holes]}$$

Precondition $\mathcal{I}(\sigma)$ derives the *setUp* phase:

$$\dfrac{\displaystyle \mathcal{I}(\sigma) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{setUp}} \left[\begin{array}{l} \texttt{vm.deal}(\mathit{victim},\cdot);\; \texttt{vm.deal}(\mathit{attacker},\cdot);\; h_{\mathit{init}};\; \\ \mathsf{reentrancyCount} = 0;\; \mathsf{exploitSucceeded} = \mathsf{false};\; \mathsf{invariantBroken} = \mathsf{false};\; \\ \mathit{attacker}.\texttt{setupAttack\{value:}v\texttt{\}}(v);\; \texttt{bool}\ \mathsf{initialInvariantHolds} = h_{\mathcal{I}} \end{array}\right]} \quad \text{[Pre]}$$

Transition conditions derive the *action* phase:

$$\dfrac{\displaystyle \begin{array}{l} \mathsf{Interm}(\sigma_i,c',\sigma,m(x)) \in \mathrm{conjuncts}(\Phi) \quad \mathsf{YieldsControl}(c,c',m) \in \mathrm{conjuncts}(\Phi) \\ \mathsf{Exploit}(\sigma'_f) \in \mathrm{conjuncts}(\Phi) \end{array}}{\displaystyle \Phi \vdash_{\mathit{action}} \left[\mathit{attacker}.{\tt attack}(v)\right]} \quad \text{[Act]}$$

Where $\tt attack$ calls $\mathit{victim}.h_m(v)$ and evaluates $\mathsf{exploitSucceeded} = (\mathsf{reentrancyCount} > 1\ {\tt \&\&}\ \mathsf{invariantBroken})$.

Re-entrancy conditions derive the *callback* phase:

$$\dfrac{\displaystyle \mathsf{Exec}(c',m',\sigma_i,\sigma'_f) \in \mathrm{conjuncts}(\Phi) \quad \mathsf{target}(h_{\mathit{reenter}}) \in \mathsf{methods}(c)}{\displaystyle \Phi \vdash_{\mathit{callback}} \left[\texttt{receive()}\;\bigl\{\; \mathsf{reentrancyCount}\texttt{++};\; \textbf{if}\;(\mathsf{reentrancyCount} < 2)\;\{\; \mathsf{invariantBroken} = {!}h_{\mathcal{I}};\; h_{\mathit{reenter}}\;\} \;\bigr\}\right]} \quad \text{[Cbk]}$$

The second premise $\mathsf{target}(h_{\mathit{reenter}}) \in \mathsf{methods}(c)$ is a well-formedness side condition binding the re-entrant call to an actual entry point of the victim, so the method $m'$ it invokes is a genuine witness for $\exists m' \in \mathsf{methods}(c)$. It is discharged statically by Slither. The side condition requires only $m' \in \mathsf{methods}(c)$, not $m' = m$, so both the specification and this check permit $m' \neq m$; the [Act] detection threshold $\mathsf{reentrancyCount} > 1$, however, is reached only when the re-entered method itself re-opens the callback window, so the derived template witnesses the *same-function* pattern (and cross-function cases where $m'$ re-yields control), while general cross-function reentrancy — where the re-entered $m' \neq m$ does not itself re-open the callback window — is out of scope for this template and requires a dedicated variant.

Post-condition derives the *assert* phase:

$$\dfrac{\displaystyle \mathsf{Exec}(c',m(x),\sigma,\sigma_b) \in \mathrm{conjuncts}(\Phi) \quad \neg\mathcal{I}(\sigma_b) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{assert}} \left[\begin{array}{l} \texttt{assertTrue}(\mathsf{initialInvariantHolds});\; \texttt{assertTrue}(\mathit{attacker}.\mathsf{exploitSucceeded}());\; \\ \texttt{bool}\ \mathsf{invariantBrokenAtBoundary} = {!}h_{\mathcal{I}};\; \texttt{assertTrue}(\mathsf{invariantBrokenAtBoundary}) \end{array}\right]} \quad \text{[Assrt]}$$

All phases combine into the full schema:

$$\dfrac{\displaystyle \Phi \vdash H \qquad \Phi \vdash_{\mathit{setUp}} S \qquad \Phi \vdash_{\mathit{action}} A \qquad \Phi \vdash_{\mathit{callback}} \mathit{CB} \qquad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H,\, S,\, A,\, \mathit{CB},\, \mathit{AS} \rangle} \quad \text{[Template]}$$


## Derived Reentrancy Multi-Shot Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested.
// [LLM_INSTRUCTION]: If you need to manipulate private state directly, import StdStorage: import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The solidity files are in "../src/". The name of the file is the same as the name of the contract.

// ------------------------------ 
// [Testing Goal] Prove that execution control can be hijacked to perform
// recursive calls, thereby breaking the intended atomicity of a sensitive method.
// ------------------------------ 

// [LLM_INSTRUCTION]: Name the contract 'TestReentrancy[ContractName]'
contract TestReentrancyTemplate is Test {
    // [LLM_INSTRUCTION]: Use StdStorage if needed for complex state setup: using stdStorage for StdStorage;

// ------------------------------ 
    // [Setup] Declare the contract under test and the malicious attacker contract.
// ------------------------------ 

    // [LLM_INSTRUCTION]: Declare the contract under test variable (e.g. ReentrancySimple public _contractUnderTest)
    
    Attacker public _attacker;

// ------------------------------ [/Setup]

    function setUp() public {
// ------------------------------ 
        // [Setup] Initialize the victim contract and the attacker contract.
// ------------------------------ 

        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // 1. If the constructor has parameters, use valid concrete values here (or setup variables).
        // 2. If the constructor is payable, use 'vm.deal(address(this), amount)' before 'new'.
        
        // _contractUnderTest = new ReentrancySimple();

        _attacker = new Attacker(address(_contractUnderTest));

// ------------------------------ [/Setup]
    }

    // [LLM_INSTRUCTION]: Add Fuzz/Symbolic arguments to the test function.
    // 1. 'attackVal': The value sent/withdrawn during the attack (e.g. amount).
    // 2. 'stateVal': Any value needed to configure the initial state (e.g. initial balance).
    // Example: function test_attackerCallsWithdrawMultipleTimes(uint256 attackVal, uint256 stateVal) public {
    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
// ------------------------------ 
        // [Setup] Constrain Fuzz/Symbolic values and configure pre-conditions.
// ------------------------------ 

        // [LLM_INSTRUCTION]: Constrain the Fuzz/Symbolic values using 'vm.assume'.
        // WARNING: Avoid Integer Overflow. If attackVal is added to balances, ensure it doesn't wrap around.
        // WARNING: Avoid Balance Overflow. Do not use type(uint256).max for ETH amounts.
        // WARNING: Avoid Integer Underflow or Overflow during the attack scenario.
        // SUGGESTION: Use vm.assume to limit attackVal to a safe range.
        // SUGGESTION: Use type(uint128).max as a safe upper bound for balance math.
        // SUGGESTION: Limit the exploit to 1 initial call and 1 re-entrant call for simplicity.
        
        //vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // [LLM_INSTRUCTION]: Does the vulnerable function require specific state?
        // (e.g., specific balance, time passed, authorized user, boolean flag).

        // STRATEGY A: Public Methods (Preferred)
        // Call public setters or 'deposit' functions.
        // Example: _contractUnderTest.setVal(fuzzArg);

        // STRATEGY B: Storage Manipulation (For Private/Hard-to-reach State)
        // If the variable is private or requires complex logic to set, use 'vm.store' or 'stdstore'.
        // Example:
        // stdstore.target(address(_contractUnderTest)).sig("myVar()").checked_write(fuzzArg);
        
        // TIMING: If logic depends on time, use vm.warp(block.timestamp + 100);
// ------------------------------ [/Setup]
// ------------------------------ 
        // [Setup] (Arrange) Fund both parties with vm.deal, perform the attacker's
        // deposit, and capture the consistency invariant at the boundary state sigma.
// ------------------------------ 

        // [LLM_INSTRUCTION]: Fund the contracts using vm.deal.
        // Use the fuzzed 'attackVal' to ensure sufficient balance.
        
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        // B. Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
        // The test contract needs funds because it sends 'attackVal' to the Attacker in the deposit step below.
        // Without this, the test will fail with 'EvmError: OutOfFunds' if attackVal > default test balance.
        vm.deal(address(this), attackVal * 2);

        // [LLM_INSTRUCTION]: If the contract requires specific state (e.g. logic dependent on block.timestamp), set it here.

        // [LLM_INSTRUCTION]: Perform the attacker's deposit. setupAttack completes the
        // consistent boundary state sigma from which the vulnerable method is invoked.
        // Note: The {value: attackVal} here draws from address(this), which is why we funded it above.
        _attacker.setupAttack{value: attackVal}(attackVal);

        // [LLM_INSTRUCTION]: Capture the consistency invariant I at the boundary sigma
        // (after the deposit, before the exploit). This records C1, I(sigma).
        // Read the victim's public state to evaluate I (e.g., victim balance >= sum of deposits).
        // bool initialInvariantHolds = (/* invariant predicate over victim state at sigma */);
        bool initialInvariantHolds = true; // PLACEHOLDER: replace with the invariant check at sigma

// ------------------------------ [/Setup]

// ------------------------------ 
        // [Action] (Act) Trigger the exploit. attack() calls the victim's vulnerable
        // method, issuing the external call that yields control back to the attacker.
// ------------------------------ 

        _attacker.attack(attackVal);

// ------------------------------ [/Action]

// ------------------------------ 
        // [Assertion] (Assert) Three checks run by the test contract:
        //  C1: the consistency invariant held at the boundary sigma;
        //  C3 & C6: re-entry occurred while the invariant was violated at sigma_i
        //           (exploitSucceeded = reentrancyCount > 1 && invariantBroken);
        //  C7 & C8: the outer attack() call returns at the transaction boundary sigma_b,
        //           where the contract's specification is violated.
        // (initialInvariantHolds is captured in the arrange phase above.)
// ------------------------------ 

        // C1: invariant held at sigma (captured above, before the exploit).
        assertTrue(initialInvariantHolds, "Invariant did not hold at the boundary state sigma.");

        // C3 & C6: re-entry occurred while the invariant was broken at sigma_i.
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");

        // [LLM_INSTRUCTION]: Compute invariantBrokenAtBoundary by re-evaluating the invariant I at the
        // transaction boundary sigma_b (after attack() returns); the invariant is violated iff I is false.
        // bool invariantBrokenAtBoundary = !(/* invariant predicate over victim state at sigma_b */);
        bool invariantBrokenAtBoundary = true; // PLACEHOLDER: replace with the invariant re-check at sigma_b
        // C8: invariant violated at the boundary sigma_b.
        assertTrue(invariantBrokenAtBoundary, "Invariant not violated at the boundary: contract appears protected.");

// ------------------------------ [/Assertion]
    }

    // Keep this so the test contract can receive Ether from the contract being tested on the "positive" scenario
    receive() external payable {}
}

// ------------------------------ 
// [Setup] The LLM generates a malicious attacker contract (e.g., ExploitContract)
// that tracks the number of re-entries using a dedicated state variable
// (reentrancyCount).
// ------------------------------ 

contract Attacker {
    // [LLM_INSTRUCTION]: Declare the victim contract variable with its specific type.
    // ReentrancySimple public _victim;
    
    // [Setup] Dedicated state variables to track the exploit trace.
    uint256 public reentrancyCount;   // number of re-entries
    bool public invariantBroken;      // I violated at the intermediate state sigma_i
    bool public exploitSucceeded;     // reentrancyCount > 1 && invariantBroken

    // [LLM_INSTRUCTION]: Declare state variables to store the Fuzz/Symbolic values.
    // We must store them because 'receive()' cannot accept arguments.
    // uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        // [LLM_INSTRUCTION]: Cast and store the victim address.
        // _victim = ReentrancySimple(victimAddress);
    }

// ------------------------------ [/Setup]

// ------------------------------ 
    // [Setup] Prepare the attacker's initial state (e.g., deposit into victim).
// ------------------------------ 

    // [LLM_INSTRUCTION]: Update signature to accept Fuzz/Symbolic values.
    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        invariantBroken = false;
        
        // [LLM_INSTRUCTION]: Perform preparation steps (e.g. deposit) using the Fuzz/Symbolic value.
        // Check: If the vulnerability requires a 'deposit' first, do it here.
        // _victim.deposit{value: val}();
    }

// ------------------------------ [/Setup]

// ------------------------------ 
    // [Action] Initiate the exploit by calling the victim's vulnerable function.
// ------------------------------ 

    // [LLM_INSTRUCTION]: Update signature to accept Fuzz/Symbolic values.
    function attack(uint256 val) public {
        // [LLM_INSTRUCTION]: 1. Store the value for the re-entrant call if needed.
        // storedAttackVal = val;

        // [LLM_INSTRUCTION]: 2. Call the vulnerable function.
        // This initiates the external call that will trigger the callback.
        // _victim.withdraw(); (Or _victim.withdraw(val) if it takes args)

        // [Assertion] Set exploitSucceeded conjoining the two callback-window facts:
        // re-entry occurred (reentrancyCount > 1) AND the invariant was broken at sigma_i.
        exploitSucceeded = (reentrancyCount > 1 && invariantBroken);
    }
// ------------------------------ [/Action]

// ------------------------------ 
    // [Callback Logic] Within receive()/fallback(), re-invoke the victim's
    // vulnerable method. Increment reentrancyCount on each entry and record
    // invariantBroken by evaluating the invariant at the intermediate state sigma_i,
    // providing a trace-based proof of the exploit.
// ------------------------------ 

    receive() external payable {
        reentrancyCount++;
        if (reentrancyCount < 2) {
            // [LLM_INSTRUCTION]: Record whether the consistency invariant I is violated at the
            // intermediate state sigma_i (the victim's method is still suspended here).
            // Read the victim's public state to evaluate I.
            // invariantBroken = !(/* invariant predicate over victim state at sigma_i */);

            // [LLM_INSTRUCTION]: Re-enter the victim's vulnerable method using the stored Fuzz/Symbolic value.
            // _victim.withdraw(); (Or _victim.withdraw(storedAttackVal))
        }
    }

// ------------------------------ [/Callback Logic]
}
```

### Rule Application

The derivation $\mathsf{Reentrant}(c) \vdash \tau$ proceeds by applying the six rules in sequence. For each step we identify the triggering conjunct(s) from $\mathsf{Reentrant}(c)$, state what the rule derives, and map the output to the specific region of the code template above.

---

**Step 1 — [Holes]** (no premise)

The axiom fires unconditionally and establishes the hole signature:

$$H = \bigl\{\, h_m : \mathsf{Method},\quad h_{\mathit{reenter}} : \mathsf{CallExpr},\quad h_{\mathcal{I}} : \mathsf{BoolExpr},\quad h_{\mathit{init}} : \mathsf{State} \,\bigr\}$$

Each hole appears in the template as a $\tt [LLM\_INSTRUCTION]$ placeholder:

| Hole | Sort | Stands for | Filled by |
|---|---|---|---|
| $h_m$ | $\tt Method$ | the victim's vulnerable method | LLM (e.g., $\tt \_victim.withdraw$) |
| $h_{\mathit{reenter}}$ | $\tt CallExpr$ | the re-entrant call inside $\tt receive()$ | LLM (e.g., $\tt \_victim.withdraw(storedAttackVal)$) |
| $h_{\mathcal{I}}$ | $\tt BoolExpr$ | the boolean invariant expression | LLM (e.g., $\tt address(\_victim).balance \geq initialDeposit$) |
| $h_{\mathit{init}}$ | $\tt State$ | the state-initializing statements in $\tt setUp()$ | LLM (e.g., $\tt \_contractUnderTest = new\ VulnerableContract()$) |

---

**Step 2 — [Pre]** fires on $C_1 = \mathcal{I}(\sigma)$

Triggering conjunct: $\mathcal{I}(\sigma) \in \mathrm{conjuncts}(\mathsf{Reentrant}(c))$ — the initial state must satisfy the consistency property.

Derives:
$$\Phi \vdash_{\mathit{setUp}} \bigl[\,\texttt{vm.deal}(\mathit{victim},\cdot);\; \texttt{vm.deal}(\mathit{attacker},\cdot);\; h_{\mathit{init}};\; \mathsf{reentrancyCount} = 0;\; \mathsf{exploitSucceeded} = \mathsf{false};\; \mathsf{invariantBroken} = \mathsf{false};\; \mathit{attacker}.\texttt{setupAttack\{value:}v\texttt{\}}(v);\; \texttt{bool}\ \mathsf{initialInvariantHolds} = h_{\mathcal{I}}\,\bigr]$$

Template realization — the $\tt [Setup]$/arrange phase covers:

- In $\tt setUp()$: the $\tt [LLM\_INSTRUCTION]$ for $h_{\mathit{init}}$ instantiates the victim ($\tt \_contractUnderTest = new\ ...$) and wires it to the attacker ($\tt \_attacker = new\ Attacker(address(\_contractUnderTest))$).
- In $\tt test\_attackerCallsMultipleTimes()$: $\tt vm.deal(...)$ funds both parties; $\tt \_attacker.setupAttack\{value: attackVal\}(attackVal)$ performs the deposit that completes the consistent boundary state $\sigma$; and $\tt bool\ initialInvariantHolds = $$h_{\mathcal{I}}$ captures the invariant at $\sigma$ (this records $C_1$, asserted in Step 5).
- In $\tt setupAttack()$: $\tt reentrancyCount = 0;\ exploitSucceeded = false;\ invariantBroken = false$ reset the trace flags before the exploit.

---

**Step 3 — [Act]** fires on $C_2$, $C_4$, and $C_6$

Triggering conjuncts:
- $C_2 = \mathsf{Interm}(\sigma_i, c', \sigma, m)$ — there exists an intermediate state during execution of $m$ (by caller $c'$).
- $C_4 = \mathsf{YieldsControl}(c, c', m)$ — discharged **statically**: Slither confirms that $h_m$ contains an external CALL/DELEGATECALL instruction, so invoking $h_m$ will transfer control to the attacker contract $c'$.
- $C_6 = \mathsf{Exploit}(\sigma'_f)$ — the exploit indicator must be true in the post-state.

Derives:
$$\Phi \vdash_{\mathit{action}} \bigl[\,\mathit{attacker}.\texttt{attack}(v)\,\bigr]$$

where $\tt attack$ calls $\texttt{victim.}h_m\texttt{(v)}$ and, after the callback unwinds, evaluates $\texttt{exploitSucceeded = (reentrancyCount > 1 \&\& invariantBroken)}$. The deposit ($\tt setupAttack$) was performed in the *setUp*/arrange phase (Step 2).

Template realization — the $\tt [Action]$ region in $\tt test\_attackerCallsMultipleTimes()$:
```solidity
_attacker.attack(attackVal);                          // triggers C₂/C₄: enters h_m, fires the external CALL
```
And inside $\tt attack()$:
```solidity
// _victim.withdraw();                                // = victim.h_m(v)  →  C₂, C₄
// exploitSucceeded = (reentrancyCount > 1 && invariantBroken);  // = Exploit(σ'_f)  →  C₆ (with C₃)
```
The call $\tt \_attacker.attack(v)$ causes $\texttt{victim.}h_m\texttt{(v)}$ to issue the external CALL (witnessing $C_2$ and $C_4$). Only after the full callback stack unwinds is $\tt exploitSucceeded$ evaluated, conjoining $\tt reentrancyCount > 1$ (re-entry, $C_6$) with $\tt invariantBroken$ (the invariant violated at $\sigma_i$, $C_3$, recorded in Step 4).

---

**Step 4 — [Cbk]** fires on $C_5$ (and captures $C_3$)

Triggering conjunct: $C_5 = \mathsf{Exec}(c', m', \sigma_i, \sigma'_f)$ — $m'$ is executed by the external callee $c'$ from the intermediate state $\sigma_i$, reaching post-state $\sigma'_f$. The callback also captures $C_3 = \neg\mathcal{I}(\sigma_i)$ at runtime.

Derives:
$$\Phi \vdash_{\mathit{callback}} \left[\texttt{receive()}\;\bigl\{\; \mathsf{reentrancyCount}\texttt{++};\; \textbf{if}\;(\mathsf{reentrancyCount} < 2)\;\{\; \mathsf{invariantBroken} = {!}h_{\mathcal{I}};\; h_{\mathit{reenter}}\;\} \;\bigr\}\right] \quad (\text{with side condition } \mathsf{target}(h_{\mathit{reenter}}) \in \mathsf{methods}(c))$$

Template realization — the $\tt [Callback\ Logic]$ region in $\tt Attacker$:
```solidity
receive() external payable {
    reentrancyCount++;                          // records entry into σ_i
    if (reentrancyCount < 2) {
        // invariantBroken = !(/* invariant at σ_i */);  // = ¬I(σ_i)  →  C₃
        // _victim.withdraw();                  // = h_reenter = Exec(c', m', σ_i, σ'_f)  →  C₅
    }
}
```
$\tt receive()$ is invoked when the victim's CALL transfers ETH to the attacker. Incrementing $\tt reentrancyCount$ *before* re-entering makes the intermediate state $\sigma_i$ observable at runtime. Because the callback runs while $h_m$ is still suspended, evaluating $\tt invariantBroken = !$$h_{\mathcal{I}}$ there captures the invariant violation at $\sigma_i$ ($C_3$) as a constructive runtime witness — no static (CEI) assumption is needed. The guard $\tt reentrancyCount < 2$ limits re-entry to exactly one recursive call, sufficient to witness $C_5$: $h_{\mathit{reenter}}$ (filled by the LLM as $\tt \_victim.withdraw(...)$) is the concrete execution of $m'$ from $\sigma_i$.

---

**Step 5 — [Assrt]** fires on $C_7$ and $C_8$

Triggering conjuncts: $C_7 = \mathsf{Exec}(c', m, \sigma, \sigma_b)$ — the outer invocation of $m$ returns at the transaction boundary $\sigma_b$ (witnessed by $\tt attack$ returning) — and $C_8 = \neg\mathcal{I}(\sigma_b)$ — the consistency invariant is violated at that boundary. The *assert* phase is the verification phase: it also validates the boundary witness $C_1$ and the attacker's $\tt exploitSucceeded$ flag ($C_3$, $C_6$).

Derives:
$$\Phi \vdash_{\mathit{assert}} \bigl[\,\texttt{assertTrue}(\mathsf{initialInvariantHolds});\; \texttt{assertTrue}(\mathit{attacker}.\mathsf{exploitSucceeded}());\; \texttt{bool}\ \mathsf{invariantBrokenAtBoundary} = {!}h_{\mathcal{I}};\; \texttt{assertTrue}(\mathsf{invariantBrokenAtBoundary})\,\bigr]$$

Template realization — the $\tt [Assertion]$ region:
```solidity
assertTrue(initialInvariantHolds, "...");                 // C₁: invariant held at σ
assertTrue(_attacker.exploitSucceeded(), "...");          // C₃, C₆: re-entry while invariant broken
bool invariantBrokenAtBoundary = !(/* invariant at σ_b */);
assertTrue(invariantBrokenAtBoundary, "...");             // C₈: invariant broken at boundary σ_b
```
A passing run means: $\tt initialInvariantHolds$ held at $\sigma$ (witnessing $C_1$); $\tt exploitSucceeded$ was set in Step 3 from $\tt reentrancyCount > 1$ and $\tt invariantBroken$ (witnessing $C_6$ and $C_3$); the outer $\tt attack$ call returned, reaching the boundary $\sigma_b$ (witnessing $C_7 = \mathsf{Exec}(c,m,\sigma,\sigma_b)$); and $\tt invariantBrokenAtBoundary$ holds at $\sigma_b$, i.e. $\neg\mathcal{I}(\sigma_b)$, witnessing $C_8$ directly in the boundary state recorded by Forge/Kontrol.

---

**Step 6 — [Template]** assembles all five sub-derivations

All premises of [Template] are now established:

| Premise | Established in |
|---|---|
| $\Phi \vdash H$ | Step 1 |
| $\Phi \vdash_{\mathit{setUp}} S$ | Step 2 |
| $\Phi \vdash_{\mathit{action}} A$ | Step 3 |
| $\Phi \vdash_{\mathit{callback}} CB$ | Step 4 |
| $\Phi \vdash_{\mathit{assert}} AS$ | Step 5 |

Applying [Template] yields $\mathsf{Reentrant}(c) \vdash \langle H, S, A, CB, AS \rangle = \tau$, which is exactly the code template above with four open holes for the LLM to fill. The conjuncts $C_1$–$C_8$ of $\mathsf{Reentrant}(c)$ are each covered by exactly one of the five phases of $\tau$ as recorded in the Phase–Conjunct table above, completing the derivation.

## Soundness of $\vdash$ for $\mathsf{Reentrant}_{\mathcal{I}}(c)$

**Theorem (Soundness of $\vdash$ for $\mathsf{Reentrant}_{\mathcal{I}}(c)$).**
Let $\mathsf{Reentrant}_{\mathcal{I}}(c) \vdash \tau$ be derivable by the rules above, let $\tau[\theta]$ be a ground instance of $\tau$ obtained by resolving all holes in $H$ (Slither for $h_m$, LLM for the remainder), and let $M_{\tau[\theta]}$ be the EVM execution trace produced by running $\tau[\theta]$. Assume further that $\tau[\theta]$ is *non-vacuous*: the path constraints accumulated by *setUp* together with the model-supplied $\tt vm.assume$s are jointly satisfiable on a path on which the runtime atoms of $C_1$–$C_8$ are evaluated (so that $M_{\tau[\theta]}$ is a genuine, non-empty execution). Then

$$\tau[\theta] \text{ passes in Forge/Kontrol} \;\Longrightarrow\; M_{\tau[\theta]} \models \mathsf{Reentrant}_{\mathcal{I}}(c).$$

That is, a passing test induces an execution trace $M_{\tau[\theta]}$ that is a model of, hence a *constructive witness* for, the existential statement $\mathsf{Reentrant}_{\mathcal{I}}(c)$. Here $\models$ interprets every atom of the ($\mathcal{I}$-instantiated) schema on $\mathcal{P}_0/\mathcal{P}_1$ in the usual way; every conjunct, including the boundary conjunct $C_8 = \neg\mathcal{I}(\sigma_b)$, is read off the trace. The LLM's task is precisely to find the ground substitution $\theta$ (including the invariant $\theta(h_{\mathcal{I}})$); the $\models$ check (Forge/Kontrol execution) confirms it on $M_{\tau[\theta]}$.

**Setup.** Recall the reentrancy specification, with its eight conjuncts labelled:

$$\begin{aligned}
\mathsf{Reentrant}_{\mathcal{I}}(c) \equiv{} &
  \exists m,m' \in \mathsf{methods}(c).\;
  \exists c' \neq c.\;
  \exists x \in \mathsf{Dom}(m).\;
  \exists \sigma, \sigma_i, \sigma'_f, \sigma_b \in \mathsf{State}.\\
  &\underbrace{\mathcal{I}(\sigma)}_{C_1}
  \;\land\; \underbrace{\mathsf{Interm}(\sigma_i,c',\sigma,m(x))}_{C_2}
  \;\land\; \underbrace{\neg\mathcal{I}(\sigma_i)}_{C_3}
  \;\land\; \underbrace{\mathsf{YieldsControl}(c,c',m)}_{C_4}
  \\&
  \;\land\; \underbrace{\mathsf{Exec}(c',m',\sigma_i,\sigma'_f)}_{C_5}
  \;\land\; \underbrace{\mathsf{Exploit}(\sigma'_f)}_{C_6}
  \;\land\; \underbrace{\mathsf{Exec}(c',m(x),\sigma,\sigma_b)}_{C_7}
  \;\land\; \underbrace{\neg\mathcal{I}(\sigma_b)}_{C_8}
\end{aligned}$$

We treat $\mathsf{Reentrant}_{\mathcal{I}}(c)$ as a defect schema: the schema parameter $\mathcal{I}$ is fixed at the meta-level by the LLM's choice $\theta(h_{\mathcal{I}})$, so the statement is a FOL sentence. The derivation $\mathsf{Reentrant}(c) \vdash \tau$ is a flat tree whose leaves are the phase judgements and whose root is [Template]. By inversion on the derivation rules, we show that each conjunct $C_1,\ldots,C_8$ is satisfied in the test-induced model $M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle$, where $\mathcal{S}$ is the underlying many-sorted domain (EVM states, methods, etc.), $\mathcal{P}_0 = \mathrm{Slither}(c)$, $\mathcal{P}_1$ is extracted from the EVM execution trace of $\tau[\theta]$, and the witness tuple is $\mathcal{W} = (\theta(h_m),\, m',\, \mathit{attacker},\, v,\, \theta(h_{\mathcal{I}}),\, \theta(h_{\mathit{init}}),\, \sigma_i,\, \sigma'_f,\, \sigma_b)$, where $m'$ is the method targeted by the call expression $\theta(h_{\mathit{reenter}})$, $\mathit{attacker}$ is the deployed LLM-generated contract realizing the external callee $c'$ (the $\tt CALL$ target identified by Slither), $v$ is the concrete outer argument witnessing $x$, and $\sigma_i,\sigma'_f,\sigma_b$ are read off the trace $\mathcal{P}_1$ (Steps 4–5). The tuple thus assigns a concrete value to every one of the eight existentials bound by the prefix of the specification (together with the schema parameter $\theta(h_{\mathcal{I}})$).

**Step 1 ([Holes]): witnesses are well-typed.** The [Holes] rule establishes the hole signature

$$H = \bigl\{ h_m : \mathsf{Method},\; h_{\mathit{reenter}} : \mathsf{CallExpr},\; h_{\mathcal{I}} : \mathsf{BoolExpr},\; h_{\mathit{init}} : \mathsf{State} \bigr\}$$

with the resolution strategy $\mathit{res} : H \to \{\mathsf{Slither},\mathsf{LLM}\}$ defined as $\mathit{res}(h_m) = \mathsf{Slither}$ and $\mathit{res}(h_{\mathit{reenter}}) = \mathit{res}(h_{\mathcal{I}}) = \mathit{res}(h_{\mathit{init}}) = \mathsf{LLM}$. By assumption:

- $\theta(h_m) \in \mathsf{methods}(c)$ per Slither's output $\Rightarrow$ $\theta(h_m)$ is a valid existential witness for $m$;
- $\theta(h_{\mathit{reenter}})$, $\theta(h_{\mathcal{I}})$, $\theta(h_{\mathit{init}})$ are syntactically valid Solidity expressions, so $\tau[\theta]$ is a type-correct Forge test.

The intermediate state $\sigma_i$ carries no explicit hole; its existence is witnessed at runtime by $\mathsf{reentrancyCount} \geq 1$ (Step 4 below).

**Lemma (Hole Typing).** If $\vdash H : \tau$ (the hole signature $H$ is derivable for the template $\tau$) and $\tau[\theta]$ does not revert on a type error, then $\mathcal{W}$ is a valid witness candidate for the existential prefix of $\mathsf{Reentrant}(c)$. ✓

**Step 2 ([Pre]): conjunct $C_1$ satisfied.** The [Pre] rule fires because $\mathcal{I}(\sigma) \in \mathrm{conjuncts}(\mathsf{Reentrant}(c))$ and derives the $\tt setUp$ phase:

$$\begin{array}{l}
\texttt{vm.deal}(\mathit{victim},\cdot);\; \texttt{vm.deal}(\mathit{attacker},\cdot);\; \theta(h_{\mathit{init}});\\
\mathsf{reentrancyCount} = 0;\; \mathsf{exploitSucceeded} = \mathsf{false};\; \mathsf{invariantBroken} = \mathsf{false};\\
\mathit{attacker}.\texttt{setupAttack\{value:}v\texttt{\}}(v);\; \texttt{bool}\;\mathsf{initialInvariantHolds} = \theta(h_{\mathcal{I}})
\end{array}$$

When $\tau[\theta]$ passes, the *setUp*/arrange phase — deployment, funding, and the attacker's deposit via $\tt setupAttack$ — executed without reverting, so the consistent initial state $\sigma$ is reachable. The invariant at $\sigma$ is *checked*, not assumed: once the deposit has established $\sigma$ — the state in which the vulnerable method is invoked, before any external call — the test contract captures $\mathsf{initialInvariantHolds} = \theta(h_{\mathcal{I}})$, evaluating the invariant at $\sigma$. Since $\tau[\theta]$ passes, the assertion $\texttt{assertTrue}(\mathsf{initialInvariantHolds})$ (Step 5) forces $\mathsf{initialInvariantHolds} = \mathsf{true}$, hence $\theta(h_{\mathcal{I}})(\sigma) \in \mathcal{P}_1$, which establishes $C_1$ ($M_{\tau[\theta]} \models C_1$) as a runtime witness rather than an assumption on the freshly-initialized state. ✓

**Step 3 ([Act]): conjuncts $C_2$, $C_4$, $C_6$ satisfied.** The [Act] rule fires because $\mathsf{Interm}(\sigma_i,c',\sigma,m(x))$, $\mathsf{YieldsControl}(c,c',m)$, and $\mathsf{Exploit}(\sigma'_f)$ are all in $\mathrm{conjuncts}(\mathsf{Reentrant}(c))$, and derives the $\tt action$ phase $\mathit{attacker}.\texttt{attack}(v)$, where $\tt attack$ calls $\mathit{victim}.\theta(h_m)(v)$ and assigns $\mathsf{exploitSucceeded} = (\mathsf{reentrancyCount} > 1\ \texttt{\&\&}\ \mathsf{invariantBroken})$. Here $\mathsf{invariantBroken}$ is set inside the callback at $\sigma_i$ (Step 4, witnessing $C_3$) and $\mathsf{reentrancyCount} > 1$ records re-entry ($C_6$); the boundary witnesses $C_1$ ($\mathsf{initialInvariantHolds}$, captured in *setUp*, Step 2) and $C_8$ ($\mathsf{invariantBrokenAtBoundary}$ at $\sigma_b$) are asserted by the test contract in the $\tt assert$ phase (Step 5). When $\tau[\theta]$ passes, the outer call to $\mathit{victim}.\theta(h_m)$ executes and fires an EVM $\tt CALL$ instruction transferring control to the attacker contract. From the execution trace:

- The trace records the nested-call entry point, witnessing an intermediate state $\sigma_i$ during $\theta(h_m)$'s execution: $\mathsf{Interm}(\sigma_i, c', \sigma, \theta(h_m)(v)) \in \mathcal{P}_1$ establishes $C_2$ ($M_{\tau[\theta]} \models C_2$), the concrete outer argument $v$ witnessing the prefix existential $x$.
- Slither identifies $\theta(h_m)$ as containing a $\tt CALL$ to an external address $c'$: $\mathsf{YieldsControl}(c, c', m) \in \mathcal{P}_0$ establishes $C_4$ ($M_{\tau[\theta]} \models C_4$). By the CALL-target precision premise, this $c'$ is the address at which the LLM-deployed attacker runs, hence the *same* callee bound in $C_5$ and $C_7$, so the prefix existential $\exists c'\neq c$ is witnessed consistently across the three conjuncts.
- After the re-entrant call stack unwinds back to $\tt attack$, $\mathsf{reentrancyCount} > 1$ holds, recording $\mathsf{Exploit}(\sigma'_f) \in \mathcal{P}_1$, which establishes $C_6$ ($M_{\tau[\theta]} \models C_6$). The counter is read after the stack unwinds rather than at $\sigma'_f$ itself, but this is faithful precisely because $\mathsf{Exploit}$ is a *monotone* trace property: its indicator $\mathsf{reentrancyCount}$ is initialised to $0$ in [Pre] and only ever *incremented*, inside the attacker's $\tt receive()$ ([Cbk]), with no decrement or reset anywhere in $\tau$, so once it exceeds $1$ at $\sigma'_f$ it stays $>1$ at every later state; its post-unwind value $>1$ therefore witnesses $\mathsf{Exploit}(\sigma'_f)$ at the firing state $\sigma'_f$.

✓

**Step 4 ([Cbk]): conjuncts $C_3$ and $C_5$ satisfied.** The [Cbk] rule fires because $\neg\mathcal{I}(\sigma_i) \in \mathrm{conjuncts}(\mathsf{Reentrant}(c))$ and $\mathsf{Exec}(c',m',\sigma_i,\sigma'_f) \in \mathrm{conjuncts}(\mathsf{Reentrant}(c))$ and derives the $\tt callback$ phase inside $\tt receive()$:

$$\mathsf{reentrancyCount}\texttt{++};\quad \textbf{if}\;(\mathsf{reentrancyCount} < 2)\;\{\, \mathsf{invariantBroken} = \texttt{!}\theta(h_{\mathcal{I}});\; \theta(h_{\mathit{reenter}})\,\}$$

When $\tau[\theta]$ passes:

- The attacker's $\tt receive()$ executed, and the expression $\theta(h_{\mathit{reenter}})$ re-invoked a method on the $\mathit{victim}$. The trace records $\mathsf{Exec}(c', m', \sigma_i, \sigma'_f)$ (a second $\tt CALL$ entry at depth $> 1$, where $m'$ is the method targeted by $\theta(h_{\mathit{reenter}})$), i.e., $\mathsf{Exec}(c', m', \sigma_i, \sigma'_f) \in \mathcal{P}_1$ — which establishes $C_5$ ($M_{\tau[\theta]} \models C_5$). By the [Cbk] well-formedness side condition $\mathsf{target}(h_{\mathit{reenter}}) \in \mathsf{methods}(c)$, this $m'$ lies in $\mathsf{methods}(c)$, so it is a genuine witness for the bound existential $\exists m' \in \mathsf{methods}(c)$ (it may differ from $m$, though the $\mathsf{reentrancyCount} > 1$ detection witnesses such a re-entry only when the re-entered method re-opens the callback window; general cross-function reentrancy is out of scope — see Scope below).
- The callback body runs *while the outer call to $\theta(h_m)$ is suspended*, i.e., exactly at the intermediate state $\sigma_i$. The assignment $\mathsf{invariantBroken} = \texttt{!}\theta(h_{\mathcal{I}})$ therefore evaluates the invariant *at* $\sigma_i$. Since $\tau[\theta]$ passes, $\texttt{assertTrue}(\mathsf{exploitSucceeded})$ forces $\mathsf{invariantBroken} = \mathsf{true}$, hence $\theta(h_{\mathcal{I}})(\sigma_i) \not\in \mathcal{P}_1$, which establishes $C_3$ ($M_{\tau[\theta]} \models C_3$). This is a constructive runtime witness extracted directly from the trace; no static (CEI) assumption on $\theta(h_m)$ is required.

The intermediate state $\sigma_i$ is thereby concretely witnessed in the trace, closing the open existential $\exists\sigma_i$ from Step 3. ✓

**Step 5 ([Assrt]): conjuncts $C_7$ and $C_8$ satisfied.** The [Assrt] rule fires because $\mathsf{Exec}(c',m(x),\sigma,\sigma_b) \in \mathrm{conjuncts}(\mathsf{Reentrant}_{\mathcal{I}}(c))$ and $\neg\mathcal{I}(\sigma_b) \in \mathrm{conjuncts}(\mathsf{Reentrant}_{\mathcal{I}}(c))$ and derives the $\tt assert$ phase, executed by the test contract:

$$\begin{array}{l}
\texttt{assertTrue}(\mathsf{initialInvariantHolds});\quad \texttt{assertTrue}(\mathit{attacker}.\mathsf{exploitSucceeded}());\\
\mathsf{invariantBrokenAtBoundary} = \texttt{!}\theta(h_{\mathcal{I}});\quad \texttt{assertTrue}(\mathsf{invariantBrokenAtBoundary})
\end{array}$$

The re-entrant inner call has post-state $\sigma'_f$ (the $\mathsf{Exec}(c',m',\sigma_i,\sigma'_f)$ witness of $C_5$, Step 4). When the outer call $\mathit{attacker}.\texttt{attack}$ returns, the EVM has fully unwound the call stack: the suspended outer method $\theta(h_m)$ has resumed and run to completion, so the trace records the outer execution $\mathsf{Exec}(c',m(x),\sigma,\sigma_b) \in \mathcal{P}_1$, where $\sigma_b$ is the transaction-boundary post-state of $m$ (and $\sigma_i$ its intermediate state, $C_2$). This establishes $C_7$ ($M_{\tau[\theta]} \models C_7$) and concretely witnesses the boundary state $\sigma_b$. Crucially, $C_2 = \mathsf{Interm}(\sigma_i,c',\sigma,m(x))$ and $C_7 = \mathsf{Exec}(c',m(x),\sigma,\sigma_b)$ share the same applied triple $\langle c', m(x), \sigma\rangle$; since $\mathsf{Exec}$ is functional in those arguments, both refer to the single outer run — the one issued by the attacker's $\tt attack$, whose concrete outer argument witnesses $x$ — so $\sigma_i$ is genuinely an intermediate state of the very run that terminates at $\sigma_b$. The boundary violation at $\sigma_b$ is therefore caused by the same execution whose callback window is witnessed at $\sigma_i$, not by an unrelated run. The test contract then re-evaluates the invariant *at* $\sigma_b$, assigning $\mathsf{invariantBrokenAtBoundary} = \texttt{!}\theta(h_{\mathcal{I}})$. Although this re-evaluation is performed by the test contract *after* $\tt attack$ returns, it observes precisely $\sigma_b$ on $c$: by construction the attacker's $\tt attack$ issues no state-changing call to $c$ after the outer call to $\theta(h_m)$ returns, so the only state-changing operation between $m$'s return at $\sigma_b$ and the boundary read is the attacker's own assignment to $\mathsf{exploitSucceeded}$ (a write to the attacker's storage), which $h_{\mathcal{I}}$ — a consistency predicate over $c$ — does not read, while the assert phase otherwise performs only reads. Hence $c$'s state at the boundary read agrees with $\sigma_b$ on everything $h_{\mathcal{I}}$ observes, so $\theta(h_{\mathcal{I}})$ evaluated there reflects exactly $\sigma_b$.

When $\tau[\theta]$ passes, none of the $\tt assertTrue$ calls threw. From $\texttt{assertTrue}(\mathsf{initialInvariantHolds})$, $\theta(h_{\mathcal{I}})(\sigma)$ is true — the invariant the test contract captured at $\sigma$ in the *setUp* phase (Step 2) — establishing $C_1$ ($M_{\tau[\theta]} \models C_1$). The call $\texttt{assertTrue}(\mathit{attacker}.\mathsf{exploitSucceeded}())$ forces $\mathsf{reentrancyCount} > 1$ and $\mathsf{invariantBroken}$ true, the runtime facts establishing $C_6$ (Step 3) and $C_3$ (Step 4). From $\texttt{assertTrue}(\mathsf{invariantBrokenAtBoundary})$ we get $\mathsf{invariantBrokenAtBoundary} = \mathsf{true}$, i.e. the invariant *re-evaluated at* $\sigma_b$ is false. Hence $\theta(h_{\mathcal{I}})(\sigma_b)$ is false: the consistency invariant $\mathcal{I}$ is violated at the transaction boundary $\sigma_b$, so $\neg\theta(h_{\mathcal{I}})(\sigma_b) \in \mathcal{P}_1$, establishing $C_8$ ($M_{\tau[\theta]} \models C_8$) directly as a trace fact. Because $\sigma_b$ is the transaction boundary — the state at which the consistency invariant is required to hold — this witness is faithful: a self-healing transient violation, repaired by $\theta(h_m)$'s late write before $m$ returns, would leave $\theta(h_{\mathcal{I}})(\sigma_b)$ true and the test would fail, so no spurious witness is produced. The $C_8$ check at $\sigma_b$ is thus independent of the $\sigma_i$ check establishing $C_3$ (Step 4). ✓

**Key observation.** A passing $\tt assertTrue$ (concretely in Forge, symbolically in Kontrol) is equivalent to the satisfaction of the corresponding *observed* FOL atom in $\mathcal{P}_1$ — an $\mathsf{Interm}$/$\mathsf{Exec}$/$\mathsf{Exploit}$ fact or an invariant literal $\mathcal{I}/\neg\mathcal{I}$; every conjunct $C_1$–$C_8$ is thus read directly off the trace. ✓

**Step 6 ([Template]): global assembly.** The [Template] rule at the root of the derivation tree is

$$\dfrac{\displaystyle \Phi \vdash H \qquad \Phi \vdash_{\mathit{setUp}} S \qquad \Phi \vdash_{\mathit{action}} A \qquad \Phi \vdash_{\mathit{callback}} \mathit{CB} \qquad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H, S, A, \mathit{CB}, \mathit{AS}\rangle} \quad \text{[Template]}$$

with $\Phi = \mathsf{Reentrant}(c)$. By Steps 1–5, each of the five premises is established and each of the eight conjuncts $C_1,\ldots,C_8$ is satisfied in $M_{\tau[\theta]}$, with every conjunct covered by exactly one phase (Phase–Conjunct Correspondence above). Since $\mathcal{W} = (\theta(h_m), m', \mathit{attacker}, v, \theta(h_{\mathcal{I}}), \theta(h_{\mathit{init}}), \sigma_i, \sigma'_f, \sigma_b)$ witnesses all eight existentials (with $m'$ statically extracted from $\theta(h_{\mathit{reenter}})$, $\mathit{attacker}$ realizing the external callee $c'$ of $C_4$, $v$ the concrete outer argument witnessing $x$, and $\sigma_i$, $\sigma'_f$, and the boundary $\sigma_b$ concretely extracted from the trace, Steps 4–5), all conjuncts hold simultaneously under $(\mathcal{P}_0, \mathcal{P}_1, \mathcal{W})$:

$$M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle \;\models\; \mathsf{Reentrant}(c). \qquad\square$$

**Scope.** The theorem does *not* claim that $\tau[\theta]$ is the unique defect model: other exploit scenarios may also satisfy $\mathsf{Reentrant}(c)$. It is also silent on completeness: if the LLM produces a $\theta$ for which some conjunct fails, the test fails and the theorem does not apply. The template is also structurally incomplete: reentrancy admits many variants — mediated by a $\tt fallback()$ entry point, by *cross-function* re-entry in which the re-entered method $m' \neq m$ does not itself re-open the callback window (so the $\mathsf{reentrancyCount} > 1$ threshold is never reached), or by re-entry patterns that do not route through a single $\tt receive()$ callback — that lie outside the scope of the derived template. We regard the current template as a baseline; the derivation methodology is designed to be extended with dedicated template variants targeting these patterns in future work.

 



