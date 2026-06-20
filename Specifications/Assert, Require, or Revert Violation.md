# Assert, Require, or Revert Violation

The Assert, Require, or Revert Violation vulnerability occurs when a smart contract evaluates a condition that leads to an $\tt assert$, $\tt require$, or $\tt revert$ instruction being triggered unexpectedly, without proper control, or under conditions that can be influenced by an adversary. A failing $\tt assert$, $\tt require$, or $\tt revert$ can be triggered by an attacker, indicate faulty logic, or lead to the unexpected propagation of a revert that breaks invariants or functionality.

An attacker can intentionally trigger failing assertions or conditions, causing the contract to revert critical operations, waste gas, lock tokens or funds, or block certain addresses — or even all users — from interacting with the contract.

## Specification primitives

Our defect specifications rely on standard Solidity datatypes — $\mathsf{Contract}$, $\mathsf{Method}$, $\mathsf{Address}$, $\mathsf{Env}$(ironment), and $\mathsf{State}$. A brief description of the necessary predicates and functions over these types is included in the table below. The evaluation of these primitives is stratified: structural properties are derived statically via Slither, while behavioral properties are verified at runtime via Forge/Kontrol assertions within the LLM-generated test harness.

| Symbol | Semantics |
|--------|-----------|
| ***Static Analysis (Slither)*** | |
| $\texttt{methods}(c)$ | The set of externally-callable functions (entry points) of contract $c$, which includes its public/external functions and the special $\tt receive$ and $\tt fallback$ functions. |
| $\texttt{Dom}(m)$ | The domain of admissible input arguments of method $m$ (its parameter types). The *domain* is a static Slither fact, whereas the witnessing *element* $x \in \mathsf{Dom}(m)$ is resolved dynamically (fuzzed by Forge or symbolic under Kontrol). |
| $\texttt{IsEssential}(m)$ | Holds if $m$ is a state-mutating operation essential to the contract's intended use — concretely, $m$ is non-$\tt view$/non-$\tt pure$ and either writes contract storage or transfers value (it is not a deprecated or intentionally disabled stub). A static, decidable over-approximation computed by Slither; it gates the griefing disjunct only. |
| ***Runtime Verification (Forge/Kontrol)*** | |
| $\texttt{FailExec}(a, m(x), \sigma, \sigma_{\mathit{err}})$ | Holds if caller $a$ (i.e. $\mathit{msg.sender}=a$) invoking $m$ with arguments $x$ in state $\sigma$ reverts, producing the error state $\sigma_{\mathit{err}}$. The applied form $m(x)$ abbreviates the pair $(m,x)$; the inputs $x$ are kept explicit because the panic and griefing branches quantify over them. |
| $\texttt{IsPanic}(\sigma_{\mathit{err}}, p)$ | Holds if the revert recorded in $\sigma_{\mathit{err}}$ is a Solidity Panic (0.8.x) with code $p$. We use the named code constant $\mathsf{P_{assert}} \equiv \texttt{0x01}$ (a failed $\tt assert$ — an internal logic-invariant violation). In particular $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})$ excludes a user-facing $\tt require$, which does not raise a Panic (it yields Error(string) or an empty revert). |
| $\texttt{IsGriefable}(m, \sigma)$ | Defined notation, *not* a trace-checked predicate: abbreviates $\forall a\in\mathsf{Address}.\,\forall x\in\mathsf{Dom}(m).\,\exists\sigma_{\mathit{err}}.\,\mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}})$, i.e.\ $m$ reverts for every caller and input at $\sigma$; a denial-of-service defect only in conjunction with $\texttt{IsEssential}(m)$. |


## Formal Specification

The Logic Fault predicate is defined as the existence of a method, an input in its domain, and a pair of states — an initial state and a resulting error state — such that the execution fails and the failure is either a Panic or a griefable revert:

$$\begin{aligned}
\mathsf{LogicFault}(c) \equiv {}& \exists m \in \mathsf{methods}(c).\ \exists \sigma \in \mathsf{State}.\\
&\bigl(\exists a \in \mathsf{Address}.\ \exists x \in \mathsf{Dom}(m).\ \exists \sigma_{\mathit{err}} \in \mathsf{State}.\ \mathsf{FailExec}(a, m(x), \sigma, \sigma_{\mathit{err}}) \land \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})\bigr)\\
&\quad{}\lor\ \bigl(\mathsf{IsEssential}(m) \land \mathsf{IsGriefable}(m, \sigma)\bigr)
\end{aligned}$$

where the griefing predicate $\mathsf{IsGriefable}$ abbreviates the universally quantified denial-of-service condition

$$\mathsf{IsGriefable}(m,\sigma) \equiv \forall a \in \mathsf{Address}.\ \forall x \in \mathsf{Dom}(m).\ \exists \sigma_{\mathit{err}} \in \mathsf{State}.\ \mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}),$$

the invocation $m(x)$ being issued by caller $a$ (i.e. $\mathit{msg.sender}=a$). Unfolding $\mathsf{IsGriefable}$ this way exposes the quantifier structure the witness must discharge: a *symbolic* caller discharges $\forall a$, a *symbolic* input $h_{\mathit{args}}$ discharges $\forall x$, and the intercepted revert supplies the $\exists\sigma_{\mathit{err}}$. It also makes precise why only Kontrol soundly witnesses this disjunct — a concrete Forge run samples finitely many $(a,x)$ and cannot establish the universals.

The griefing disjunct $\mathsf{IsEssential}(m) \land \mathsf{IsGriefable}(m, \sigma)$ captures *griefing* attacks, in which an *essential* method can be forced to fail for every caller in the reachable state $\sigma$, yielding a denial of service or locked funds without necessarily violating a functional specification. The essentiality conjunct $\mathsf{IsEssential}(m)$ is what separates a genuine denial of service from a method that reverts for everyone *by design* — a deprecated or disabled stub, or a callback that intentionally rejects its caller: only when $m$ is an essential, state-mutating operation does a universal revert deny the contract a function it is meant to provide. As noted above, the universal quantification over callers and inputs restricts this branch to Kontrol, whose symbolic caller and inputs witness the revert on *every* feasible path from $\sigma$. Note the deliberate revert-kind asymmetry between the two branches: the panic branch restricts to $\tt Panic(0x01)$ (via $\mathsf{IsPanic}$), whereas the griefing branch accepts *any* revert ($\tt vm.expectRevert()$ with no selector). This is not a weaker check: under the universal $\forall a\,\forall x$ the revert kind is immaterial, as a revert firing for *every* caller and input bricks an essential method just as effectively as a panic, so any total revert is a genuine denial of service. The complementary exclusion of ordinary single-input $\tt require$ validation is enforced in the panic branch (see *Scope* below).

