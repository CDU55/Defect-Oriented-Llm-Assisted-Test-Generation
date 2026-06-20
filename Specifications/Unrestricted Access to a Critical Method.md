# Unrestricted Access to a Critical Method

Unrestricted Access to a Critical Method is a fundamental and highly impactful vulnerability in the smart contract field. The main idea behind it is that smart contracts often contain sensitive methods meant only for specific administrative roles, but fail to properly verify the caller's authorization. This vulnerability occurs when an arbitrary user successfully executes a method that performs a critical operation, even though they are not actually authorized to do so.

The classical example here is a contract with a function designed to modify ownership, mint new tokens, or even invoke $\tt selfdestruct$ to destroy the contract entirely. If these functions lack proper access control guards (like an $\tt onlyOwner$ modifier), a malicious user can simply call the unprotected function. When this happens, the unauthorized execution can easily lead to a permanent takeover of the contract, the manipulation of pricing mechanisms, or a complete loss of funds.

## Specification primitives

Our defect specifications rely on standard Solidity datatypes— $\mathsf{Contract}$, $\mathsf{Method}$, $\mathsf{Address}$, $\mathsf{Env}$(ironment), and $\mathsf{State}$, together with the Booleans $\mathbb{B} = \{\mathit{true}, \mathit{false}\}$. A brief description of the necessary predicates and functions over these types is included in the table below. The evaluation of these primitives is stratified: structural properties are derived statically via Slither, while behavioral properties are verified at runtime via Forge/Kontrol assertions within the LLM-generated test harness.

