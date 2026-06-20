# Gas Costly Pattern — Complex Fallback

The $\tt receive()$ or $\tt fallback()$ functions in Solidity are special functions that handle plain Ether transfers sent to a contract without any data, or with empty calldata. The built-in functions $\tt send$ and $\tt transfer$ are used to transfer currency and have a strict gas limit of 2300 gas. When these are called on a contract address, either $\tt receive()$ or $\tt fallback()$ (if the former is not defined) is executed, and only 2300 gas is forwarded to it. If one of those two functions contains more complex functionality, the calls will always revert due to insufficient gas. Thus, the contract becomes unable to receive Ether via these standard functions.

## Specification Primitives

Our defect specifications rely on standard Solidity datatypes — $\mathsf{Contract}$, $\mathsf{Method}$, $\mathsf{Address}$, $\mathsf{Env}$(ironment), and $\mathsf{State}$. A brief description of the necessary predicates and functions over these types is included in the table below. The evaluation of these primitives is stratified: structural properties are derived statically via Slither, while behavioral properties are verified at runtime via Forge/Kontrol assertions within the LLM-generated test harness.

| Symbol | Semantics |
|--------|-----------|
| ***Datatypes*** | |
| $\mathsf{Path}$ | The sort of finite EVM execution paths through the contract. |
| $\mathsf{Paths}(m)$ | The set of execution paths of method $m$, with $\mathsf{Paths}(m) \subseteq \mathsf{Path}$. |
| $\mathsf{TransferPaths}(m)$ | The subset of $\mathsf{Paths}(m)$ reachable by a plain value transfer — a call carrying value with empty calldata from a cold state, exactly as $\tt transfer$/$\tt send$ issue — so $\mathsf{TransferPaths}(m) \subseteq \mathsf{Paths}(m)$. These are the only paths a standard value transfer can traverse, hence the only ones whose stipend exhaustion constitutes the targeted DoS. |
| ***Static Analysis (Slither)*** | |
| $\texttt{methods}(c)$ | The set of externally-callable functions (entry points) of contract *c*, which includes its public/external functions and the special $\tt receive$ and $\tt fallback$ functions. |
| $\mathsf{IsReceive}(m)$ | Holds if $m$ is the Solidity $\tt receive()$ function (which is necessarily $\tt payable$). |
| $\mathsf{IsFallback}(m)$ | Holds if $m$ is a *payable* Solidity $\tt fallback()$ function; a non-payable $\tt fallback$ rejects value transfers and is therefore off the $\tt transfer$/$\tt send$ path, outside this defect's scope. |
| ***Runtime Verification (Forge)*** | |
| $\mathsf{dGas}(\pi, \mathit{EIP\_2929})$ | The cumulative gas consumed along execution path $\pi \in \mathsf{Path}$ under the EIP-2929 cost schedule, which models the higher cost of cold storage access. This and the structural predicates $\mathsf{IsReceive}$/$\mathsf{IsFallback}$ are *exact* — a measured gas total and a syntactic callback-kind test, respectively — so, unlike the heuristic static predicates of the other defects, they carry no precision assumption. |

## Formal Specification

The Gas Costly Pattern is defined as the existence of a callback method (either $\tt receive()$ or $\tt fallback()$) whose execution along some path exceeds the 2300-stipend threshold:

$$\begin{aligned}
\mathsf{GasCostly}(c) \equiv {} & \exists m \in \{m' \in \mathsf{methods}(c) \mid \mathsf{IsReceive}(m') \lor \mathsf{IsFallback}(m')\}.\ \exists \pi \in \mathsf{TransferPaths}(m). \\
& \mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300
\end{aligned}$$

The specification is existentially quantified over both the callback method $m$ and an execution path $\pi \in \mathsf{TransferPaths}(m)$ of that method: the defect is flagged when some path *taken by a plain value transfer* exceeds the 2300-gas stipend of $\tt transfer$/$\tt send$ (under EIP-2929 Berlin costs, e.g. 2100 for a cold $\tt SLOAD$), so that a standard value transfer to the contract can fail. Restricting the binder to $\mathsf{TransferPaths}(m) \subseteq \mathsf{Paths}(m)$ (see the primitives table) rather than to all of $\mathsf{Paths}(m)$ is essential: an expensive path reachable only via non-empty calldata is *not* on the $\tt transfer$/$\tt send$ route and would be a spurious witness. This is also exactly the path the two-probe measurement exercises, so formula and witness coincide. A single such path suffices to expose the defect, which is exactly what the concrete Forge measurement witnesses. Note that $\mathsf{TransferPaths}(m)$ is non-empty for any payable $\tt receive$/$\tt fallback$ callback (a plain value transfer always traverses at least one path through $m$), so the binder $\exists\pi\in\mathsf{TransferPaths}(m)$ is not vacuously unsatisfiable; the defect question is genuinely whether some such path exceeds the stipend.

**Why $\exists\pi$ and not $\forall\pi$.** The existential is the intended strength, not an under-specification. The safety property a payable contract owes is that $\tt transfer$/$\tt send$ *always* succeed; its negation — the defect — is that *some* transfer-reachable path fails, i.e. $\exists\pi\in\mathsf{TransferPaths}(m).\,\mathsf{dGas}(\pi)>2300$. A single expensive path already makes the contract unsafe to receive value, since the sender cannot choose the path. A universal $\forall\pi.\,\mathsf{dGas}(\pi)>2300$ would instead demand that *every* transfer path be expensive, wrongly exonerating a contract that fails only on some paths — precisely the intermittent-DoS case that matters most. The cost is a completeness boundary, not an unsoundness: the two-probe measurement exercises the path determined by the cold initial state $h_{\mathit{init}}$, so it constructively witnesses $\exists\pi$ for *that* path; an expensive path reachable only under a different state the probe does not set up may be missed (a false negative), but no non-defective contract is flagged, since a measured $\mathsf{dGas}(\pi)>2300$ exhibits a genuine failing transfer path.

The binding domain is restricted to *custom* $\tt receive()$/$\tt fallback()$ callbacks for a principled reason rather than as an additional conjunct: defining such a callback is a deliberate, opt-in design choice the author makes precisely to react to incoming value transfers, and reacting to Ether transfers is a fundamental function of a payable contract. A developer-defined callback on the $\tt transfer$/$\tt send$ path is therefore essential by construction, so its stipend-DoS failure renders the contract unable to perform a basic, intended operation. We thus fold essentiality into the quantifier's domain — every $m$ it ranges over is essential by definition — rather than carrying it as a separate $\mathsf{IsEssential}(m)$ conjunct: here the syntactic domain ($\tt receive$/$\tt fallback$) already *entails* essentiality, so no semantic predicate is needed, in contrast to Assert/Require/Revert Violation, where essentiality is not implied by the method's signature and is carried explicitly as the static $\mathsf{IsEssential}(m)$ conjunct.

## Specific Test Template Design

**Testing Goal** — Measure if the minimum execution path for mandatory callbacks (a receive or fallback callback) exceeds the 2300 gas stipend when storage is cold.

**Setup** — The LLM initializes a fresh test environment where no previous calls have been made to the contract, ensuring all state variables are cold so that storage reads and writes incur their maximum gas cost.

**Measurement** — The template directs the LLM to identify paths where the callback reads multiple state variables, since each cold storage read consumes 2100 gas, rapidly exhausting the stipend.

**Action** — The harness reproduces exactly what a plain value transfer does, with two value-bearing probes against cold instances: a *stipend-bounded* probe that forwards exactly the 2300-gas stipend, and an *unbounded* probe on a freshly redeployed instance that runs the callback to completion.

**Assertion** — The framework checks that the unbounded probe succeeds while the stipend-bounded probe reverts; this holds iff the callback's path cost exceeds the 2300 stipend ($\mathsf{dGas} > 2300$), identifying a contract that will revert during standard $\tt transfer$/$\tt send$ calls, effectively locking incoming Ether. The unbounded probe's success rules out non-gas failures (e.g., a contract that cannot receive Ether).

## Template Derivation and LLM Instantiation

The conceptual test design is materialized into a standardized Foundry test template (e.g., $\tt ComplexFallback.t.sol$). To bridge the gap between static analysis and generation, the template embeds explicit $\tt [LLM\_INSTRUCTION]$ comments alongside structural markers for the Setup, Measurement, Action, and Assertion phases.

Each hole is assigned to either Slither or the LLM for resolution, as summarized in the table below. The method $m$ and the execution path $\pi \in \mathsf{TransferPaths}(m)$ are the specification's only existential witnesses; the remaining holes ($h_{\mathit{sender}}$, $h_{\mathit{amt}}$, $h_{\mathit{init}}$) are execution-context holes the harness instantiates to perform the measurement:

| Spec witness | Hole | Sort | Resolved by |
|---|---|---|---|
| $\exists m \in \{m' \mid \mathsf{IsReceive}(m') \lor \mathsf{IsFallback}(m')\}$ | $h_m$ | $\mathsf{CallbackMethod}$ | Slither |
| $\exists \pi$ (execution path) | witnessed by the measured run | | Forge |
| sender address | $h_{\mathit{sender}}$ | $\mathsf{Address}$ | LLM ($\tt makeAddr$) |
| ETH amount (fuzzed) | $h_{\mathit{amt}}$ | $\mathsf{FuzzValue}$ | LLM |
| initial (cold) state | $h_{\mathit{init}}$ | $\mathsf{State}$ | LLM |

The execution path $\pi$ carries no explicit hole: its *existence* is witnessed at runtime by the gas measurement of the concrete call, making it an implicit existential that is *verified* rather than *filled*.

Before stating the derivation rules, we record how each conjunct of $\mathsf{GasCostly}(c)$ maps to exactly one test phase and its concrete template realization:

| Spec element | Phase | Template realization |
|---|---|---|
| cold state (max SLOAD cost) | *setUp* | fresh $h_{\mathit{init}}$; no prior calls |
| sender funding (EOA) | *setUp* | $h_{\mathit{sender}} = \tt makeAddr("sender")$; $\tt vm.deal(sender,\ h_{\mathit{amt}} \cdot 2)$; $\tt vm.assume(h_{\mathit{amt}} \geq 0.01\ ether)$ |
| $\mathsf{dGas}(\pi, \mathit{EIP\_2929})$ probes | *action* | $\tt okStipend = .call\{value:h_{\mathit{amt}},gas:0\}("");$ redeploy fresh victim; $\tt okUnbounded = .call\{value:h_{\mathit{amt}}\}("")$ |
| $\mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300$ | *assert* | $\tt assertTrue(okUnbounded \&\& !okStipend)$ |

The single conjunct $\mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300$ is realized across two phases by a *two-probe* test that reproduces exactly what $\tt transfer$/$\tt send$ do. The *action* phase issues two value-bearing calls to the callback: a *stipend-bounded* probe $\tt call\{value:h_{\mathit{amt}},gas:0\}$ and an *unbounded* probe $\tt call\{value:h_{\mathit{amt}}\}$. Because $h_{\mathit{amt}} > 0$, the EVM adds exactly the $\mathit{Gcallstipend} = 2300$ gas to the bounded probe, so the callee receives precisely the 2300 stipend; each probe runs against a freshly redeployed instance, giving both identical cold state. The two probes therefore issue the *same* call (value-bearing, empty calldata) from the *same* state, and since EVM execution is deterministic they traverse the *same* path $\pi$, differing only in the gas made available. The *assert* phase checks $\tt okUnbounded \&\& !okStipend$, which is the materialization of the conjunct in the direction soundness needs: if the unbounded call succeeds while the 2300-bounded call reverts, then the callback's path cost along $\pi$ exceeds the stipend, i.e. $\tt okUnbounded \&\& !okStipend \Rightarrow \mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300$. The converse holds only up to the unbounded probe's $63/64$ budget (a path exhausting even that fails both probes — a completeness-only false negative, never a false positive). The unbounded probe's success rules out non-gas failures (a contract that cannot receive ether, or a callback reverting for logic reasons), so a passing test is a sound witness rather than the vacuous caller-side gas delta. Forge is the natural tool (not Kontrol) since the probes require concrete execution.

## Derivation Rules for $\vdash$

This section gives a rigorous definition of the relation $\Phi(c) \vdash \tau$, read "defect specification $\Phi$ derives template schema $\tau$". We develop it through the Gas Costly Pattern running example.

The relation $\Phi(c) \vdash \tau$ is defined by the following five rules.

Witnesses become typed holes:

$$\dfrac{}{\displaystyle \Phi \vdash \bigl\{ h_m : \mathsf{CallbackMethod},\; h_{\mathit{sender}} : \mathsf{Address},\; h_{\mathit{amt}} : \mathsf{FuzzValue},\; h_{\mathit{init}} : \mathsf{State} \bigr\}} \quad \text{[Holes]}$$

The callback-domain witness and cold storage requirement derive the *setUp* phase:

$$\dfrac{\displaystyle m \in \{m' \in \mathsf{methods}(c) \mid \mathsf{IsReceive}(m') \lor \mathsf{IsFallback}(m')\}\ \text{existential witness of}\ \Phi}{\displaystyle \Phi \vdash_{\mathit{setUp}} \left[\begin{array}{l} h_{\mathit{init}};\; h_{\mathit{sender}} = \texttt{makeAddr}(\text{"sender"});\; \\ \texttt{vm.deal}(h_{\mathit{sender}},\, h_{\mathit{amt}} \cdot 2);\; \texttt{vm.assume}(h_{\mathit{amt}} \geq 0.01\ \mathsf{ether}) \end{array}\right]} \quad \text{[Pre]}$$

The gas-probe conjunct derives the *action* phase (two value-bearing probes on cold instances):

$$\dfrac{\displaystyle \mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300 \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{action}} \left[\begin{array}{l} \texttt{vm.prank}(h_{\mathit{sender}});\; \texttt{okStipend} = \texttt{address(victim).call\{value:}h_{\mathit{amt}}\texttt{,gas:0\}("")};\; \\ \text{redeploy fresh } \textit{victim}' \text{ via setUp};\; \texttt{vm.prank}(h_{\mathit{sender}});\; \\ \texttt{okUnbounded} = \texttt{address(}\textit{victim}'\texttt{).call\{value:}h_{\mathit{amt}}\texttt{\}("")} \end{array}\right]} \quad \text{[Act]}$$

The threshold conjunct derives the *assert* phase:

$$\dfrac{\displaystyle \mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300 \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{assert}} \bigl[\,\texttt{assertTrue}(\texttt{okUnbounded \&\& !okStipend})\,\bigr]} \quad \text{[Assrt]}$$

All phases combine into the full schema:

$$\dfrac{\displaystyle \Phi \vdash H \qquad \Phi \vdash_{\mathit{setUp}} S \qquad \Phi \vdash_{\mathit{action}} A \qquad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H,\, S,\, A,\, \mathit{AS} \rangle} \quad \text{[Template]}$$

## Derived Gas-Costly Multi-Shot Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The solidity files are in "../src/". The name of the file is the same as the name of the contract.
// [LLM_INSTRUCTION]: If you need to manipulate private state directly, import StdStorage:
// import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

// ------------------------------
// [Testing Goal] Measure if the minimum execution path for mandatory callbacks
// (such as receive() or fallback()) exceeds the 2,300 gas stipend when storage is cold.
// ------------------------------

// [LLM_INSTRUCTION]: Name the contract 'TestComplexFallback[ContractName]'
contract TestComplexFallbackTemplate is Test {
    // [LLM_INSTRUCTION]: Use StdStorage if needed for complex state setup:
    // using stdStorage for StdStorage;

    // ------------------------------
    // [Setup] Declare the contract under test variable.
    // ------------------------------

    // [LLM_INSTRUCTION]: Declare the contract under test variable
    // ComplexFallback public _contractUnderTest;

    // ------------------------------ [/Setup]

    function setUp() public {
        // ------------------------------
        // [Setup] Initialize a fresh test environment where no previous calls
        // have been made to the contract, ensuring all state variables are in
        // a cold state (maximizing SLOAD/SSTORE gas costs).
        // ------------------------------

        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // 1. If constructor parameters are needed, use concrete valid values.
        // 2. If payable, use vm.deal(address(this), amount) before deployment.

        // _contractUnderTest = new ComplexFallback();

        // ------------------------------ [/Setup]
    }

    // [LLM_INSTRUCTION]: Add Fuzz/Symbolic arguments.
    // 'amount': The value transferred to trigger the fallback.
    // 'stateVal': Any value needed to configure the state (optional).
    // Example: function test_highlightGasNeededIsOver2300(uint256 amount) public {
    function test_highlightGasNeededIsOver2300(uint256 amount) public {

        // ------------------------------
        // [Setup] Constrain fuzz/symbolic values and configure pre-conditions.
        // ------------------------------

        // [LLM_INSTRUCTION]: Constrain the Fuzz/Symbolic values.
        // WARNING: Avoid Integer/Balance Overflow.
        vm.assume(amount >= 0.01 ether && amount <= type(uint128).max);

        // [LLM_INSTRUCTION]: FUNDING
        // A. Create and Fund a dedicated Sender address
        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        // B. Fund the Test Contract (Safety Net)
        // Even though we use 'sender', ensuring address(this) has funds prevents
        // unexpected failures if the LLM adds logic using address(this).
        vm.deal(address(this), amount * 2);

        // ------------------------------ [/Setup]

        // ------------------------------
        // [Measurement] Identify paths where the fallback reads multiple state
        // variables. Each cold SLOAD consumes 2,100 gas, rapidly exhausting
        // the 2,300 stipend.
        // ------------------------------

        // [LLM_INSTRUCTION]: STATE VARIABLES
        // Does the fallback logic depend on specific state to be expensive?
        // (e.g. executing a loop only when isProcessing is true).

        // STRATEGY A: Public Methods (Preferred)
        // Call public setters.
        // Example: _contractUnderTest.setExpensiveMode(true);

        // STRATEGY B: Storage Manipulation
        // Example: stdstore.target(address(_contractUnderTest)).sig("config()").checked_write(1);

        // ------------------------------ [/Measurement]

        // ------------------------------
        // [Action] Two-probe measurement reproducing exactly what transfer()/send()
        // do. Issue two value-bearing low-level calls to the callback, each against
        // a freshly redeployed (cold) victim: a stipend-bounded probe (gas: 0, so the
        // EVM adds exactly the 2,300 stipend because amount > 0) and an unbounded probe.
        // ------------------------------

        // Probe 1: stipend-bounded call. Because amount > 0, the EVM adds exactly the
        // 2,300 stipend, so the callee receives precisely 2,300 gas.
        vm.prank(sender);
        (bool okStipend, ) = address(_contractUnderTest).call{value: amount, gas: 0}("");

        // [LLM_INSTRUCTION]: Redeploy a FRESH victim so Probe 2 runs against identical
        // cold state. Re-run the same initialization used in setUp (constructor args,
        // expensive-mode setters, vm.deal if payable).
        // _contractUnderTest = new ComplexFallback();

        // Probe 2: unbounded call (its success rules out non-gas failures).
        vm.prank(sender);
        (bool okUnbounded, ) = address(_contractUnderTest).call{value: amount}("");

        // ------------------------------ [/Action]

        // ------------------------------
        // [Assertion] The unbounded call succeeds while the 2,300-bounded call reverts
        // iff the callback's path cost exceeds the stipend (dGas > 2300). The unbounded
        // probe's success rules out non-gas failures (a contract that cannot receive
        // Ether or a callback that reverts for logic reasons), so a passing test is a
        // sound witness that standard transfer()/send() calls will revert, locking Ether.
        // ------------------------------

        assertTrue(okUnbounded && !okStipend, "Callback fits within the 2300 stipend: not gas-locked");

        // ------------------------------ [/Assertion]
    }
}
```

### Rule Application

The derivation $\mathsf{GasCostly}(c) \vdash \tau$ proceeds by applying the five rules in sequence. For each step we identify the triggering conjunct(s) from $\mathsf{GasCostly}(c)$, state what the rule derives, and map the output to the specific region of the code template above.

---

**Step 1 — [Holes]** (no premise)

The axiom fires unconditionally and establishes the hole signature:

$$H = \bigl\{\, h_m : \mathsf{CallbackMethod},\quad h_{\mathit{sender}} : \mathsf{Address},\quad h_{\mathit{amt}} : \mathsf{FuzzValue},\quad h_{\mathit{init}} : \mathsf{State} \,\bigr\}$$

Each hole appears in the template as a $\tt [LLM\_INSTRUCTION]$ placeholder:

| Hole | Sort | Stands for | Filled by |
|---|---|---|---|
| $h_m$ | $\mathsf{CallbackMethod}$ | the $\tt receive()$ or $\tt fallback()$ method to measure | Slither |
| $h_{\mathit{sender}}$ | $\mathsf{Address}$ | the address that sends Ether to trigger the callback | LLM (via $\tt makeAddr("sender")$) |
| $h_{\mathit{amt}}$ | $\mathsf{FuzzValue}$ | the fuzzed ETH amount sent to trigger the fallback | LLM (fuzz argument $\tt amount$) |
| $h_{\mathit{init}}$ | $\mathsf{State}$ | the state-initializing statements in $\tt setUp()$ | LLM (e.g., $\tt \_contractUnderTest = new\ ComplexFallback()$) |

---

**Step 2 — [Pre]** fires on the callback-domain witness $m$

Triggering witness: $m \in \{m' \in \mathsf{methods}(c) \mid \mathsf{IsReceive}(m') \lor \mathsf{IsFallback}(m')\}$ — the existential ranges only over custom $\tt receive()$/$\tt fallback()$ callbacks, which are essential by construction (a developer defines them precisely to react to incoming transfers), so essentiality is folded into the binding domain rather than carried as a separate conjunct.

Derives:
$$\Phi \vdash_{\mathit{setUp}} \bigl[\, h_{\mathit{init}};\; h_{\mathit{sender}} = \texttt{makeAddr}(\text{"sender"});\; \texttt{vm.deal}(h_{\mathit{sender}},\, h_{\mathit{amt}} \cdot 2);\; \texttt{vm.assume}(h_{\mathit{amt}} \geq 0.01\ \mathsf{ether}) \,\bigr]$$

Template realization — the $\tt [Setup]$ regions cover two locations:

- In $\tt setUp()$: the $\tt [LLM\_INSTRUCTION]$ for $h_{\mathit{init}}$ instantiates the victim with a fresh deployment ($\tt \_contractUnderTest = new\ ComplexFallback()$). Crucially, no prior calls are made, ensuring all storage slots are in cold state and that $\tt SLOAD$ operations will incur the maximum 2100-gas EIP-2929 cost.
- In $\tt test\_highlightGasNeededIsOver2300()$: $\tt vm.assume(amount > 0.01\ ether\ \&\&\ amount < type(uint128).max)$ constrains $h_{\mathit{amt}}$ to a safe range; $\tt makeAddr("sender")$ instantiates $h_{\mathit{sender}}$; and $\tt vm.deal(sender,\ amount * 2)$ funds the sender so it can forward $h_{\mathit{amt}}$ to the victim.

The callback-domain restriction is discharged **statically** by Slither, which identifies the $\tt receive()$/$\tt fallback()$ callbacks; essentiality follows by construction from membership in this domain, so no separate $\mathsf{IsEssential}$ predicate or hole is needed.

---

**Step 3 — [Act]** fires on $C_1 = \mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300$

Triggering conjunct: the gas measurement conjunct $\mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300 \in \mathrm{conjuncts}(\mathsf{GasCostly}(c))$ — there exists an execution path through the callback whose cumulative gas cost under EIP-2929 rules exceeds 2300.

Derives:
$$\Phi \vdash_{\mathit{action}} \bigl[\, \texttt{vm.prank}(h_{\mathit{sender}});\; \texttt{okStipend} = \texttt{address(victim).call\{value:}h_{\mathit{amt}}\texttt{,gas:0\}("")};\; \text{redeploy fresh } \textit{victim}';\; \texttt{vm.prank}(h_{\mathit{sender}});\; \texttt{okUnbounded} = \texttt{address(}\textit{victim}'\texttt{).call\{value:}h_{\mathit{amt}}\texttt{\}("")} \,\bigr]$$

Template realization — the $\tt [Action]$ region in $\tt test\_highlightGasNeededIsOver2300()$:

```solidity
// Probe 1 - stipend-bounded (gas: 0 -> EVM adds exactly the 2300 stipend)
vm.prank(sender);
(bool okStipend, ) = address(_contractUnderTest).call{value: amount, gas: 0}("");

// Deploy a fresh, cold instance identical to setUp for Probe 2
ComplexFallback freshInstance = new ComplexFallback();

// Probe 2 - unbounded (forward all gas)
vm.prank(sender);
(bool okUnbounded, ) = address(freshInstance).call{value: amount}("");
```

The low-level $\tt .call\{value:\ amount\}("")$ (with empty calldata) routes to $\tt receive()$ if defined, or to $\tt fallback()$ otherwise — precisely the set identified by Slither as satisfying $\mathsf{IsReceive}(h_m) \lor \mathsf{IsFallback}(h_m)$. Because each probe targets a freshly deployed instance without any prior storage reads, all $\tt SLOAD$ operations in the callback incur the cold-access cost of 2100 gas (EIP-2929), maximizing $\mathsf{dGas}(\pi, \mathit{EIP\_2929})$. Since $\tt amount > 0$, the EVM adds exactly the 2300 stipend to Probe 1, so $\tt okStipend$ records whether the callback completes within the stipend, while $\tt okUnbounded$ records whether it completes with ample gas.

The $\tt [Measurement]$ block (between Setup and Action) further guides the LLM to force the contract into its most expensive execution mode — for example, by calling a public setter to enable a state-dependent code path — so that the witnessed path $\pi$ is the one most likely to exhaust the stipend.

---

**Step 4 — [Assrt]** fires on $C_1$ (threshold side)

Triggering conjunct: the same gas conjunct $\mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300 \in \mathrm{conjuncts}(\mathsf{GasCostly}(c))$ now drives the threshold check.

Derives:
$$\Phi \vdash_{\mathit{assert}} \bigl[\, \texttt{assertTrue}(\texttt{okUnbounded \&\& !okStipend}) \,\bigr]$$

Template realization — the $\tt [Assertion]$ region:

```solidity
// dGas(pi) > 2300  <=>  unbounded call succeeds AND stipend-bounded call reverts
assertTrue(okUnbounded && !okStipend, "Callback fits within the 2300 stipend: not gas-locked");
```

A passing $\tt assertTrue$ means the unbounded call succeeded while the 2300-bounded call reverted, which holds iff the concrete execution of $h_m$ along the witnessed path $\pi$ consumed more than 2300 gas under EIP-2929 pricing. This is the runtime discharge of the existential $\exists \pi.\ \mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300$: Forge has found a concrete $\pi$ satisfying the bound. The unbounded probe's success rules out non-gas failures (e.g., a contract that cannot receive Ether). Because $\tt transfer()$ and $\tt send()$ forward exactly 2300 gas, any callback consuming more than 2300 gas will cause those calls to revert, confirming the defect.

Note that the single formal conjunct $\mathsf{dGas}(\pi, \mathit{EIP\_2929}) > 2300$ is realized across **two** phases: [Act] issues the two probes (stipend-bounded and unbounded) on cold instances, and [Assrt] applies the witness test $\tt okUnbounded\ \&\&\ !okStipend$. This split is intentional — probing and validation are distinct concerns — and explains why both rules share the same triggering conjunct.

---

**Step 5 — [Template]** assembles all four sub-derivations

All premises of [Template] are now established:

| Premise | Established in |
|---|---|
| $\Phi \vdash H$ | Step 1 |
| $\Phi \vdash_{\mathit{setUp}} S$ | Step 2 |
| $\Phi \vdash_{\mathit{action}} A$ | Step 3 |
| $\Phi \vdash_{\mathit{assert}} AS$ | Step 4 |

Applying [Template] yields $\mathsf{GasCostly}(c) \vdash \langle H, S, A, AS \rangle = \tau$, which is exactly the code template above with four open holes for the LLM to fill. The conjuncts of $\mathsf{GasCostly}(c)$ are in correspondence with the phases of $\tau$ as recorded in the Phase–Conjunct table above, completing the derivation. The absence of a separate callback phase (present in the Reentrancy derivation) reflects the architectural difference between the two defects: Gas Costly Pattern has no attacker contract or re-entrant loop — the victim's own $\tt receive()$/$\tt fallback()$ is the sole unit under measurement.

## Soundness of $\vdash$ for $\mathsf{GasCostly}(c)$

**Theorem (Soundness of $\vdash$ for $\mathsf{GasCostly}(c)$).** Let $\mathsf{GasCostly}(c) \vdash \tau$ be derivable by the rules above, let $\tau[\theta]$ be a ground instance of $\tau$ obtained by resolving all holes in $H$ (Slither for $h_m$, the LLM for $h_{\mathit{sender}}$, $h_{\mathit{amt}}$, and $h_{\mathit{init}}$), and let $M_{\tau[\theta]}$ be the model induced by the EVM execution trace produced by running $\tau[\theta]$ in Forge. Assume $\tau[\theta]$ is *non-vacuous*: the *setUp* constraints together with the $\texttt{vm.assume}(h_{\mathit{amt}} \geq 0.01\,\texttt{ether})$ bound are jointly satisfiable, so that $M_{\tau[\theta]}$ is a genuine, funded, value-bearing run reaching the callback (and, since $\mathsf{TransferPaths}(m)$ is non-empty for any payable $\tt receive$/$\tt fallback$, the run exercises at least one transfer path). Assume further that the callback is *deploy-invariant*: its executed path is independent of the contract's deployment address (and of the deployer nonce), so the two freshly deployed instances $\mathit{victim}$ and $\mathit{victim}'$ are observationally equivalent on the transfer path. This holds for any callback whose control flow is driven by storage, calldata, value, or caller rather than by $\tt address(this)$ — i.e. every contract whose stipend cost arises from $\tt SLOAD$s, loops, or external calls. Then

$$\tau[\theta] \text{ passes in Forge (i.e., } \texttt{assertTrue}(\mathsf{okUnbounded}\,\&\&\,!\mathsf{okStipend}) \text{ holds)} \;\Longrightarrow\; M_{\tau[\theta]} \models \mathsf{GasCostly}(c).$$

That is, a passing two-probe test induces an execution trace $M_{\tau[\theta]}$ that is a model of, hence a *constructive witness* for, the existential statement $\mathsf{GasCostly}(c)$. Here $\models$ interprets the specification's atoms on $\mathcal{P}_0/\mathcal{P}_1$ in the usual way: the static callback-kind facts are read off $\mathcal{P}_0 = \mathrm{Slither}(c)$ and the gas measurement off the Forge trace $\mathcal{P}_1$.

**Setup.** Recall the gas-costly specification, with its single matrix conjunct labelled:

$$\begin{aligned}
\mathsf{GasCostly}(c) \equiv{} &
  \exists m \in \{m' \in \mathsf{methods}(c) \mid \mathsf{IsReceive}(m') \lor \mathsf{IsFallback}(m')\}.\;
  \exists \pi \in \mathsf{TransferPaths}(m).\\
  &\underbrace{\mathsf{dGas}(\pi,\mathit{EIP\_2929}) > 2300}_{C_1}
\end{aligned}$$

The derivation $\mathsf{GasCostly}(c) \vdash \tau$ is a flat tree whose leaves are the phase judgements [Holes], [Pre], [Act], and [Assrt], and whose root is [Template]. By inversion on the derivation rules, we show that the conjunct $C_1$ is satisfied — and the two existentials $m,\pi$ witnessed — in the test-induced model $M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle$, where $\mathcal{S}$ is the underlying many-sorted domain (EVM states, methods, execution paths, etc.), $\mathcal{P}_0 = \mathrm{Slither}(c)$ (supplying $\mathsf{IsReceive}/\mathsf{IsFallback}$), $\mathcal{P}_1$ is extracted from the Forge trace (the two-probe gas measurement), and the witness tuple is $\mathcal{W} = (\theta(h_m),\, \pi)$, where $\theta(h_m) = m$ is the chosen callback method and $\pi \in \mathsf{TransferPaths}(m)$ is the path the *unbounded* probe runs to completion, read off $\mathcal{P}_1$ (Step 3). The remaining holes $h_{\mathit{sender}}, h_{\mathit{amt}}, h_{\mathit{init}}$ are execution-context holes, not spec witnesses, so $\mathcal{W}$ collects exactly the two existentials $m$ and $\pi$ bound by the prefix.

**Step 1 ([Holes]): witnesses are well-typed.** The [Holes] rule establishes the hole signature

$$H = \bigl\{ h_m : \mathsf{CallbackMethod},\; h_{\mathit{sender}} : \mathsf{Address},\; h_{\mathit{amt}} : \mathsf{FuzzValue},\; h_{\mathit{init}} : \mathsf{State} \bigr\}$$

with $\mathit{res}(h_m) = \mathsf{Slither}$ and $\mathit{res}(h_{\mathit{sender}}) = \mathit{res}(h_{\mathit{amt}}) = \mathit{res}(h_{\mathit{init}}) = \mathsf{LLM}$. By assumption, $\theta(h_m) \in \{m' \in \mathsf{methods}(c) \mid \mathsf{IsReceive}(m') \lor \mathsf{IsFallback}(m')\}$ per Slither's output, so $\theta(h_m)$ is a valid existential witness for $m$ in the restricted domain; and $\theta(h_{\mathit{sender}}), \theta(h_{\mathit{amt}}), \theta(h_{\mathit{init}})$ are syntactically valid Solidity, so $\tau[\theta]$ is a type-correct Forge test. The path $\pi$ carries no hole; it is witnessed at runtime by the unbounded probe's completing run (Step 3).

**Lemma (Hole Typing).** If $\vdash H : \tau$ and $\tau[\theta]$ does not revert on a type error, then $m = \theta(h_m)$ is a valid witness candidate for $\exists m$ in the existential prefix of $\mathsf{GasCostly}(c)$; the companion path witness $\pi$ is a runtime object discharged in Step 3. ✓

**Step 2 ([Pre]): domain membership discharged, cold state established.** The [Pre] rule fires because $m \in \{m' \in \mathsf{methods}(c) \mid \mathsf{IsReceive}(m') \lor \mathsf{IsFallback}(m')\}$ is the existential witness of $\Phi$, and derives the $\tt setUp$ phase

$$h_{\mathit{init}};\; h_{\mathit{sender}} {=} \texttt{makeAddr("sender")};\; \texttt{vm.deal}(h_{\mathit{sender}}, h_{\mathit{amt}}{\cdot}2);\; \texttt{vm.assume}(h_{\mathit{amt}} \geq 0.01\,\texttt{ether}).$$

When the test runs, *setUp* deploys a fresh victim in a *cold* state (no prior calls, maximizing $\tt SLOAD$ cost under EIP-2929), funds $h_{\mathit{sender}}$, and bounds $h_{\mathit{amt}} > 0$. The domain restriction $\mathsf{IsReceive}(m) \lor \mathsf{IsFallback}(m)$ is a *static* ($\mathcal{P}_0$) fact discharged by Slither at $h_m$ selection: $\theta(h_m)$ is a $\tt receive()$ or payable $\tt fallback()$ callback, so it lies in the quantifier's domain, recorded in $\mathcal{P}_0$. Because this domain is syntactic and *exact* (a callback-kind test), the membership carries *no* precision premise. Two independent facts hold of this phase. First, by the essentiality-by-construction argument, $m$ is an essential callback, so its stipend-DoS failure denies the contract a basic, intended operation. Second — and separately — the cold $h_{\mathit{init}}$ makes the measured run traverse the maximal-cost route a real $\tt transfer$/$\tt send$ would hit. We stress that this cold setup is a *detection-power/fidelity* device, not a premise of the soundness direction: a warm-state run measuring $\mathsf{dGas}(\pi,\mathit{EIP\_2929}) > 2300$ is still a true positive, since a warm path is cheaper than its cold counterpart, so a warm failure entails a cold one, and the first real transfer to a fresh contract is itself cold. Cold $h_{\mathit{init}}$ thus bears on completeness (how many genuine defects are caught), never on the absence of false positives. ✓

**Step 3 ([Act]): the two-probe measurement witnesses $\pi$.** The [Act] rule fires because $\mathsf{dGas}(\pi,\mathit{EIP\_2929}) > 2300 \in \mathrm{conjuncts}(\mathsf{GasCostly}(c))$ and derives the $\tt action$ phase: a *stipend-bounded* probe $\mathsf{okStipend} = \texttt{address(victim).call\{value:}h_{\mathit{amt}}\texttt{,gas:0\}("")}$, a redeployment of a fresh $victim'$ via *setUp*, and an *unbounded* probe $\mathsf{okUnbounded} = \texttt{address(}\mathit{victim}'\texttt{).call\{value:}h_{\mathit{amt}}\texttt{\}("")}$, each preceded by $\texttt{vm.prank}(h_{\mathit{sender}})$. When $\tau[\theta]$ runs, each probe issues a value-bearing call with empty calldata from $h_{\mathit{sender}}$ against a freshly redeployed cold victim — exactly what $\tt transfer$/$\tt send$ do. Because each probe carries empty calldata and value, the EVM dispatches it to the callback a plain $\tt transfer$/$\tt send$ would reach — $\tt receive()$ if present, otherwise the payable $\tt fallback()$ — which is exactly Slither's resolution rule for $h_m$, so the dispatched callback is $\theta(h_m) = m$ and the traversed path lies in $\mathsf{TransferPaths}(m)$. Because $h_{\mathit{amt}} > 0$, the EVM adds precisely the $\mathit{Gcallstipend} = 2300$ gas to the bounded probe, so the callee receives exactly the $2300$ stipend, whereas the unbounded probe forwards the available $63/64$ gas. Both probes issue the *same* call from the *same* cold state; since EVM execution is deterministic and the callback is deploy-invariant (so the redeployed $\mathit{victim}'$ is observationally equivalent to $\mathit{victim}$ on the transfer path, the address change notwithstanding), they traverse the *same* path $\pi \in \mathsf{TransferPaths}(m)$, differing only in the gas made available. The unbounded probe runs the callback to completion along $\pi$, concretely witnessing the existential $\exists \pi \in \mathsf{TransferPaths}(m)$: $\pi$ is realized on the trace, i.e. $\pi \in \mathcal{P}_1$. ✓

**Step 4 ([Assrt]): conjunct $C_1$ satisfied.** The [Assrt] rule fires because $\mathsf{dGas}(\pi,\mathit{EIP\_2929}) > 2300 \in \mathrm{conjuncts}(\mathsf{GasCostly}(c))$ and derives the $\tt assert$ phase $[\,\texttt{assertTrue}(\mathsf{okUnbounded} \;\texttt{\&\&}\; \texttt{!}\,\mathsf{okStipend})\,]$. The defect-indicating outcome — the test passing — occurs *iff* $\mathsf{okUnbounded} \wedge \neg\,\mathsf{okStipend}$. When it holds: the unbounded probe succeeded ($\mathsf{okUnbounded}$), so the callback can receive ether and does not revert for logic reasons along $\pi$ — ruling out non-gas failures and confirming $\pi$ is a genuine completing transfer path; and the stipend-bounded probe reverted ($\neg\,\mathsf{okStipend}$), so the callback's cost along $\pi$ exceeds the $2300$ gas it was given. Since both probes traverse the same $\pi$ (Step 3), the only difference is the gas budget, so the bounded probe's failure is attributable to gas alone: $\mathsf{dGas}(\pi,\mathit{EIP\_2929}) > 2300$, which establishes $C_1$ ($M_{\tau[\theta]} \models C_1$). Formally this is the sound direction $\mathsf{okUnbounded} \wedge \neg\,\mathsf{okStipend} \Rightarrow \mathsf{dGas}(\pi,\mathit{EIP\_2929}) > 2300$; its converse can fail only when a path so expensive that it exhausts even the unbounded probe's $63/64$ budget makes *both* probes fail — a completeness-only false negative, never a false positive. ✓

**Key observation.** A passing two-probe test (concretely in Forge) is equivalent to the satisfaction of the observed atom $\mathsf{dGas}(\pi,\mathit{EIP\_2929}) > 2300$ in $\mathcal{P}_1$ on the path $\pi$ witnessed by the unbounded probe. Because $\mathsf{dGas}$ and $\mathsf{IsReceive}/\mathsf{IsFallback}$ are *exact* — a measured gas total and a syntactic callback-kind test — the conjunct is read off the run with *no* static-precision premise: the Gas Costly Pattern is the sole defect with an empty static trusted base. ✓

**Step 5 ([Template]): global assembly.** The [Template] rule at the root of the derivation tree is

$$\dfrac{\displaystyle \Phi \vdash H \quad \Phi \vdash_{\mathit{setUp}} S \quad \Phi \vdash_{\mathit{action}} A \quad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H, S, A, \mathit{AS}\rangle} \quad \text{[Template]}$$

with $\Phi = \mathsf{GasCostly}(c)$. By Steps 1–4, each of the four premises is established, the single conjunct $C_1$ holds in $M_{\tau[\theta]}$, the domain membership is discharged in *setUp*, and $C_1$ is witnessed across *action* and *assert*. Since $\mathcal{W} = (\theta(h_m), \pi)$ witnesses both existentials — $\theta(h_m) = m$ the $\tt receive$/$\tt fallback$ callback selected by Slither and $\pi$ the transfer path the unbounded probe runs to completion, extracted from the trace — the conjunct holds under $(\mathcal{P}_0, \mathcal{P}_1, \mathcal{W})$:

$$M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle \;\models\; \mathsf{GasCostly}(c). \qquad\square$$

**Scope.** The theorem does *not* claim that $\pi$ is the unique expensive path, nor that every transfer path is expensive: the specification is existential ($\exists\pi$), so a single witnessing path suffices. It is silent on completeness: an expensive path reachable only under a warm or otherwise-configured state that the cold $h_{\mathit{init}}$ does not set up is a false negative, as is a path so costly that even the unbounded probe's $63/64$ budget is exhausted (both probes fail and the assertion is false). Soundness carries *no* static-precision premise — $\mathsf{dGas}$ and the callback-kind tests are exact — so, unlike the other defects, the Gas Costly Pattern has an empty static trusted base and no false-positive channel from static imprecision. The standing premises are instead two runtime-measurement conditions: non-vacuity (a genuine, funded, value-bearing run reaching the callback) and callback deploy-invariance (the executed path is independent of the deployment address, so the redeployed $\mathit{victim}'$ is observationally equivalent to $\mathit{victim}$); the latter rules out the sole residual false-positive channel, an $\tt address(this)$-dependent revert that the unbounded probe, running on a different address, would otherwise fail to rule out.