**Role of the input witness $x$ per branch.** Whether the existential input $\exists x \in \mathsf{Dom}(m)$ is *load-bearing* depends on how the panic is triggered, along two independent axes — its dependence on the input $x$ and on the state $\sigma$. Writing $P(x,\sigma)$ for "$m(x)$ raises $\tt Panic(0x01)$ in state $\sigma$", the *panic* disjunct splits into four cases: (i) $P$ holds for *every* $x$ in *every* reachable $\sigma$ (e.g. an unconditional $\tt assert(false)$): neither $x$ nor $\sigma$ is load-bearing; (ii) $P$ holds for *every* $x$ but only in a specific $\sigma$ (a broken invariant reachable only after a particular setup): $\sigma$ is load-bearing — materialized by the $\tt setUp$ that establishes $h_{\mathit{init}}$ — while $x$ ranges freely; (iii) $P$ holds only for a specific $x$, in any $\sigma$ (e.g. $\tt assert(x != k)$ for a reachable $k$): $x$ is load-bearing — materialized by a $\tt vm.assume$ that pins the fuzzed/symbolic $h_{\mathit{args}}$ to the panicking subset — while $\sigma$ ranges freely; (iv) $P$ holds only for a specific $x$ in a specific $\sigma$: both are load-bearing, pinned by $\tt vm.assume$ and $\tt setUp$ respectively. In all four the harness leaves $h_{\mathit{args}}$ fuzzed (Forge) or symbolic (Kontrol) and narrows it only as needed: the input-independent cases (i)–(ii) need no input constraint, whereas the input-specific cases (iii)–(iv) require the pinning $\tt vm.assume$ to keep $\tt vm.expectRevert(stdError.assertionError)$ passing. This is sound throughout: a passing run exhibits a concrete $(a,x,\sigma)$ at which $\mathsf{FailExec}(a,m(x),\sigma,\sigma_{\mathit{err}})$ and $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})$ hold, witnessing the existential $\exists a\,\exists x\,\exists\sigma$ — and in the input-independent cases (i)–(ii) the test additionally exercises $x$ freely (all feasible $x$ under Kontrol, sampled $x$ under Forge) and finds each panics, a property strictly stronger than the required $\exists x$. By contrast, the *griefing* branch keeps *both* the caller $h_{\mathit{caller}}$ and $h_{\mathit{args}}$ symbolic and universally quantified, since $\mathsf{IsGriefable}(m, \sigma)$ asserts failure for all callers and inputs; the input *existential* $\exists x$ does not appear in this disjunct at all (it is scoped to the panic branch) — instead $h_{\mathit{args}}$ is held symbolic to discharge the *universal* $\forall x$ of the unfolded $\mathsf{IsGriefable}$, exactly as $h_{\mathit{caller}}$ discharges $\forall a$.

**Scope.** Although the category is named for $\tt assert$/$\tt require$/$\tt revert$, the formalization deliberately targets the two cases that constitute genuine defects: a broken *internal invariant* surfacing as $\tt Panic(0x01)$ ($\mathsf{IsPanic}$), and an *essential* method that denies service to *every* caller in a reachable state ($\mathsf{IsEssential}\land\mathsf{IsGriefable}$). An isolated $\tt require$ failure on a single bad input — ordinary input validation — is intentionally *not* flagged, as it does not constitute a vulnerability. The restriction of $\mathsf{IsPanic}$ to $\tt Panic(0x01)$ enforces this exclusion in the panic branch — a failed $\tt require$ does not satisfy $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})$ (cf. the primitives table) — so only a genuine internal-invariant violation (a failed $\tt assert$) is admitted.

**Reachability of the panic state $\sigma$.** The panic disjunct quantifies $\exists\sigma\in\mathsf{State}$ without restriction, and the template realizes $\sigma$ either through public setters (Strategy A) or, for private/hard-to-reach state, through direct storage manipulation with $\tt vm.store$/$\tt stdstore$ (Strategy B). For the witnessed $\tt Panic(0x01)$ to certify a *genuine* defect rather than an artefact, the chosen $\sigma$ must be *reachable*: it must be constructible through $c$'s public interface — deployment (with constructor arguments) followed by public/external calls — so Strategy B is admissible only when it sets storage to values some public call sequence of $c$ could also produce. A $\tt Panic(0x01)$ fired only from an unreachable $\sigma$ is a spurious witness and does not satisfy $\mathsf{LogicFault}(c)$. (The griefing branch already states $\sigma$ as the *reachable* state, and is likewise governed by this reachability condition.)

**Residual human judgement (griefing).** The griefing witness establishes exactly that an essential $m$ reverts for *every* caller and input at the *reachable* state $\sigma$. It does *not* establish that this denial of service is *permanent*: whether $\sigma$ is a trap (no caller sequence re-enables $m$) or merely a recoverable configuration — e.g. a correctly $\tt paused$ contract that an authorised caller can later $\tt unpause$ — is a reachability property the harness does not decide. We deliberately do *not* encode permanence as a predicate, since it is neither read from the trace nor discharged by a tool; rather, it is an explicit side judgement left to the analyst. Consequently a *recoverable* denial of service may satisfy the witnessed griefing property without being a defect: the theorem certifies only the universal revert at $\sigma$ (the *formula as written*), not the strictly stronger informal notion of a *permanent* denial of service, which $\mathsf{LogicFault}(c)$ does not encode — whether the revert is permanent is the analyst's side judgement. For the griefing branch this conclusion moreover holds *only under Kontrol and only under the symbolic-coverage premise* discussed above: absent it — under Forge, or if a $\tt vm.assume$ narrows the caller or inputs — the run only samples the universal $\forall a\,\forall x$ and weakens to corroborating evidence.

**Assumption (Essentiality identification).** The conjunct $\mathsf{IsEssential}(m)$ is discharged by the static Slither classifier of the primitives table. Its soundness as a filter rests on this classifier being *accurate* on $h_m$: an over-broad classifier admits a non-essential method (a false positive — e.g. flagging an intentionally disabled stub), while an over-narrow one rejects a genuinely essential method (a false negative). We therefore assume the classifier correctly decides the essentiality of the selected $h_m$; like the other static $\mathcal{P}_0$ conjuncts, $\mathsf{IsEssential}(m)$ is never confirmed on the trace, so this precision is a standing premise of the derivation rather than a property the test establishes.

## Specific test template design