| Symbol | Semantics |
|--------|-----------|
| ***Static Analysis (Slither)*** | |
| $\texttt{methods}(c)$ | The set of externally-callable functions (entry points) of contract *c*, which includes its public/external functions and the special $\tt receive$ and $\tt fallback$ functions. |
| $\texttt{IsCritical}(m)$ | Holds if method $m$ performs a security-critical operation (e.g., $\tt selfdestruct$, ownership transfer, or minting). |
| $\mathcal{R}$ | The set of access-control roles defined by the contract (e.g., owner, admin, minter). |
| $\texttt{Authorized}(\mathit{Role}, m, \sigma)$ | The set of addresses holding role *Role* for method *m* in state σ, read from the role-granting storage of *c* in σ (e.g., $\tt owner()$). |
| ***Runtime Verification (LLM-generated based on specific template)*** | |
| $\texttt{Exec}(a, m, \sigma, \sigma')$ | Holds if caller *a* invoking *m* in state σ successfully transitions to σ' without reverting. |


## Formal Specification

Unrestricted Access to a Critical Method is defined as the existence of an unauthorised address that the contract nevertheless admits to successfully execute a security-critical method:

$$\begin{aligned}
\mathsf{FaultyAccess}(c) \equiv{} & \exists m \in \mathsf{methods}(c).\ \exists A \in \mathsf{Address}.\ \exists \sigma, \sigma' \in \mathsf{State}.\\
&\mathsf{Exec}(A, m, \sigma, \sigma') \land \mathsf{IsCritical}(m)\\
&\land (\forall \mathit{Role} \in \mathcal{R}.\ A \notin \mathsf{Authorized}(\mathit{Role}, m, \sigma))
\end{aligned}$$

The defect is a *successful unauthorised execution* of a critical method: an address $A$ that no role authorises invokes the security-critical method $m$ and the call completes without reverting. We frame the defect by this observable *outcome* rather than by the *absence of an authorisation gate*: a non-reverting $\mathsf{Exec}$ by an unauthorised $A$ already evidences that the contract's authorisation admitted $A$ on this path, so a separate "the contract admits $A$" predicate would be implied by $\mathsf{Exec}$ and hence redundant. This outcome framing captures flaws in custom modifier logic, uninitialized ownership, or flawed role-delegation, and — unlike an "absence of guard" condition — it correctly still flags a *present-but-buggy* guard that wrongly admits $A$.

## Specific test template design

**Testing Goal** — Verify if critical methods are properly protected by ensuring that unauthorized addresses cannot reach or modify a sensitive contract state.

**Setup** — The framework identifies all *sensitive* methods — such as those modifying ownership, minting tokens, or invoking a self-destruct — using static analysis.

**Fuzzing** — The test declares a fuzzed or symbolic caller address and constrains it to be excluded from every privileged role ($\forall \mathit{Role} \in \mathcal{R}$), ensuring the caller is a strictly unauthorized entity.

**Action** — The harness simulates the transaction from the perspective of the unauthorized caller and attempts to invoke the sensitive method.

**Assertion** — The primary witness is the call *not reverting*: if the sensitive method executes successfully from the unauthorized caller, the access-control logic is confirmed as flawed. An optional state-change check confirms the critical effect but is not the primary witness.

## Template Derivation and LLM Instantiation

The conceptual test design is materialized into a standardized Foundry test template (e.g., $\tt UnrestrictedAccess.t.sol$). To bridge the gap between static analysis and generation, the template embeds explicit $\tt [LLM\_INSTRUCTION]$ comments alongside structural markers for the Setup, Fuzzing, Action, and Assertion phases.

The matrix writes $\mathsf{Exec}$ in its *input-abstracted* form $\mathsf{Exec}(A,m,\sigma,\sigma')$, admissible because the defect — a non-reverting critical call by an unauthorised $A$ — does not depend on the call inputs; the harness realises it by the applied run $\tt victim.h\_m(h\_args)$, whose post-state is unique by functionality of $\mathsf{Exec}$ on $\langle A, m(h_{\mathit{args}}),\sigma\rangle$. The bound post-state $\exists\sigma'$ occurs in no other conjunct; only its *existence* (that the call returned rather than reverted) is the witness.

Each hole is assigned to either Slither or the LLM for resolution, as summarized in the table below.
The specification $\mathsf{FaultyAccess}(c)$ contains four existential witnesses and one universal constraint.
Each existential maps to a typed hole in the template schema:

| Spec witness | Hole | Sort | Resolved by |
|---|---|---|---|
| $\exists m \in \mathsf{methods}(c)$ with $\mathsf{IsCritical}(m)$ | $h_m$ | $\mathsf{Method}$ | Slither ($\mathsf{IsCritical}$ detector) |
| $\exists A \in \mathsf{Address}$ (caller) | $h_{\mathit{caller}}$ | $\mathsf{Address}$ | LLM |
| $\exists \sigma \in \mathsf{State}$ | $h_{\mathit{init}}$ | $\mathsf{State}$ | LLM |
| $\forall \mathit{Role}.\ A \notin \mathsf{Authorized}(\mathit{Role}, m, \sigma)$ | constrains $h_{\mathit{caller}}$ ($\tt vm.assume$) | | LLM / Forge / Kontrol |
| $\exists \sigma' \in \mathsf{State}$ | witnessed by successful execution | | Forge/Kontrol |
| (call well-formedness only) | $h_{\mathit{args}}$ | $\mathsf{InputArgs}$ | LLM |

The post-state $\sigma'$ carries no explicit hole: its *existence* is witnessed at runtime by the call to $h_m$ not reverting, making it an implicit existential that is *verified* rather than *filled*. $\mathsf{IsCritical}(m)$ is established statically by Slither; the optional effect check $\tt assertTrue(h\_eff)$ is an auxiliary runtime confirmation.

Before stating the derivation rules, we record how each conjunct of $\mathsf{FaultyAccess}(c)$ maps to exactly one test phase and its concrete template realization:

| Spec element | Phase | Template realization |
|---|---|---|
| $\exists \sigma \in \mathsf{State}$ *(witness)* | *setUp* | $h_{\mathit{init}}$; $\tt vm.deal(\cdot)$ if payable |
| $\forall \mathit{Role} \in \mathcal{R}.\ A \notin \mathsf{Authorized}(\mathit{Role}, m, \sigma)$ | *setUp* | $\tt vm.assume(h\_caller\ !=\ address(this));$ $\tt vm.assume(h\_caller\ !=\ victim.owner());\ \ldots$ |
| $\exists A \in \mathsf{Address}$ *(witness, caller)* | *action* | $\tt vm.prank(h\_caller)$ (sets $\tt msg.sender$ to $A$) |
| $\mathsf{Exec}(A, m, \sigma, \sigma')$ | *action* | $\tt victim.h\_m()$ (succeeds iff the contract admits $A$) |
| $\mathsf{IsCritical}(m)$ | *action* | cited as a premise of [Act] (cf. $\mathsf{YieldsControl}$ in Reentrancy) and exercised by the action call on $h_m$; *discharged* statically at $h_m$ selection by Slither's $\mathsf{IsCritical}$ detector (a $\mathcal{P}_0$ fact), not observed on the trace. An optional effect check $\tt assertTrue(h\_eff)$ may be emitted in an auxiliary *assert* phase, but it does not discharge the conjunct |

## Derivation Rules for $\vdash$

This section gives a rigorous definition of the relation $\Phi(c) \vdash \tau$, read "defect specification $\Phi$ derives template schema $\tau$". We develop it through the Unrestricted Access running example.

The relation $\Phi(c) \vdash \tau$ is defined by the following six rules.

Witnesses become typed holes:

$$\dfrac{}{\displaystyle \Phi \vdash \bigl\{ h_m : \mathsf{Method},\; h_{\mathit{caller}} : \mathsf{Address},\; h_{\mathit{init}} : \mathsf{State} \bigr\}} \quad \text{[Holes]}$$

The universal role-exclusion conjunct derives the *setUp* phase:

$$\dfrac{\displaystyle (\forall \mathit{Role} \in \mathcal{R}.\ A \notin \mathsf{Authorized}(\mathit{Role}, m, \sigma)) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{setUp}} \left[\begin{array}{l} h_{\mathit{init}};\; \texttt{vm.deal}(\cdot)\ \text{if payable};\; \\ \texttt{vm.assume}(h_{\mathit{caller}} \neq \texttt{address(this)});\; \texttt{vm.assume}(h_{\mathit{caller}} \neq \texttt{victim.owner}()) \end{array}\right]} \quad \text{[Pre]}$$

The caller-witness, execution, and criticality conjuncts derive the *action* phase. The criticality premise $\mathsf{IsCritical}(m)$ is cited here — exactly as Reentrancy's [Act] cites the static $\mathsf{YieldsControl}(c,c',m)$ — so that every conjunct of $\mathsf{FaultyAccess}(c)$ is produced by some phase rule; like $\mathsf{YieldsControl}$, it is *discharged* statically as a $\mathcal{P}_0$ fact (Slither's $\mathsf{IsCritical}$ detector at $h_m$ selection), not observed on the trace:

$$\dfrac{\displaystyle \mathsf{Exec}(A, m, \sigma, \sigma') \in \mathrm{conjuncts}(\Phi) \quad \mathsf{IsCritical}(m) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{action}} \bigl[\texttt{vm.prank}(h_{\mathit{caller}});\; \texttt{victim.}h_m\texttt{()}\bigr]\quad \text{(passes iff not reverting)}} \quad \text{[Act]}$$

The assert phase has two variants. The default [Assrt-None] emits the empty phase ($\varepsilon$): the mandatory witness is the non-reverting call derived by [Act], so no assertion is required.

$$\dfrac{}{\displaystyle \Phi \vdash_{\mathit{assert}} \varepsilon} \quad \text{[Assrt-None]}$$

The optional [Assrt-Eff] instead adds an auxiliary effect check, where $h_{\mathit{eff}} : \mathsf{BoolExpr}$ confirms the critical state change was caused by $h_{\mathit{caller}}$:

$$\dfrac{\displaystyle h_{\mathit{eff}} : \mathsf{BoolExpr}\ \text{(effect predicate for $m$'s criticality flavor)}}{\displaystyle \Phi \vdash_{\mathit{assert}} \bigl[\texttt{assertTrue}(h_{\mathit{eff}})\bigr]} \quad \text{[Assrt-Eff]}$$

Here $h_{\mathit{eff}}$ is instantiated per criticality flavor (e.g., $\tt victim.owner() == h\_caller$ for ownership transfer, $\tt victim.balanceOf(h\_caller) > pre$ for minting, or $\tt address(victim).code.length == 0$ for $\tt selfdestruct$). Neither variant discharges $\mathsf{IsCritical}(m)$ — that conjunct is the static $\mathcal{P}_0$ fact established by Slither at $h_m$ selection and cited in [Act]. The effect predicate lies outside the core hole signature $H$, since the mandatory witness is the non-reverting [Act] call.

All phases combine into the full schema:

$$\dfrac{\displaystyle \Phi \vdash H \qquad \Phi \vdash_{\mathit{setUp}} S \qquad \Phi \vdash_{\mathit{action}} A \qquad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H,\, S,\, A,\, \mathit{AS} \rangle} \quad \text{[Template]}$$

Here $\mathit{AS}$ is the assert phase: by default the empty phase ($\mathit{AS} = \varepsilon$) derived by [Assrt-None], since the mandatory witness is the non-reverting call derived by [Act]; the optional [Assrt-Eff] instead supplies an auxiliary effect check.

**Assumption (Role identification).** Let $\hat{\mathcal{R}}$ be the set of access-control roles inferred from $c$ by Slither and the LLM, and for $\mathit{Role}\in\hat{\mathcal{R}}$ let $\mathsf{Authorized}(\mathit{Role},m,\sigma)$ be its holders in the $\tt setUp$ state $\sigma$. We assume *(i) completeness*, $\mathcal{R}\subseteq\hat{\mathcal{R}}$ (every role the contract's authorisation can consult is identified); *(ii) exclusion*, that $\tt setUp$ fixes $\sigma$ and $A=\theta(h_{\mathit{caller}})$ with $A\notin\mathsf{Authorized}(\mathit{Role},m,\sigma)$ for all $\mathit{Role}\in\hat{\mathcal{R}}$, realised by the caller $\tt vm.assume$s together with state manipulation of the role-granting storage; and *(iii) reachability*, that the chosen $\sigma$ is constructible through $c$'s public interface — deployment (with constructor arguments) followed by public/external calls — rather than fabricated by arbitrary storage writes to otherwise-unreachable slots. Reachability is naturally satisfied in our harness because the test contract is itself the *deployer* of $c$: any state it establishes through deployment and subsequent calls (including role grants available to the deploying party) is by construction a state a legitimate deployer can reach, so the role-storage manipulation used for (ii) is restricted to values the contract's own role-granting functions can produce, not to states no deployer path can set. Under (i)–(iii) the finite $\tt setUp$ exclusions discharge $\forall \mathit{Role}\in\mathcal{R}.\,A\notin\mathsf{Authorized}(\mathit{Role},m,\sigma)$ at a *reachable* state, so a non-reverting unauthorised call is a sound witness for $\mathsf{FaultyAccess}(c)$; an unmodelled privileged role ($\mathcal{R}\not\subseteq\hat{\mathcal{R}}$) is a *false-positive* channel — the more dangerous direction — since the caller $A$ excluded only from $\hat{\mathcal{R}}$ may in fact hold the unmodelled role in $\mathcal{R}\setminus\hat{\mathcal{R}}$, making its call legitimately authorised and the reported "unauthorised" execution not a defect (so the conclusion is relative to $\hat{\mathcal{R}}=\mathcal{R}$); and an unreachable $\sigma$ (violating (iii)) could likewise yield a spurious witness no real transaction can reproduce.

**Assumption (Authorization precision).** Clauses (i)–(iii) above presuppose that, for each inferred role $\mathit{Role}\in\hat{\mathcal{R}}$, Slither correctly identifies the *role-granting storage* and hence the holder set $\mathsf{Authorized}(\mathit{Role},m,\sigma)$ that the contract's own guard consults in $\sigma$. This is an independent precision premise on the static reading of $\mathsf{Authorized}$, distinct from completeness of the role *set* $\hat{\mathcal{R}}$: even with $\mathcal{R}\subseteq\hat{\mathcal{R}}$, a *mis*-located role slot makes the $\tt setUp$ exclusions in (ii) constrain the wrong storage, so the test may exclude $h_{\mathit{caller}}$ from a phantom holder set while the contract still authorises $A$ on the real slot; the unauthorised call then succeeds for a legitimate reason and a *non-vulnerable* contract is flagged — the dangerous false-positive direction. We therefore assume Slither resolves each $\mathsf{Authorized}(\mathit{Role},m,\cdot)$ to the actual role-granting storage of $c$; like the other static $\mathcal{P}_0$ facts, $\mathsf{Authorized}$ is never confirmed on the trace, so this precision is a standing premise of the derivation rather than a property the test establishes.

**Assumption (Criticality identification).** The conjunct $\mathsf{IsCritical}(m)$ is discharged by Slither's $\tt IsCritical$ detector, a heuristic over known security-sensitive operations ($\tt selfdestruct$, ownership transfer, minting, and similar). Its soundness as a witness rests on this detector being *accurate* on $h_m$: an over-broad detector flags a non-critical method (a false positive), while an over-narrow one misses a genuinely critical method (a false negative). We therefore assume the detector correctly classifies the criticality of the selected $h_m$; unlike the runtime conjuncts, $\mathsf{IsCritical}(m)$ is never confirmed on the trace, so this static precision is a standing premise of the derivation rather than a property the test establishes.


## Derived Unrestricted-Access Multi-Shot Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The solidity files are in "../src/". The name of the file is the same as the name of the contract.
// [LLM_INSTRUCTION]: If you need to manipulate private state directly, import StdStorage: 
// import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

// ------------------------------ 
// [Testing Goal] Verify if critical methods are properly protected by ensuring
// that unauthorized addresses cannot reach or modify a sensitive contract state.
// ------------------------------ 

// [LLM_INSTRUCTION]: Name the contract 'TestAccessControl[ContractName]'
contract TestAccessControlTemplate is Test {
    // [LLM_INSTRUCTION]: Use StdStorage if needed for complex state setup: using stdStorage for StdStorage;

    // ------------------------------ 
    // [Setup] Identify and declare the contract under test. The sensitive methods
    // (e.g., modifying ownership, minting tokens, invoking selfdestruct) are the
    // targets for access control validation.
    // ------------------------------ 

    // [LLM_INSTRUCTION]: Declare the contract under test variable
    // UnprotectedSelfdestruct public _contractUnderTest;

    // ------------------------------  [/Setup]

    function setUp() public {
        // ------------------------------ 
        // [Setup] Initialize the contract under test.
        // ------------------------------ 

        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // 1. If constructor parameters are needed, use concrete valid values.
        // 2. If payable, use vm.deal(address(this), amount) before deployment.
        
        // _contractUnderTest = new UnprotectedSelfdestruct();

        // ------------------------------  [/Setup]
    }

    // [LLM_INSTRUCTION]: Add Fuzz/Symbolic arguments.
    // 1. 'caller': The arbitrary address attempting the access.
    // 2. 'fuzzArg': Any arguments required by the function itself.
    // Example: function test_highlightArbitraryUserCanAccess(address caller, uint256 fuzzArg) public {
    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // ------------------------------ 
        // [Fuzzing] Declare a fuzzed/symbolic address (unauthorizedUser) and
        // constrain it using vm.assume to exclude all privileged addresses,
        // ensuring the caller is not part of the authorized set.
        // ------------------------------ 

        // [LLM_INSTRUCTION]: Constrain the 'caller'.
        // 1. Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // 2. Exclude the Zero Address
        vm.assume(caller != address(0));

        // 3. Exclude Foundry Internals (Dynamic)
        // This catches the 'FoundryCheat' address reliably
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // [LLM_INSTRUCTION]: CRITICAL - Exclude ALL privileged roles.
        // Analyze the contract to find ALL addresses that ARE allowed to call this function.
        // You must exclude them so that vm.assume(unauthorizedUser != authorized_address)
        // guarantees the caller is not part of the privileged set.
        // - If `onlyOwner`: exclude owner.
        // - If `msg.sender == vault`: exclude vault.
        // - If `hasRole(DEFAULT_ADMIN_ROLE, msg.sender)`: exclude admins.
        // Example: 
        // vm.assume(caller != _contractUnderTest.owner());

        // [LLM_INSTRUCTION]: Constrain other fuzz args if present.
        // vm.assume(fuzzArg < 100);

        // ------------------------------  [/Fuzzing]

        // ------------------------------ 
        // [Setup] Configure any required pre-conditions (funding, state).
        // ------------------------------ 

        // [LLM_INSTRUCTION]: FUNDING
        // Analyze the function being tested. Does it require sending value (payable) or checking balances?
        // If YES: Fund the caller so they can pay for the value transfer.
        // Example: vm.deal(caller, 100 ether);
        
        // If NO: You can skip funding to keep the test minimal.

        // [LLM_INSTRUCTION]: STATE VARIABLES
        // Does the function require specific state to be reachable? (e.g. contract not paused).
        // Use public setters (Strategy A) or vm.store (Strategy B) here.

        // ------------------------------ [/Setup]

        // ------------------------------ 
        // [Action] Use vm.prank(unauthorizedUser) to simulate the transaction
        // from the unauthorized entity and attempt to invoke the sensitive method.
        // ------------------------------ 

        // Switch context to the arbitrary caller
        vm.prank(caller);

        // ------------------------------  [/Action]

        // ------------------------------ 
        // [Assertion] The primary witness is the call NOT reverting: simply
        // trigger the sensitive method. If it executes successfully without
        // reverting from the unauthorized caller, the access control logic is
        // confirmed as flawed and the test PASSES. An optional state-change
        // check (e.g., the owner variable was modified) corroborates the
        // critical effect but is not the primary witness.
        // ------------------------------ 

        // [LLM_INSTRUCTION]: TRIGGER THE SENSITIVE METHOD
        // Simply call the function. 
        //  If the contract is VULNERABLE (Unprotected): the call SUCCEEDS - test PASSES.
        //  If the contract is SECURE (Protected): the call REVERTS - test FAILS.
        
        // _contractUnderTest.criticalFunction();

        // [LLM_INSTRUCTION]: (Optional) ASSERT STATE CHANGE
        // Check for side effects to confirm the action really happened.
        // If the sensitive method modifies state (e.g., owner, balances), assert
        // that the change occurred, further proving the access control is flawed.
        // Example: assertEq(_contractUnderTest.owner(), caller);

        // ------------------------------ [/Assertion]
    }
}
```

### Rule Application

The derivation $\mathsf{FaultyAccess}(c) \vdash \tau$ proceeds by applying the rules in sequence (a single derivation uses one of the two assert variants). For each step we identify the triggering conjunct(s) from $\mathsf{FaultyAccess}(c)$, state what the rule derives, and map the output to the specific region of the code template above.

A crucial structural difference from the Reentrancy derivation governs the entire analysis: the test **passes** when the call **succeeds** (vulnerability present) and **fails** when the call **reverts** (contract is protected). There is no explicit $\tt assertTrue$ call; the EVM's default behavior — propagating a revert as a test failure — acts as the implicit assertion. The conjunct $\mathsf{Exec}(A, m, \sigma, \sigma')$ is witnessed by the absence of a revert, not by a dedicated harness flag; a non-reverting call by the unauthorised $A$ also evidences that the contract's authorisation admitted $A$.

---

**Step 1 — [Holes]** (no premise)

The axiom fires unconditionally and establishes the hole signature:

$$H = \bigl\{\, h_m : \mathsf{Method},\quad h_{\mathit{caller}} : \mathsf{Address},\quad h_{\mathit{init}} : \mathsf{State} \,\bigr\}$$

Each hole appears in the template as a $\tt [LLM\_INSTRUCTION]$ placeholder:

| Hole | Sort | Stands for | Filled by |
|---|---|---|---|
| $h_m$ | $\mathsf{Method}$ | the victim's sensitive/critical method | Slither ($\mathsf{IsCritical}$ detector) + LLM (e.g., $\tt \_contractUnderTest.criticalFunction()$) |
| $h_{\mathit{caller}}$ | $\mathsf{Address}$ | the arbitrary unauthorized address | LLM (fuzz parameter $\tt caller$) |
| $h_{\mathit{init}}$ | $\mathsf{State}$ | the state-initializing statements in $\tt setUp()$ | LLM (e.g., $\tt \_contractUnderTest = new\ UnprotectedSelfdestruct()$) |

The hole set is strictly smaller than in Reentrancy: there is no $h_{\mathit{reenter}}$ (no callback loop) and no $h_{\mathcal{I}}$ (no invariant expression), because the defect is witnessed by a single non-reverting call rather than by a recursive callback sequence.

---

**Step 2 — [Pre]** fires on $C_1 = (\forall \mathit{Role} \in \mathcal{R}.\ A \notin \mathsf{Authorized}(\mathit{Role}, m, \sigma))$

Triggering conjunct: the universal role-exclusion formula — every role in $\mathcal{R}$ must fail to authorize $A$ for $m$.

Derives:
$$\Phi \vdash_{\mathit{setUp}} \bigl[\,h_{\mathit{init}};\; \texttt{vm.deal}(\cdot)\ \text{if payable};\; \texttt{vm.assume}(h_{\mathit{caller}} \neq \texttt{address(this)});\; \texttt{vm.assume}(h_{\mathit{caller}} \neq \texttt{victim.owner}()) \,\bigr]$$

Template realization — the $\tt [Setup]$ and $\tt [Fuzzing]$ regions:

- In $\tt setUp()$: the $\tt [LLM\_INSTRUCTION]$ for $h_{\mathit{init}}$ instantiates the victim contract (e.g., $\tt \_contractUnderTest = new\ UnprotectedSelfdestruct()$). If the targeted method is payable, $\tt vm.deal(caller,\ 100\ ether)$ funds the caller.
- In the test function: the chain of $\tt vm.assume$ calls enforces the universal conjunct. Standard exclusions ($\tt address(this)$, $\tt address(0)$, $\tt address(vm)$, the console address) handle bookkeeping. The LLM-generated role exclusions — one $\tt vm.assume$ per role in $\mathcal{R}$ — guarantee that the fuzzed $\tt caller$ is strictly unauthorized. Soundness presupposes that Slither and the LLM enumerate $\mathcal{R}$ completely: if a privileged role is missed, the constraint is unsound.

---

**Step 3 — [Act]** fires on $C_2$ and $C_3$

Triggering conjuncts:
- $C_2 = \mathsf{Exec}(A, m, \sigma, \sigma')$ — $m$ executes successfully, transitioning $\sigma$ to $\sigma'$ without reverting; a non-reverting call by the unauthorised $A$ also evidences that the contract's authorisation admitted $A$ on this path.
- $C_3 = \mathsf{IsCritical}(m)$ — cited here (cf. Reentrancy's static $\mathsf{YieldsControl}$ premise in [Act]) so that every conjunct is produced by some phase rule; it is *discharged* statically at $h_m$ selection by Slither, not observed on the trace, and the action call merely exercises the selected critical method.

Derives:
$$\Phi \vdash_{\mathit{action}} \bigl[\,\texttt{vm.prank}(h_{\mathit{caller}});\; \texttt{victim.}h_m\texttt{()}\,\bigr] \quad \text{(passes iff not reverting)}$$

Template realization — the $\tt [Action]$ region:
```solidity
vm.prank(caller);                          // sets msg.sender = h_caller = A
// _contractUnderTest.criticalFunction();  // = victim.h_m() — witnesses C₂
```

This is the central polarity inversion: $\tt vm.prank(h_{\mathit{caller}})$ fixes the caller identity $A$, and the call $\tt victim.h_m()$ witnesses $C_2$ by the absence of a revert: a non-reverting $\mathsf{Exec}$ by the unauthorised $A$ confirms both that the contract admitted $A$ and that the critical operation executed. No explicit success assertion is required. If instead the contract is correctly protected and the call reverts, the EVM propagates the revert as a Foundry test failure — the test itself becomes the falsifier.

---

**Step 4 — [Assrt-None] / [Assrt-Eff]** (assert phase, by default empty)

Conjunct $C_3 = \mathsf{IsCritical}(m)$ is a state-independent property of the method $m$, *discharged* statically by Slither (its $\mathsf{IsCritical}$ detector identifies $h_m$ as critical before the test runs) and *cited* as a premise of [Act] (Step 3). The assert phase therefore does *not* discharge $C_3$: by default [Assrt-None] emits the empty phase $\varepsilon$, since the mandatory witness is the non-reverting call of Step 3. Optionally, [Assrt-Eff] emits an auxiliary effect check confirming the critical effect at runtime:
$$\dfrac{}{\displaystyle \Phi \vdash_{\mathit{assert}} \varepsilon} \quad \text{[Assrt-None]} \qquad\qquad \dfrac{\displaystyle h_{\mathit{eff}} : \mathsf{BoolExpr}}{\displaystyle \Phi \vdash_{\mathit{assert}} \bigl[\,\texttt{assertTrue}(h_{\mathit{eff}})\,\bigr]} \quad \text{[Assrt-Eff]}$$
where $h_{\mathit{eff}}$ is instantiated per criticality flavor (ownership: $\tt victim.owner() == h\_caller$; minting: $\tt victim.balanceOf(h\_caller) > pre$; $\tt selfdestruct$: $\tt address(victim).code.length == 0$).

Template realization — the $\tt [Assertion]$ region (one instantiation of $h_{\mathit{eff}}$):
```solidity
// assertTrue(_contractUnderTest.owner() == caller);  // optional: ownership-flavor effect check h_eff
```

When present, a passing effect check $\tt assertTrue(h\_eff)$ means the critical state change (e.g., ownership transfer, a minted balance, or contract destruction) was indeed caused by the unauthorized $\tt caller$, providing a deterministic runtime confirmation of the effect. The assertion is *optional* because the non-revert in Step 3 already witnesses the vulnerability; the effect check elevates it from a liveness proof to a safety-violation proof by confirming the exact state mutation.

---

**Step 5 — [Template]** assembles all four sub-derivations

All premises of [Template] are now established:

| Premise | Established in |
|---|---|
| $\Phi \vdash H$ | Step 1 |
| $\Phi \vdash_{\mathit{setUp}} S$ | Step 2 |
| $\Phi \vdash_{\mathit{action}} A$ | Step 3 |
| $\Phi \vdash_{\mathit{assert}} AS$ | Step 4 |

Applying [Template] yields $\mathsf{FaultyAccess}(c) \vdash \langle H, S, A, AS \rangle = \tau$, which is exactly the code template above with three open holes for the LLM to fill. The conjuncts $C_1$–$C_3$ of $\mathsf{FaultyAccess}(c)$ map onto the phases of $\tau$ as recorded in the Phase–Conjunct table above ($C_1$ gates *setUp*; $C_2 = \mathsf{Exec}$ and $C_3 = \mathsf{IsCritical}$ are the *action* premises, with $C_3$ discharged statically at $h_m$ selection; the *assert* phase $AS$ defaults to $\varepsilon$), completing the derivation.

Note that unlike Reentrancy, there is no [Cbk] rule: the Unrestricted Access template has no attacker contract and no callback phase, because the exploit is witnessed by a single direct call rather than a recursive loop. The template schema is correspondingly simpler: $\langle H, S, A, AS \rangle$ has four components versus Reentrancy's five $\langle H, S, A, CB, AS \rangle$.

## Soundness of $\vdash$ for $\mathsf{FaultyAccess}(c)$

**Theorem (Soundness of $\vdash$ for $\mathsf{FaultyAccess}(c)$).** Let $\mathsf{FaultyAccess}(c) \vdash \tau$ be derivable by the rules above, let $\tau[\theta]$ be a ground instance of $\tau$ obtained by resolving all holes in $H$ (Slither's $\tt IsCritical$ detector for $h_m$, the LLM for $h_{\mathit{caller}}$, $h_{\mathit{args}}$, and $h_{\mathit{init}}$), and let $M_{\tau[\theta]}$ be the EVM execution trace produced by running $\tau[\theta]$. Assume $\tau[\theta]$ is *non-vacuous* — the *setUp* constraints together with the caller-exclusion $\tt vm.assume$s are jointly satisfiable, so that $M_{\tau[\theta]}$ is a genuine run on which the action call is evaluated — and assume the standing static premises stated above: *Role identification* (i) completeness $\mathcal{R}\subseteq\hat{\mathcal{R}}$, (ii) exclusion, and (iii) reachability of $\sigma$; *Authorization precision*; and *Criticality identification*. Then

$$\tau[\theta] \text{ passes (the unauthorised call does not revert)} \;\Longrightarrow\; M_{\tau[\theta]} \models \mathsf{FaultyAccess}(c).$$

That is, a passing test induces an execution trace $M_{\tau[\theta]}$ that is a model of, hence a *constructive witness* for, the existential statement $\mathsf{FaultyAccess}(c)$. Here $\models$ interprets the specification's atoms on $\mathcal{P}_0/\mathcal{P}_1$ in the usual way: $\mathsf{IsCritical}$ and the holder sets $\mathsf{Authorized}(\mathit{Role},m,\sigma)$ are read off $\mathcal{P}_0 = \mathrm{Slither}(c)$, and the non-reverting execution off the trace $\mathcal{P}_1$.

**Setup.** Recall the unrestricted-access specification, with its three matrix conjuncts labelled:

$$\begin{aligned}
\mathsf{FaultyAccess}(c) \equiv{} &
  \exists m \in \mathsf{methods}(c).\;
  \exists A \in \mathsf{Address}.\;
  \exists \sigma, \sigma' \in \mathsf{State}.\\
  &\underbrace{\mathsf{Exec}(A, m, \sigma, \sigma')}_{C_1} \;\land\;
  \underbrace{\mathsf{IsCritical}(m)}_{C_2} \;\land\;
  \underbrace{\bigl(\forall \mathit{Role} \in \mathcal{R}.\; A \notin \mathsf{Authorized}(\mathit{Role}, m, \sigma)\bigr)}_{C_3}
\end{aligned}$$

The derivation $\mathsf{FaultyAccess}(c) \vdash \tau$ is a flat tree whose leaves are the phase judgements [Holes], [Pre], [Act], and [Assrt-None]/[Assrt-Eff], and whose root is [Template]. By inversion on the derivation rules, we show that each conjunct $C_1, C_2, C_3$ is satisfied in the test-induced model $M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle$, where $\mathcal{S}$ is the underlying many-sorted domain (EVM states, methods, addresses, roles, etc.), $\mathcal{P}_0 = \mathrm{Slither}(c)$ (supplying $\mathsf{IsCritical}$, the inferred role set $\hat{\mathcal{R}}$, and the holder sets $\mathsf{Authorized}$), $\mathcal{P}_1$ is extracted from the EVM trace (the non-reverting execution), and the witness tuple is $\mathcal{W} = (\theta(h_m),\, A,\, \sigma,\, \sigma')$, where $\theta(h_m) = m$ is the chosen critical method, $A = \theta(h_{\mathit{caller}})$ is the unauthorised caller, $\sigma$ is the state established by $h_{\mathit{init}}$ and the *setUp* exclusions, and $\sigma'$ is the post-state of the successful call, read off $\mathcal{P}_1$ (Step 3). The hole $h_{\mathit{args}}$ is a well-formedness placeholder, not a spec witness, so $\mathcal{W}$ collects exactly the four existentials $m, A, \sigma, \sigma'$.

**Step 1 ([Holes]): witnesses are well-typed.** The [Holes] rule establishes the hole signature

$$H = \bigl\{ h_m : \mathsf{Method},\; h_{\mathit{caller}} : \mathsf{Address},\; h_{\mathit{args}} : \mathsf{InputArgs},\; h_{\mathit{init}} : \mathsf{State} \bigr\}$$

with $\mathit{res}(h_m) = \mathsf{Slither}$ and $\mathit{res}(h_{\mathit{caller}}) = \mathit{res}(h_{\mathit{args}}) = \mathit{res}(h_{\mathit{init}}) = \mathsf{LLM}$. By assumption, $\theta(h_m) \in \mathsf{methods}(c)$ with $\mathsf{IsCritical}(\theta(h_m))$ per Slither's $\tt IsCritical$ detector, so $\theta(h_m)$ is a valid existential witness for $m$; and $\theta(h_{\mathit{caller}}), \theta(h_{\mathit{args}}), \theta(h_{\mathit{init}})$ are syntactically valid Solidity, so $\tau[\theta]$ is a type-correct test. The hole $h_{\mathit{args}}$ is a well-formedness placeholder making $\mathit{victim}.h_m(h_{\mathit{args}})$ a syntactically valid call (the empty tuple $\tt ()$ when $m$ is nullary, an admissible tuple otherwise); it is *not* a spec witness, since the defect is input-independent — which caller invokes $m$, not the argument values, is what it turns on. The post-state $\sigma'$ carries no hole; it is witnessed by the successful execution (Step 3).

**Lemma (Hole Typing).** If $\vdash H : \tau$ and $\tau[\theta]$ does not revert on a type error, then $\mathcal{W} = (m, A, \sigma, \sigma')$ is a valid witness candidate for the existential prefix of $\mathsf{FaultyAccess}(c)$. ✓

**Step 2 ([Pre]): conjunct $C_3$ satisfied, state $\sigma$ established.** The [Pre] rule fires because $(\forall \mathit{Role} \in \mathcal{R}.\, A \notin \mathsf{Authorized}(\mathit{Role},m,\sigma)) \in \mathrm{conjuncts}(\mathsf{FaultyAccess}(c))$ and derives the $\tt setUp$ phase

$$h_{\mathit{init}};\; \texttt{vm.deal}(\cdot)\text{ if payable};\; \texttt{vm.assume}(h_{\mathit{caller}} \neq \mathit{address}(\mathit{this}));\; \forall \mathit{Role} \in \hat{\mathcal{R}}.\; \forall a \in \mathsf{Authorized}(\mathit{Role},m,\sigma).\; \texttt{vm.assume}(h_{\mathit{caller}} \neq a),$$

where $h_{\mathit{init}}$ initialises $\sigma$ so that each holder set $\mathsf{Authorized}(\mathit{Role},m,\sigma)$ is finite and $h_{\mathit{caller}} \notin \mathsf{Authorized}(\mathit{Role},m,\sigma)$ for all $\mathit{Role} \in \hat{\mathcal{R}}$. When $\tau[\theta]$ runs, *setUp* establishes $\sigma$ — by the reachability premise (iii), a state constructible through $c$'s public interface (the test contract is itself the deployer of $c$) — and fixes $A = \theta(h_{\mathit{caller}})$ excluded from every *inferred* role: $A \notin \mathsf{Authorized}(\mathit{Role},m,\sigma)$ for all $\mathit{Role} \in \hat{\mathcal{R}}$. The rule operationalises the universal over the inferred role set $\hat{\mathcal{R}}$, whereas $\Phi$ quantifies over the true role set $\mathcal{R}$; under the completeness premise (i) $\mathcal{R} \subseteq \hat{\mathcal{R}}$, the finite conjunction of exclusions over $\hat{\mathcal{R}}$ — and, within each role, over every holder $a \in \mathsf{Authorized}(\mathit{Role},m,\sigma)$, so that multi-holder roles are fully excluded — entails $\forall \mathit{Role} \in \mathcal{R}.\, A \notin \mathsf{Authorized}(\mathit{Role},m,\sigma)$, which establishes $C_3$ ($M_{\tau[\theta]} \models C_3$). Crucially, because $\mathcal{R}$ is *finite* and each holder set is finite, and the exclusions are concrete constraints discharged at *setUp*, this universal is established *decidably* by a finite conjunction — no symbolic exploration of an unbounded domain is required, in contrast to the genuinely unbounded universals of Predictable Random Number Generation and the griefing branch of Assert/Require/Revert Violation. The *Authorization-precision* premise ensures each $\mathsf{Authorized}(\mathit{Role},m,\sigma)$ is read off the actual role-granting storage, so the exclusions constrain the real holder sets rather than phantom slots. ✓

**Step 3 ([Act]): conjuncts $C_1$ and $C_2$ satisfied.** The [Act] rule fires because $\mathsf{Exec}(A,m,\sigma,\sigma') \in \mathrm{conjuncts}(\mathsf{FaultyAccess}(c))$ and $\mathsf{IsCritical}(m) \in \mathrm{conjuncts}(\mathsf{FaultyAccess}(c))$, and derives the $\tt action$ phase $\texttt{vm.prank}(h_{\mathit{caller}});\; \mathit{victim}.h_m(h_{\mathit{args}})$, which passes iff it does not revert. When $\tau[\theta]$ passes, the action call does not revert: $\tt vm.prank$ sets $\mathit{msg.sender} = A = \theta(h_{\mathit{caller}})$, and the call $\mathit{victim}.h_m(h_{\mathit{args}})$ completes, transitioning $\sigma$ to a post-state $\sigma'$. The non-reverting completion is exactly $\mathsf{Exec}(A,m,\sigma,\sigma') \in \mathcal{P}_1$, which establishes $C_1$ ($M_{\tau[\theta]} \models C_1$) — witnessed by the call *not reverting*, not by any harness flag. The existence of $\sigma'$ (the post-state of the successful call) witnesses the bound $\exists\sigma'$, whose particular value is immaterial, since the defect is input-independent and $\mathsf{Exec}$ is functional on the applied triple $\langle A, m(h_{\mathit{args}}), \sigma\rangle$. A successful $\mathsf{Exec}$ by an $A$ that no role authorises simultaneously shows that the contract's authorisation admitted $A$ on this path (otherwise the call would have reverted) and that the critical operation actually executed. The conjunct $C_2 = \mathsf{IsCritical}(m)$ is a *static* ($\mathcal{P}_0$) fact discharged by Slither's $\tt IsCritical$ detector at $h_m$ selection: $\mathsf{IsCritical}(m) \in \mathcal{P}_0$, which establishes $C_2$ ($M_{\tau[\theta]} \models C_2$). It is cited as a premise of [Act] for derivation uniformity — exactly as Reentrancy's [Act] cites the static $\mathsf{YieldsControl}(c,c',m)$ — and exercised by the action call on the selected critical method, but it is never observed on the trace; its soundness is the standing *Criticality-identification* premise. ✓

**Step 4 ([Assrt-None]/[Assrt-Eff]): no residual obligation.** By default the [Assrt-None] rule fires, emitting the empty assert phase $\varepsilon$: the mandatory witness is the non-reverting [Act] call (discharging $C_1$), so no assertion is required to establish any conjunct. Optionally, [Assrt-Eff] adds an auxiliary effect check $\texttt{assertTrue}(h_{\mathit{eff}})$, where $h_{\mathit{eff}}$ confirms the critical state change was caused by $h_{\mathit{caller}}$ (e.g. $\tt victim.owner() == $$h_{\mathit{caller}}$ for ownership transfer); this corroborates that the critical operation took effect but does *not* discharge $\mathsf{IsCritical}(m)$ (a static $\mathcal{P}_0$ fact) and is not the primary witness. Either way, the assert phase introduces no new proof obligation: all three conjuncts are already established by Steps 2–3. ✓

**Key observation.** A non-reverting unauthorised critical call (concretely in Forge, symbolically in Kontrol) is equivalent to the satisfaction of $\mathsf{Exec}(A,m,\sigma,\sigma')$ in $\mathcal{P}_1$ under a caller $A$ excluded from every role at *setUp*; combined with the static $\mathsf{IsCritical}(m) \in \mathcal{P}_0$ and the finite role-exclusion conjunction discharging $C_3$, every conjunct $C_1$–$C_3$ is established. Because $C_3$'s universal is *finite* (over $\mathcal{R}$) and discharged by concrete *setUp* exclusions rather than by sampling an unbounded domain, the conclusion holds under *both* Forge and Kontrol with no symbolic-coverage premise — unlike the genuinely unbounded universals elsewhere. ✓

**Step 5 ([Template]): global assembly.** The [Template] rule at the root of the derivation tree is

$$\dfrac{\displaystyle \Phi \vdash H \quad \Phi \vdash_{\mathit{setUp}} S \quad \Phi \vdash_{\mathit{action}} A \quad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H, S, A, \mathit{AS}\rangle} \quad \text{[Template]}$$

with $\Phi = \mathsf{FaultyAccess}(c)$ and $\mathit{AS} = \varepsilon$ ([Assrt-None]) by default, or the optional effect check ([Assrt-Eff]). By Steps 1–4, each premise is established and each conjunct $C_1, C_2, C_3$ holds in $M_{\tau[\theta]}$, with $C_3$ covered by *setUp* and $C_1, C_2$ by *action*. Since $\mathcal{W} = (\theta(h_m), A, \sigma, \sigma')$ witnesses all four existentials — $\theta(h_m) = m$ the critical method selected by Slither, $A = \theta(h_{\mathit{caller}})$ the unauthorised caller, $\sigma$ the reachable *setUp* state, and $\sigma'$ the post-state of the successful call extracted from the trace — all conjuncts hold simultaneously under $(\mathcal{P}_0, \mathcal{P}_1, \mathcal{W})$:

$$M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle \;\models\; \mathsf{FaultyAccess}(c). \qquad\square$$

**Scope.** The theorem does *not* claim that $A$ or $\sigma$ are unique witnesses, nor does it assert completeness: a protected contract — one whose call reverts for every excluded caller — yields a failing test, and the theorem does not apply. Soundness is conditional on the three premises governing the static reading. *Role completeness* ($\mathcal{R} \subseteq \hat{\mathcal{R}}$) is the dangerous false-positive channel: an unmodelled privileged role leaves $C_3$ only partially constrained, and a caller $A$ excluded from $\hat{\mathcal{R}}$ may legitimately hold a role in $\mathcal{R} \setminus \hat{\mathcal{R}}$, making the reported "unauthorised" execution no defect — so the conclusion is relative to $\hat{\mathcal{R}} = \mathcal{R}$. *Authorization precision* guards against a mis-located role slot making the *setUp* exclusions constrain phantom storage, and *Criticality identification* against an over-broad detector flagging a non-critical method. The *reachability* premise (iii) rules out spurious witnesses at a fabricated, unreachable $\sigma$. Under these premises the finite universal $\forall \mathit{Role} \in \mathcal{R}$ is discharged decidably by the *setUp* exclusions, so — unlike Predictable Random Number Generation and the griefing branch of Assert/Require/Revert Violation — no symbolic-coverage premise is needed and the conclusion holds under Forge and Kontrol alike.