**Testing Goal** — Identify valid input sequences that drive the contract into a panic state or a denial-of-service condition.

**Setup** — The LLM initializes the contract state and identifies the essential methods that must remain accessible for the system to function correctly, such as withdrawals or critical administrative operations.

**Action** — The test invokes the target method with fuzzed or symbolic parameters in the chosen state. To reach specific faults, the LLM may establish a specialized configuration through additional setup calls before the main transaction.

**Check** — The harness monitors for Solidity panic codes, notably a failed assertion, and for unexpected reverts triggered by otherwise valid environment states.

**Assertion** — Verification relies on a revert expectation asserting that the call to the target method fails under the identified conditions. If a sequence of transactions makes an essential method unreachable or causes it to revert unexpectedly, the framework flags the behaviour as a valid vulnerability. Because the revert expectation must appear immediately before the reverting call, the assertion phase precedes the action phase — a key structural difference from the Reentrancy template.

## Template Derivation and LLM Instantiation

The conceptual test design is materialized into a standardized Foundry test template (e.g., $\tt AssertRequireOrRevertViolation.t.sol$). To bridge the gap between static analysis and generation, the template embeds explicit $\tt [LLM\_INSTRUCTION]$ comments to guide the LLM through the instantiation phase.

Each hole is assigned to either Slither or the LLM for resolution, as summarized in the table below.
The specification $\mathsf{LogicFault}(c)$ contains four existential witnesses, which map to typed holes in the template schema (together with an auxiliary caller hole $h_{\mathit{caller}}$ used by the grief variant):

| Spec witness | Hole | Sort | Resolved by |
|---|---|---|---|
| $\exists m \in \mathsf{methods}(c)$ | $h_m$ | $\mathsf{Method}$ | Slither |
| $\exists x \in \mathsf{Dom}(m)$ | $h_{\mathit{args}}$ | $\mathsf{InputArgs}$ | LLM (fuzzed/symbolic) |
| caller (panic: $\exists a$ via default; grief: $\forall a$) | $h_{\mathit{caller}}$ | $\mathsf{Address}$ | default caller (panic) / Kontrol symbolic (grief) |
| $\exists \sigma \in \mathsf{State}$ | $h_{\mathit{init}}$ | $\mathsf{State}$ | LLM |
| $\exists \sigma_{\mathit{err}} \in \mathsf{State}$ | witnessed at runtime | | Forge/Kontrol (revert/panic) |

The error state $\sigma_{\mathit{err}}$ carries no explicit hole: its existence is witnessed at runtime when the EVM emits a Panic code or a plain revert, making it an implicit existential that is *verified* rather than *filled*.

Before stating the derivation rules, we record how each conjunct of $\mathsf{LogicFault}(c)$ maps to exactly one test phase and its concrete template realization. The disjunction $\bigl(\exists a\,\exists x.\ \mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}) \land \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})\bigr) \lor \mathsf{IsGriefable}(m, \sigma)$ gives rise to two template variants, labelled **[Assrt-Panic]** and **[Assrt-Grief]**:

| Spec element | Phase | Template realization |
|---|---|---|
| $\exists \sigma \in \mathsf{State}$ *(witness)* | *setUp* | $h_{\mathit{init}}$; $\tt vm.deal(victim,\cdot)$ if payable |
| $\exists x \in \mathsf{Dom}(m)$ *(witness)* | *setUp* | $\tt vm.assume(\cdot)$ constraining fuzzed/symbolic $h_{\mathit{args}}$ |
| $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})$ | *assert* | $\tt vm.expectRevert(stdError.assertionError)$ |
| $\mathsf{IsGriefable}(m, \sigma)$ | *assert* | $\tt vm.expectRevert()$ (DoS variant; symbolic, via Kontrol) |
| $\mathsf{IsEssential}(m)$ *(grief variant)* | *action* | cited as a premise of **[Act-Grief]** (static $\mathcal{P}_0$ fact) |
| $\forall$ caller (grief variant) | *action* | $\tt vm.prank(h_{caller})$ (symbolic caller ⇒ every caller; grief variant only) |
| $\mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}})$ | *action* | $\texttt{victim.}h_m\texttt{(}h_{\mathit{args}}\texttt{)}$ (caller $a$ set by $\tt vm.prank(h_{caller})$ in the grief variant; default caller in the panic variant) |

## Derivation Rules for $\vdash$

This section gives a rigorous definition of the relation $\Phi(c) \vdash \tau$, read "defect specification $\Phi$ derives template schema $\tau$". We develop it through the Assert/Require/Revert Violation running example.

The relation $\Phi(c) \vdash \tau$ is defined by the following seven rules.

Witnesses become typed holes:

$$\dfrac{}{\displaystyle \Phi \vdash \bigl\{ h_m : \mathsf{Method},\; h_{\mathit{args}} : \mathsf{InputArgs},\; h_{\mathit{caller}} : \mathsf{Address},\; h_{\mathit{init}} : \mathsf{State} \bigr\}} \quad \text{[Holes]}$$

Preconditions $\exists \sigma \in \mathsf{State}$ and $\exists x \in \mathsf{Dom}(m)$ derive the *setUp* phase:

$$\dfrac{\displaystyle \sigma \in \mathsf{State}\ \text{and}\ x \in \mathsf{Dom}(m)\ \text{existential witnesses of}\ \Phi}{\displaystyle \Phi \vdash^{v}_{\mathit{setUp}} \left[\, h_{\mathit{init}};\; \texttt{vm.deal}(\mathit{victim},\cdot)\ \text{if payable};\; \texttt{vm.assume}(\cdot) \,\right]} \quad \text{[Pre]}$$

Here and below $v \in \{\textsf{panic},\textsf{grief}\}$ is the variant tag selecting which disjunct is being derived; [Pre] is variant-generic.

Panic condition derives the *assert* phase (Panic variant):

$$\dfrac{\displaystyle \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}}) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash^{\textsf{panic}}_{\mathit{assert}} \bigl[\,\texttt{vm.expectRevert(stdError.assertionError)}\,\bigr]} \quad \text{[Assrt-Panic]}$$

Griefable condition derives the *assert* phase (DoS variant):

$$\dfrac{\displaystyle \mathsf{IsGriefable}(m, \sigma) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash^{\textsf{grief}}_{\mathit{assert}} \bigl[\,\texttt{vm.expectRevert()}\,\bigr]} \quad \text{[Assrt-Grief]}$$

Failing execution derives the *action* phase, in two variants mirroring the two assert variants. The **panic** variant issues the call directly, since $\tt Panic(0x01)$ is independent of $\mathit{msg.sender}$:

$$\dfrac{\displaystyle \mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}) \in \mathrm{conjuncts}(\Phi) \quad \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}}) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash^{\textsf{panic}}_{\mathit{action}} \bigl[\,\mathit{victim}.h_m(h_{\mathit{args}})\,\bigr]} \quad \text{[Act-Panic]}$$

In [Act-Panic] the existential $\exists a$ of the panic branch is witnessed by the harness's default caller (the test contract's own $\mathit{msg.sender}$), so no symbolic caller is needed.

The **grief** variant prepends $\texttt{vm.prank}(h_{\mathit{caller}})$ with a *symbolic* caller and symbolic $h_{\mathit{args}}$, so that a passing $\tt vm.expectRevert()$ under Kontrol witnesses the revert for *every* caller and input; the essentiality premise $\mathsf{IsEssential}(m)$ is discharged statically at $h_m$ selection by Slither (a $\mathcal{P}_0$ fact):

$$\dfrac{\displaystyle \mathsf{IsEssential}(m) \in \mathrm{conjuncts}(\Phi) \quad \mathsf{IsGriefable}(m, \sigma) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash^{\textsf{grief}}_{\mathit{action}} \bigl[\,\texttt{vm.prank}(h_{\mathit{caller}});\; \mathit{victim}.h_m(h_{\mathit{args}})\,\bigr]} \quad \text{[Act-Grief]}$$

All phases combine into the full schema:

$$\dfrac{\displaystyle \Phi \vdash H \qquad \Phi \vdash^{v}_{\mathit{setUp}} S \qquad \Phi \vdash^{v}_{\mathit{assert}} \mathit{AS} \qquad \Phi \vdash^{v}_{\mathit{action}} A}{\displaystyle \Phi \vdash \langle H,\, S,\, \mathit{AS},\, A \rangle} \quad \text{[Template]}$$

The shared tag $v \in \{\textsf{panic},\textsf{grief}\}$ forces all phases into the same disjunct, so the unsound cross-pairing (an any-revert assertion in front of a single-caller call) is not derivable.


## Derived Assert/Require/Revert Multi-Shot Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

// [LLM_INSTRUCTION]: Import stdError to catch Assertion Violation (Panic 0x01).
import {Test, stdError} from "../lib/forge-std/src/Test.sol";
// [LLM_INSTRUCTION]: If you need to manipulate private state directly, import StdStorage:
// import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The
// solidity files are in "../src/". The name of the file is the same as the name of the contract.

// ------------------------------ 
// [Testing Goal] Identify valid input sequences that transition the contract
// into a Panic state or a Denial-of-Service (DoS) condition.
// ------------------------------ 

// [LLM_INSTRUCTION]: Name the contract 'TestAssertFailure[ContractName]'
contract TestAssertFailureTemplate is Test {
    // [LLM_INSTRUCTION]: Use StdStorage if needed for complex state setup:
    // using stdStorage for StdStorage;

    // ------------------------------ 
    // [Setup] Declare the contract under test. Identify "essential" methods
    // that must remain accessible (e.g., withdraw(), admin functions).
    // ------------------------------ 

    // [LLM_INSTRUCTION]: Declare the contract under test variable
    // ConditionAlwaysFalse public _contractUnderTest;

    // ------------------------------ [/Setup]

    function setUp() public {
        // ------------------------------ 
        // [Setup] Initialize the contract state.
        // ------------------------------ 

        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // 1. If constructor parameters are needed, use concrete valid values.
        // 2. If payable, use vm.deal(address(this), amount) before deployment.
        // _contractUnderTest = new ConditionAlwaysFalse();

        // ------------------------------ [/Setup]
    }

    // [LLM_INSTRUCTION]: Analyze the method being tested.
    // 1. If it accepts arguments, ADD them to this function signature to enable Fuzzing/Symbolic execution.
    // 2. If it takes no arguments, keep the signature empty.
    // 3. GRIEFING variant: also add a fuzzed/symbolic 'address caller' to witness a universal DoS.
    // Example: function test_highlightAssertionFailure(uint256 fuzzArg) public {
    // Example (grief): function test_highlightAssertionFailure(address caller, uint256 fuzzArg) public {
    function test_highlightAssertionFailure() public {

        // ------------------------------ 
        // [Setup] Constrain fuzz/symbolic inputs and configure pre-conditions.
        // The LLM may establish a specialized configuration through additional
        // setup calls prior to the main transaction.
        // ------------------------------ 

        // [LLM_INSTRUCTION]: Use 'vm.assume' to constrain inputs to reachable logical paths.
        // WARNING: Avoid assumptions that make the specific assertion failure impossible.
        // Example: vm.assume(fuzzArg > 10);

        // [LLM_INSTRUCTION]: FUNDING (If Applicable)
        // Even for logic tests, funding ensures calls don't fail due to low-level balance checks.
        // 1. Fund the Victim: vm.deal(address(_contractUnderTest), 100 ether);
        // 2. CRITICAL: Fund the Test Contract (address(this)) if it interacts with payable functions.
        //    vm.deal(address(this), 100 ether);

        // [LLM_INSTRUCTION]: STATE VARIABLES
        // Does the assertion failure require specific state (e.g. an inconsistent update)?

        // STRATEGY A: Public Methods (Preferred)
        // Call public setters.
        // Example: _contractUnderTest.setState(fuzzArg);

        // STRATEGY B: Storage Manipulation (For Private/Hard-to-reach State)
        // Use 'vm.store' or 'stdstore' to force the contract into a "contradictory" state.
        // Example:
        // stdstore.target(address(_contractUnderTest)).sig("myVar()").checked_write(fuzzArg);

        // ------------------------------ [/Setup]

        // ------------------------------ 
        // [Check] Monitor for Solidity Panic codes (e.g., 0x01 for failed
        // assertions) and unexpected reverts triggered by valid environment states.
        // ------------------------------ 

        // ------------------------------ 
        // [Assertion] Use vm.expectRevert() to assert that the call to the
        // target method fails under the identified conditions. If a sequence of
        // transactions makes an essential method unreachable or
        // causes it to revert unexpectedly, the behavior is flagged as a
        // valid vulnerability.
        // ------------------------------ 

        // [LLM_INSTRUCTION]: Pick the assertion by defect branch:
        //  - PANIC branch (broken internal invariant / failed `assert` -> Panic(0x01)):
        //    keep the assertion-error matcher below and issue a bare call (no prank).
        //  - GRIEFING branch (universal DoS: a require/revert that fails for EVERY caller):
        //    a require failure raises Error(string), NOT Panic(0x01), so use a generic
        //    `vm.expectRevert()` instead, and drive the call from a fuzzed/symbolic `caller`
        //    via `vm.prank(caller)` in the Action phase. Under Kontrol a symbolic caller
        //    witnesses the revert for every caller (the universal DoS).
        // PANIC branch (default) - confirms the contract reverts with Panic(0x01) (Assert Failed):
        vm.expectRevert(stdError.assertionError);
        // GRIEFING branch (alternative): vm.expectRevert();

        // ------------------------------ [/Check]

        // ------------------------------ 
        // [Action] Invoke the target method with fuzzing/symbolic parameters
        // to trigger the fault.
        // ------------------------------ 

        // [LLM_INSTRUCTION]: Call the function.
        // If you added parameters to the test signature, pass them here.
        // _contractUnderTest.notGonnaExecute(fuzzArg);
        // GRIEFING variant: prepend vm.prank(caller) so the call runs as the fuzzed/symbolic caller.
        // vm.prank(caller);
        // _contractUnderTest.notGonnaExecute(fuzzArg);

        // ------------------------------ [/Action]
        // ------------------------------ [/Assertion]
    }
}
```

### Rule Application

The derivation $\mathsf{LogicFault}(c) \vdash \tau$ proceeds by applying the rules in sequence. For each step we identify the triggering conjunct(s) from $\mathsf{LogicFault}(c)$, state what the rule derives, and map the output to the specific region of the code template above. Because the disjunction $\bigl(\exists a\,\exists x.\ \mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}) \land \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})\bigr) \lor \bigl(\mathsf{IsEssential}(m) \land \mathsf{IsGriefable}(m, \sigma)\bigr)$ yields two different assertion-and-action strategies, the Rule Application covers both variants at Steps 3 and 4.

---

**Step 1 — [Holes]** (no premise)

The axiom fires unconditionally and establishes the hole signature:

$$H = \bigl\{\, h_m : \mathsf{Method},\quad h_{\mathit{args}} : \mathsf{InputArgs},\quad h_{\mathit{caller}} : \mathsf{Address},\quad h_{\mathit{init}} : \mathsf{State} \,\bigr\}$$

Each hole appears in the template as a $\tt [LLM\_INSTRUCTION]$ placeholder:

| Hole | Sort | Stands for | Filled by |
|---|---|---|---|
| $h_m$ | $\mathsf{Method}$ | the target method whose execution is expected to revert | Slither (e.g., $\tt \_contractUnderTest.notGonnaExecute$) |
| $h_{\mathit{args}}$ | $\mathsf{InputArgs}$ | the arguments passed to $h_m$ that trigger the fault | LLM (fuzzed/symbolic, e.g., $\tt fuzzArg$) |
| $h_{\mathit{caller}}$ | $\mathsf{Address}$ | the caller of $h_m$ (grief variant only; symbolic under Kontrol to range over all callers) | default caller (panic) / Kontrol symbolic (grief) |
| $h_{\mathit{init}}$ | $\mathsf{State}$ | the state-initializing statements in $\tt setUp()$ | LLM (e.g., $\tt \_contractUnderTest = new\ ConditionAlwaysFalse()$) |

---

**Step 2 — [Pre]** fires on $C_1 = (\exists \sigma \in \mathsf{State})$ and $C_2 = (\exists x \in \mathsf{Dom}(m))$

Triggering conjuncts:
- $C_1 = (\exists \sigma \in \mathsf{State}) \in \mathrm{conjuncts}(\mathsf{LogicFault}(c))$ — there must exist an initial state from which the fault is reachable.
- $C_2 = (\exists x \in \mathsf{Dom}(m)) \in \mathrm{conjuncts}(\mathsf{LogicFault}(c))$ — the fault-triggering argument must lie within the domain of $m$.

Derives:
$$\Phi \vdash_{\mathit{setUp}} \bigl[\, h_{\mathit{init}};\; \texttt{vm.deal}(\mathit{victim},\cdot)\ \text{if payable};\; \texttt{vm.assume}(\cdot) \,\bigr]$$

Template realization — the $\tt [Setup]$ regions cover two locations:

- In $\tt setUp()$: the $\tt [LLM\_INSTRUCTION]$ for $h_{\mathit{init}}$ instantiates the contract under test (e.g., $\tt \_contractUnderTest = new\ ConditionAlwaysFalse()$), realizing $C_1$ by fixing an initial state $\sigma$.
- In $\tt test\_highlightAssertionFailure()$: the $\tt [LLM\_INSTRUCTION]$ for $\tt vm.assume$ constrains the fuzzed/symbolic parameter (e.g., $\tt vm.assume(fuzzArg > 10)$), ensuring $h_{\mathit{args}}$ stays within $\mathsf{Dom}(m)$ and realizing $C_2$. Optional $\tt vm.deal$ calls fund the victim if the method is payable.

---

**Step 3 — [Assrt-Panic] or [Assrt-Grief]** fires on $C_3$

The disjunction $\bigl(\exists a\,\exists x.\ \mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}) \land \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})\bigr) \lor \bigl(\mathsf{IsEssential}(m) \land \mathsf{IsGriefable}(m, \sigma)\bigr)$ in $\mathsf{LogicFault}(c)$ gives rise to two alternative sub-derivations. Exactly one branch is selected based on which conjunct the tool pipeline can discharge.

**Variant A — [Assrt-Panic]** fires when $C_{3a} = \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}}) \in \mathrm{conjuncts}(\Phi)$.

Slither flags the method $h_m$ as containing an $\tt assert$ check or arithmetic that may panic; Forge/Kontrol confirms at runtime that the revert carries a Solidity Panic code.

Derives:
$$\Phi \vdash^{\textsf{panic}}_{\mathit{assert}} \bigl[\,\texttt{vm.expectRevert(stdError.assertionError)}\,\bigr]$$

Template realization — the $\tt [Check]$ / $\tt [Assertion]$ region:
```solidity
// This confirms that the contract reverts with Panic(0x01) (Assert Failed).
vm.expectRevert(stdError.assertionError);
```
The cheatcode $\tt vm.expectRevert(stdError.assertionError)$ intercepts the Panic(0x01) signal emitted by the EVM when an $\tt assert$ is violated, directly witnessing $C_{3a}$.

**Variant B — [Assrt-Grief]** fires when $C_{3b} = \mathsf{IsGriefable}(m, \sigma) \in \mathrm{conjuncts}(\Phi)$, with $h_m$ additionally an *essential* method ($\mathsf{IsEssential}(m)$, discharged statically by Slither).

Symbolic execution (Kontrol) establishes that no input and no caller can reach a successful completion of $h_m$ from $\sigma$, i.e., the essential method is blocked at the reachable state $\sigma$. (Whether this block is *permanent* — no caller sequence re-enables $h_m$ — versus a recoverable configuration is a side judgement left to the analyst, per the Scope note; the witness certifies only the universal revert at $\sigma$.)

Derives:
$$\Phi \vdash^{\textsf{grief}}_{\mathit{assert}} \bigl[\,\texttt{vm.expectRevert()}\,\bigr]$$

Template realization: replace $\tt vm.expectRevert(stdError.assertionError)$ with the bare $\tt vm.expectRevert()$, which matches any revert reason, confirming that $h_m$ always reverts for any $h_{\mathit{args}}$ in $\mathsf{Dom}(m)$ and thus witnesses $C_{3b}$.

---

**Step 4 — [Act-Panic] or [Act-Grief]** fires on $C_4$

Triggering conjunct: $C_4 = \mathsf{FailExec}(a, m(x), \sigma, \sigma_{\mathit{err}}) \in \mathrm{conjuncts}(\mathsf{LogicFault}(c))$ — invoking $m$ with $x$ in $\sigma$ must revert, producing $\sigma_{\mathit{err}}$. The action variant matches the assert variant selected in Step 3.

**Variant A — [Act-Panic]** issues the call directly, with no $\tt vm.prank$, since $\tt Panic(0x01)$ is independent of $\mathit{msg.sender}$; the existential $\exists a$ is witnessed by the harness's default caller:
$$\Phi \vdash^{\textsf{panic}}_{\mathit{action}} \bigl[\,\mathit{victim}.h_m(h_{\mathit{args}})\,\bigr]$$

**Variant B — [Act-Grief]** prepends $\tt vm.prank(h_{caller})$ with a *symbolic* caller (and symbolic $h_{\mathit{args}}$), so that the passing $\tt vm.expectRevert()$ from Step 3 witnesses the revert for *every* caller and input; the essentiality premise $\mathsf{IsEssential}(m)$ is discharged statically by Slither:
$$\Phi \vdash^{\textsf{grief}}_{\mathit{action}} \bigl[\,\texttt{vm.prank}(h_{\mathit{caller}});\; \mathit{victim}.h_m(h_{\mathit{args}})\,\bigr]$$

Template realization — the $\tt [Action]$ region in $\tt test\_highlightAssertionFailure()$:
```solidity
// _contractUnderTest.notGonnaExecute(fuzzArg);   // = victim.h_m(h_args)  →  C₄
// GRIEFING variant: prepend vm.prank(caller) so the call runs as the symbolic caller.
```
The $\tt [LLM\_INSTRUCTION]$ directs the LLM to call $h_m$ with $h_{\mathit{args}}$ (in the grief variant, behind $\tt vm.prank(h_{caller})$). Because $\tt vm.expectRevert$ was placed immediately before this line (Step 3), the Forge/Kontrol runner intercepts the revert and converts it from a test failure into a passing assertion, witnessing $C_4$.

Note the key structural difference from the Reentrancy template: the *assert* phase precedes the *action* phase in this template, because $\tt vm.expectRevert$ must appear immediately before the reverting call.

---

**Step 5 — [Template]** assembles all four sub-derivations

All premises of [Template] are now established:

| Premise | Established in |
|---|---|
| $\Phi \vdash H$ | Step 1 |
| $\Phi \vdash_{\mathit{setUp}} S$ | Step 2 |
| $\Phi \vdash_{\mathit{assert}} \mathit{AS}$ | Step 3 (Panic variant or Grief variant) |
| $\Phi \vdash_{\mathit{action}} A$ | Step 4 |

Applying [Template] yields $\mathsf{LogicFault}(c) \vdash \langle H, S, \mathit{AS}, A \rangle = \tau$, which is exactly the code template above with open holes for the LLM to fill. The three code phases of $\tau$ cover all elements of $\mathsf{LogicFault}(c)$ as recorded in the Phase–Conjunct table above, though not bijectively: the *setUp* phase realizes both existential witnesses $\exists \sigma$ and $\exists x \in \mathsf{Dom}(m)$, the *assert* phase realizes the disjunction $\bigl(\exists a\,\exists x.\ \mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}) \land \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})\bigr) \lor \bigl(\mathsf{IsEssential}(m) \land \mathsf{IsGriefable}(m, \sigma)\bigr)$ (in its selected variant), and the *action* phase realizes $\mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}})$, completing the derivation. The two variants [Assrt-Panic] and [Assrt-Grief] differ only in the *assert* phase: the former emits $\tt vm.expectRevert(stdError.assertionError)$ to catch a typed Panic revert, while the latter emits the bare $\tt vm.expectRevert()$ to catch any revert arising from a DoS-inducing griefing attack.

## Soundness of $\vdash$ for $\mathsf{LogicFault}(c)$

**Theorem (Soundness of $\vdash$ for $\mathsf{LogicFault}(c)$).** Let $\mathsf{LogicFault}(c) \vdash \tau$ be derivable by the rules above with variant tag $v \in \{\textsf{panic},\textsf{grief}\}$, let $\tau[\theta]$ be a ground instance of $\tau$ obtained by resolving all holes in $H$ (Slither for $h_m$; the LLM/fuzzer/solver for $h_{\mathit{args}}$, $h_{\mathit{caller}}$, $h_{\mathit{init}}$), and let $M_{\tau[\theta]}$ be the EVM execution trace produced by running $\tau[\theta]$. Assume $\tau[\theta]$ is *non-vacuous* — the *setUp* path constraints together with any model-supplied $\tt vm.assume$s are jointly satisfiable on the evaluated path — and that the chosen $\sigma$ satisfies the reachability condition above. Then:

- **(Panic, $v = \textsf{panic}$)** if $\tau[\theta]$ passes in Forge or Kontrol (the placed $\tt vm.expectRevert(stdError.assertionError)$ intercepts the expected $\tt Panic(0x01)$), then $M_{\tau[\theta]} \models \mathsf{LogicFault}(c)$ via the panic disjunct;
- **(Grief, $v = \textsf{grief}$)** if $\tau[\theta]$ passes under Kontrol with $h_{\mathit{caller}}$ and $h_{\mathit{args}}$ held *symbolic and unconstrained* over $\mathsf{Address}\times\mathsf{Dom}(m)$ (the *symbolic-coverage* premise) and $\mathsf{IsEssential}(m)$ holds (the *Essentiality-identification* premise), then $M_{\tau[\theta]} \models \mathsf{LogicFault}(c)$ via the griefing disjunct. Under Forge, or if the symbolic-coverage premise fails, a passing run only *samples* the universal and yields corroborating evidence, not a constructive witness.

That is, a passing test induces an execution trace $M_{\tau[\theta]}$ that is a model of, hence a *constructive witness* for, the disjunctive statement $\mathsf{LogicFault}(c)$. Since $M \models D_P \lor D_G$ holds as soon as $M$ satisfies *one* disjunct, the variant tag $v$ selects which disjunct the test witnesses, and we show $M_{\tau[\theta]}$ satisfies that disjunct.

**Setup.** Recall the specification, with its two disjuncts $D_P$ (panic) and $D_G$ (griefing) and their conjuncts labelled:

$$\begin{aligned}
\mathsf{LogicFault}(c) \equiv{} &
  \exists m \in \mathsf{methods}(c).\; \exists \sigma \in \mathsf{State}.\;
  \bigl( D_P \;\lor\; D_G \bigr),\quad\text{where}\\
  D_P \;\equiv{}& \exists a\,\exists x\,\exists \sigma_{\mathit{err}}.\;
    \underbrace{\mathsf{FailExec}(a, m(x), \sigma, \sigma_{\mathit{err}})}_{C^P_1} \;\land\;
    \underbrace{\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}})}_{C^P_2},\\
  D_G \;\equiv{}& \underbrace{\mathsf{IsEssential}(m)}_{C^G_1} \;\land\;
    \underbrace{\mathsf{IsGriefable}(m, \sigma)}_{C^G_2},\quad
    \mathsf{IsGriefable}(m,\sigma) \equiv \forall a\,\forall x\,\exists \sigma_{\mathit{err}}.\;
    \mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}).
\end{aligned}$$

The derivation $\mathsf{LogicFault}(c) \vdash \tau$ is variant-tagged: its leaves are [Holes], the variant-generic [Pre], and the variant-specific assert/action rules ([Assrt-Panic]/[Act-Panic] or [Assrt-Grief]/[Act-Grief]), with root [Template]. We prove soundness by cases on $v$. In either case the test-induced model is $M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle$, where $\mathcal{S}$ is the many-sorted domain (EVM states, methods, addresses, inputs, etc.), $\mathcal{P}_0 = \mathrm{Slither}(c)$ (supplying $\mathsf{IsEssential}$ in the grief case), $\mathcal{P}_1$ is extracted from the trace (the intercepted revert), and the witness tuple is

$$\mathcal{W}_P = (\theta(h_m),\, \sigma,\, a,\, x,\, \sigma_{\mathit{err}}) \quad\text{(panic)}, \qquad \mathcal{W}_G = (\theta(h_m),\, \sigma) \quad\text{(grief)},$$

the panic tuple additionally fixing the disjunct's own existentials $a$ (default caller), $x$ (the witnessing input), and $\sigma_{\mathit{err}}$ (the intercepted $\tt Panic(0x01)$ state), while the grief disjunct binds no top-level existential beyond $m,\sigma$ (its $\forall a\,\forall x\,\exists\sigma_{\mathit{err}}$ is witnessed by symbolic coverage at runtime, not by a fixed tuple).

**Step 1 ([Holes]): witnesses are well-typed (both variants).** The [Holes] rule establishes

$$H = \bigl\{ h_m : \mathsf{Method},\; h_{\mathit{args}} : \mathsf{InputArgs},\; h_{\mathit{caller}} : \mathsf{Address},\; h_{\mathit{init}} : \mathsf{State} \bigr\}.$$

By assumption $\theta(h_m) \in \mathsf{methods}(c)$ per Slither, and $\theta(h_{\mathit{args}}), \theta(h_{\mathit{caller}}), \theta(h_{\mathit{init}})$ are syntactically valid Solidity, so $\tau[\theta]$ is a type-correct test. The error state $\sigma_{\mathit{err}}$ carries no hole; it is witnessed at runtime by the intercepted revert (Step 3). In the panic variant $h_{\mathit{caller}}$ resolves to the harness's default caller (the existential $\exists a$); in the grief variant it is held symbolic to range over $\mathsf{Address}$ (the universal $\forall a$).

**Lemma (Hole Typing).** If $\vdash H : \tau$ and $\tau[\theta]$ does not revert on a type error, then $\mathcal{W}_P$ (resp. $\mathcal{W}_G$) is a valid witness candidate for the existential prefix of the panic (resp. griefing) disjunct of $\mathsf{LogicFault}(c)$. ✓

**Step 2 ([Pre]): state $\sigma$ established (variant-generic).** The [Pre] rule fires on the outer existential $\sigma \in \mathsf{State}$ of $\Phi$ and derives the $\tt setUp$ phase $[\,h_{\mathit{init}};\; \texttt{vm.deal}(\mathit{victim},\cdot)\text{ if payable};\; \texttt{vm.assume}(\cdot)\,]$. When $\tau[\theta]$ runs, *setUp* establishes the reachable $\sigma$ (per the reachability condition above), so that a witnessed revert certifies a genuine defect rather than an artefact of a fabricated $\sigma$. The trailing $\tt vm.assume(\cdot)$ pins the input witness $x$ only in the panic variant's *input-specific* cases (iii)–(iv), where $\exists x$ is in scope; in the grief variant $h_{\mathit{args}}$ is left symbolic and the clause is vacuous. Either way *setUp* fixes the outer witness $\sigma$ shared by both disjuncts. ✓

**Step 3$_P$ ([Assrt-Panic]/[Act-Panic]): disjunct $D_P$ satisfied.** For $v = \textsf{panic}$, [Assrt-Panic] fires because $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}}) \in \mathrm{conjuncts}(D_P)$, emitting $\texttt{vm.expectRevert(stdError.assertionError)}$ *immediately before* the call; and [Act-Panic] fires because $\mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}) \in \mathrm{conjuncts}(D_P)$ and $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}}) \in \mathrm{conjuncts}(D_P)$, emitting the bare call $\mathit{victim}.h_m(h_{\mathit{args}})$ with *no* $\tt vm.prank$ (since $\tt Panic(0x01)$ is independent of $\mathit{msg.sender}$). When $\tau[\theta]$ passes, the placed $\tt vm.expectRevert(stdError.assertionError)$ intercepted the expected outcome: the call $\mathit{victim}.h_m(h_{\mathit{args}})$ reverted, producing the error state $\sigma_{\mathit{err}}$, so $\mathsf{FailExec}(a, m(x), \sigma, \sigma_{\mathit{err}}) \in \mathcal{P}_1$ with $a$ the default caller and $x = \theta(h_{\mathit{args}})$, establishing $C^P_1$; and the intercepted revert was specifically the assertion panic, so $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{assert}}) \in \mathcal{P}_1$, establishing $C^P_2$. A passing run thus exhibits a concrete triple $(a,x,\sigma_{\mathit{err}})$ witnessing $\exists a\,\exists x\,\exists\sigma_{\mathit{err}}$, regardless of whether $x$ was pinned by $\tt vm.assume$ (cases (iii)–(iv)) or ranged freely (cases (i)–(ii)); in the input-independent cases the test additionally finds *every* sampled/feasible $x$ panics, strictly stronger than the required $\exists x$. Hence $M_{\tau[\theta]} \models D_P$, so $M_{\tau[\theta]} \models D_P \lor D_G$. The restriction of $\mathsf{IsPanic}$ to $\tt Panic(0x01)$ excludes an ordinary $\tt require$ failure (which yields $\tt Error(string)$ or an empty revert, not $\tt Panic(0x01)$), so only a genuine internal-invariant violation is admitted. This branch is deterministic and holds under *both* Forge and Kontrol. ✓

**Step 3$_G$ ([Assrt-Grief]/[Act-Grief]): disjunct $D_G$ satisfied.** For $v = \textsf{grief}$, [Assrt-Grief] fires because $\mathsf{IsGriefable}(m, \sigma) \in \mathrm{conjuncts}(D_G)$, emitting the selectorless $\texttt{vm.expectRevert()}$ (any revert); and [Act-Grief] fires because $\mathsf{IsEssential}(m) \in \mathrm{conjuncts}(D_G)$ and $\mathsf{IsGriefable}(m, \sigma) \in \mathrm{conjuncts}(D_G)$, emitting $\texttt{vm.prank}(h_{\mathit{caller}});\; \mathit{victim}.h_m(h_{\mathit{args}})$ with $h_{\mathit{caller}}$ and $h_{\mathit{args}}$ *symbolic*. Under the symbolic-coverage premise — Kontrol holds $h_{\mathit{caller}}$ and $h_{\mathit{args}}$ symbolic and unconstrained over $\mathsf{Address}\times\mathsf{Dom}(m)$ — a passing $\texttt{vm.expectRevert()}$ establishes that the call reverts on *every* feasible path from $\sigma$, i.e. for every caller $a$ and input $x$ there is an error state $\sigma_{\mathit{err}}$ with $\mathsf{FailExec}(a, m(x),\sigma, \sigma_{\mathit{err}})$; this is exactly $\forall a\,\forall x\,\exists\sigma_{\mathit{err}}.\, \mathsf{FailExec}(a, m(x),\sigma,\sigma_{\mathit{err}}) = \mathsf{IsGriefable}(m,\sigma)$, establishing $C^G_2$ ($M_{\tau[\theta]} \models C^G_2$). Because the assertion accepts *any* revert, the revert kind is immaterial under the universal — a $\tt require$ firing for every caller and input bricks the method as effectively as a panic. The conjunct $C^G_1 = \mathsf{IsEssential}(m)$ is a *static* ($\mathcal{P}_0$) fact discharged by Slither at $h_m$ selection and cited as a premise of [Act-Grief]: $\mathsf{IsEssential}(m) \in \mathcal{P}_0$, establishing $C^G_1$; its soundness is the standing Essentiality-identification premise. Hence $M_{\tau[\theta]} \models D_G$, so $M_{\tau[\theta]} \models D_P \lor D_G$. *Engine caveat:* under Forge, or if a $\tt vm.assume$ narrows $h_{\mathit{caller}}$ or $h_{\mathit{args}}$, the run only *samples* the universal $\forall a\,\forall x$; the conclusion then weakens to corroborating evidence rather than a constructive witness, since finitely many sampled $(a,x)$ cannot establish $\mathsf{IsGriefable}$. ✓

**Key observation.** In the panic variant both conjuncts $C^P_1, C^P_2$ are observed atoms read off $\mathcal{P}_1$ (an intercepted $\tt Panic(0x01)$), so the disjunct is witnessed deterministically. In the grief variant the universal conjunct $C^G_2$ is read off a single passing run only because Kontrol's symbolic caller and input cover the entire $\mathsf{Address}\times\mathsf{Dom}(m)$ domain; the static $C^G_1$ is a $\mathcal{P}_0$ fact. The two variants share the tag $v$, which forces all phases into the *same* disjunct, so the unsound cross-pairing is not derivable (cf. the [Template] note). ✓

**Step 4 ([Template]): global assembly.** The [Template] rule at the root is

$$\dfrac{\displaystyle \Phi \vdash H \quad \Phi \vdash^{v}_{\mathit{setUp}} S \quad \Phi \vdash^{v}_{\mathit{assert}} \mathit{AS} \quad \Phi \vdash^{v}_{\mathit{action}} A}{\displaystyle \Phi \vdash \langle H, S, \mathit{AS}, A\rangle} \quad \text{[Template]}$$

with $\Phi = \mathsf{LogicFault}(c)$ and the shared tag $v$ forcing all phase premises into the same disjunct. By Step 1 ([Holes]) and Step 2 ([Pre]) the outer witnesses $m = \theta(h_m)$ and $\sigma$ are fixed, and by Step 3$_P$ (resp. Step 3$_G$) the selected disjunct $D_P$ (resp. $D_G$) is satisfied in $M_{\tau[\theta]}$. Since satisfying either disjunct satisfies the matrix $D_P \lor D_G$, the tuple $\mathcal{W}_P$ (resp. $\mathcal{W}_G$) witnesses the existential prefix and

$$M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle \;\models\; \mathsf{LogicFault}(c). \qquad\square$$

**Scope.** The theorem does *not* claim uniqueness of the witness, nor completeness: if no input panics (panic variant) or some caller/input does not revert (grief variant), the test fails and the theorem does not apply. The two branches differ in their trusted base. The *panic* branch is fully runtime-witnessed and deterministic (Forge or Kontrol), conditional only on the reachability of $\sigma$. The *griefing* branch holds *only under Kontrol and only under the symbolic-coverage premise*, and carries the static Essentiality-identification premise on $\mathsf{IsEssential}(m)$; moreover its conclusion is scoped to the *formula as written* — an essential $m$ reverting for every caller and input at the reachable $\sigma$ — and *not* to the strictly stronger informal notion of a *permanent* denial of service, which (as discussed in the *Residual human judgement* note above) is an explicit side judgement left to the analyst rather than a property the harness decides.
