# Division by Zero

A smart contract is vulnerable to division-by-zero if it performs an arithmetic operation (such as division or modulo) where the divisor is not guaranteed to be non-zero and can be influenced by external input, attacker-controlled state, or unpredictable environment conditions. By triggering a division-by-zero error, an attacker can force a contract to revert its logic at critical points. This can lead to severe Denial-of-Service (DoS) conditions, such as blocking withdrawals, halting token transfer flows, or preventing liquidation logic, auctions, and reward distributions.

## Specification primitives

Our defect specifications rely on standard Solidity datatypes— $\tt Contract$, $\tt Method$, $\tt Address$, $\tt Env$(ironment), and $\tt State$. A brief description of the necessary predicates and functions over these types is included in the table below. The evaluation of these primitives is stratified: structural properties are derived statically via Slither, while behavioral properties are verified at runtime via Forge/Kontrol assertions within the LLM-generated test harness.

| Symbol | Semantics |
|--------|-----------|
| ***Static Analysis (Slither)*** | |
| $\texttt{methods}(c)$ | The set of externally-callable functions (entry points) of contract *c*, which includes its public/external functions and the special $\tt receive$ and $\tt fallback$ functions. |
| $\mathsf{Dom}(m)$ | The domain of admissible input arguments of method $m$ (its parameter types). The *domain* is a static Slither fact, whereas the witnessing *element* $\mathit{args} \in \mathsf{Dom}(m)$ is resolved dynamically (symbolic under Kontrol). |
| $\mathsf{Denom}(m)$ | The set of denominator subexpressions of the divisions/modulo operations occurring in $m$, extracted by Slither: $\mathsf{Denom}(m) \in \mathsf{Set}\langle \mathsf{Dom}(m) \times \mathsf{State} \to \mathbb{Z}\rangle$; the witnessing $d$ is the specific denominator the candidate division divides by. |
| $\mathsf{srcs}(m)$ | The syntactic data-flow *source set* of $m$: its formal-parameter symbols (the "args" sources) together with the contract-state variables (the "state" sources) read by $m$. A static, value-independent set computed by Slither, distinct from the runtime witness values bound by $\exists\mathit{args}\in\mathsf{Dom}(m)$ and $\exists\sigma\in\mathsf{State}$. |
| $\texttt{Influence}(S, e)$ | Holds if the expression $e$ is data-dependent on the source set $S$ — a *value-independent* static data-flow predicate over *syntactic* arguments ($S$ a set of program sources, $e$ an expression over them), reused for Predictable Random Number Generation. For Division by Zero it is instantiated as $\texttt{Influence}(\mathsf{srcs}(m), d)$, flagging that the chosen denominator expression $d$ is non-constant. |
| ***Runtime Verification (LLM-generated based on specific template)*** | |
| $\mathsf{FailExec}(a, m(\mathit{args}), \sigma, \sigma_{\mathit{err}})$ | (Shared with Assert/Require/Revert Violation.) Holds if caller $a$ invoking $m$ with arguments $\mathit{args}$ in state $\sigma$ reverts, producing the error state $\sigma_{\mathit{err}}$. Here it witnesses that the run actually reaches and executes the division. |
| $\mathsf{IsPanic}(\sigma_{\mathit{err}}, p)$ | (Shared with Assert/Require/Revert Violation.) Holds if the revert in $\sigma_{\mathit{err}}$ is a Solidity Panic (0.8.x) with code $p$; for Division by Zero $p = \mathsf{P_{div0}} \equiv \tt 0x12$ (division or modulo by zero). |


## Formal Specification

Division by Zero is defined as the existence of a method $m$ in which some denominator expression $d$, influenceable by the method's variable data, can be driven to zero on a reachable path:

$$\begin{aligned}
\mathsf{DivZero}(c) \equiv {} & \exists m \in \mathsf{methods}(c).\ \exists \sigma \in \mathsf{State}.\ \exists \mathit{args} \in \mathsf{Dom}(m).\ \exists d \in \mathsf{Denom}(m). \\
&\exists a \in \mathsf{Address}.\ \exists \sigma_{\mathit{err}} \in \mathsf{State}.\ \mathsf{Influence}(\mathsf{srcs}(m), d) \land (d(\mathit{args}, \sigma) = 0) \land {}\\
&\mathsf{FailExec}(a, m(\mathit{args}), \sigma, \sigma_{\mathit{err}}) \land \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}})
\end{aligned}$$

where $\mathsf{Denom}(m)$ (see the primitives table) may contain several denominators, so the existential $\exists d \in \mathsf{Denom}(m)$ selects the particular denominator driven to zero; $d$ is a genuine witness, not a quantity determined by $m$ alone. The state sources in $\mathsf{srcs}(m)$ subsume the block environment ($\tt block.timestamp$, $\tt block.number$, and the other manipulable block fields, read at $\sigma$'s block context), so an environment-driven denominator — e.g. $\tt x\ \%\ block.timestamp$ — is covered by the state source; the informal "unpredictable environment conditions" clause of the domain model thus maps onto the state component of $\mathsf{srcs}(m)$, and no separate $\mathsf{Env}$ source argument is needed for this defect. A division by zero is a defect regardless of *who* can trigger it, so the specification deliberately does not condition on attacker controllability. The conjunct $d(\mathit{args},\sigma) = 0$ is the *cause*; the execution pair $\mathsf{FailExec}(a, m(\mathit{args}), \sigma, \sigma_{\mathit{err}}) \land \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}})$ is the *observed defect outcome* — the run of $m$ that actually reaches the division and reverts with a $\tt 0x12$ panic. Including the execution pair in the matrix — rather than leaving reachability to the harness — makes $M \models \mathsf{DivZero}(c)$ entail a genuine division by zero *on a real run*, not merely a denominator that *could* be zero on a dead or guarded branch; it mirrors the $\mathsf{FailExec} \land \mathsf{IsPanic}$ outcome predicate of Assert/Require/Revert Violation. The EVM cannot raise the division-by-zero panic on a division it never executed, so the captured $\tt 0x12$ jointly certifies $d(\mathit{args},\sigma)=0$ and the reachability of that division *from* $\sigma$. Guard-absence need not be stated as a separate conjunct either: a witnessing input reaching the division with $d = 0$ exists *iff* no effective guard blocks that path, since any $\texttt{require}(d \neq 0)$ along the path would surface as a path constraint making $d = 0$ unsatisfiable. The reachable-zero conjunct therefore already subsumes the absence of an effective guard — and, unlike a syntactic "no guard exists" condition, it correctly still flags a division reachable through a *present-but-buggy* guard.

**Assumption (Denominator extraction).** The witness $d$ is fixed at $h_D$ from the set $\mathsf{Denom}(m)$ returned by Slither. Its soundness rests on this extraction being *complete* — every division/modulo subexpression of $m$ is in $\mathsf{Denom}(m)$ — and *exact* — each extracted $d$ is the precise denominator operand of its operation, not an over- or under-sliced expression. An *incomplete* extraction (a missed division) yields a false negative; a *mis-sliced* $d$ would let the static $\mathsf{Influence}(\mathsf{srcs}(m),d)$ be confirmed for an expression other than the one the runtime $\tt Panic(0x12)$ actually fires on, breaking the shared-witness reading of $\exists d$. We therefore assume Slither both enumerates $\mathsf{Denom}(m)$ completely and slices each $d$ exactly; like the other static $\mathcal{P}_0$ facts, $\mathsf{Denom}(m)$ is never confirmed on the trace, so this is a standing premise. When $m$ contains several divisions, soundness of the joint witness additionally requires that the captured $\tt 0x12$ originate from $h_D$ rather than another denominator; this is discharged by the **[Ctrl]** rule (above).

**Assumption (Dependence precision).** The conjunct $\mathsf{Influence}(\mathsf{srcs}(m), d)$ is discharged by Slither's static data-flow analysis over $h_D$. Its soundness rests on this analysis being *accurate* on the chosen $d$: an *over*-approximation reports a spurious dependence and admits a denominator that is in fact constant (a false positive), while an *under*-approximation misses a genuine dependence and rejects an influenceable denominator (a false negative). We therefore assume the data-flow analysis correctly decides the dependence of the selected $d$ on $\mathsf{srcs}(m)$; like the other static $\mathcal{P}_0$ conjuncts, $\mathsf{Influence}$ is never confirmed on the trace, so this precision is a standing premise. (The same premise governs the reuse of $\mathsf{Influence}$ in Predictable Random Number Generation.)

**Convention (Reachability of $\sigma$).** The captured $\tt 0x12$ certifies that the division is reached and executed *from* $\sigma$ with $d(\mathit{args},\sigma)=0$, and — by the guard-subsumption above — that no effective guard *within $m$* blocks that path; it does *not* by itself certify that $\sigma$ is a genuine state. We therefore require $\sigma$ to be *reachable* through $c$'s public interface: constructed by deployment, public setters, and the chosen arguments. Storage cheatcodes ($\tt vm.store$/$\tt stdstore$) may be used only as a *shortcut* for such a state — setting storage to values some public call sequence of $c$ could itself produce — never to fabricate an otherwise-unreachable configuration (e.g. a denominator that a setter's $\tt require(x != 0)$ keeps non-zero, which storage manipulation must not bypass). Under this convention a captured $\tt 0x12$ witnesses a division by zero reachable on a real transaction, not an artefact of a fabricated state.

## Specific test template design

**Testing Goal** — Identify if an external actor can influence a denominator to zero without passing through a semantic guard, such as a $\tt require$ statement.

**Setup** — The LLM identifies arithmetic operations where the denominator is derived from user-supplied fuzzed parameters or mutable contract state variables.

**Control Analysis** — The harness leverages symbolic execution via Kontrol to solve for the path constraint $\tt DenominatorExpression == 0$, attempting to find a concrete value that triggers the fault.

**Action** — If the symbolic solver identifies a satisfying input, the harness executes the target method $m$ symbolically under Kontrol (or concretely in Forge on the solved inputs) to confirm reachability.

**Assertion** — The test employs a $\tt try/catch$ block to intercept the specific Solidity Panic code $\tt 0x12$ (division by zero). If the revert occurs at the division operation rather than a preceding guard, an influenceable, unguarded zero-able denominator — a witness to $\mathsf{DivZero}(c)$ — is flagged.

## Template Derivation and LLM Instantiation

The conceptual test design is materialized into a standardized Foundry test template (e.g., $\tt DivisionByZero.t.sol$). To bridge the gap between static analysis and generation, the template embeds explicit $\tt [LLM\_INSTRUCTION]$ comments alongside structural markers for the Setup, Control Analysis, Action, and Assertion phases.

Each hole is assigned to either Slither or the LLM (or Kontrol) for resolution, as summarized in the table below.
The specification $\mathsf{DivZero}(c)$ contains four existential witnesses.
Each maps to a typed hole in the template schema:

| Spec witness | Hole | Sort | Resolved by |
|---|---|---|---|
| $\exists m \in \mathsf{methods}(c)$ | $h_m$ | $\mathsf{Method}$ | Slither |
| $\exists d \in \mathsf{Denom}(m)$: chosen denominator | $h_D$ | $\mathsf{ArithExpr}$ | Slither |
| $\exists \mathit{args}\ \text{s.t.}\ d(\mathit{args},\sigma)=0$ | $h_{\mathit{args}}$ | $\mathsf{InputArgs}$ | Kontrol (symbolic) |
| $\exists a \in \mathsf{Address}$ (caller) | default caller (test contract) | | --- |
| $\exists \sigma_{\mathit{err}} \in \mathsf{State}$ ($\tt 0x12$ panic state) | witnessed at runtime | | Forge/Kontrol |
| $\exists \sigma \in \mathsf{State}$ | $h_{\mathit{init}}$ | $\mathsf{State}$ | LLM |

Note: $h_D$ realizes the chosen denominator witness $d \in \mathsf{Denom}(m)$ — Slither selects the candidate division and extracts its denominator subexpression, fixing the $\exists d$ witness. The caller existential $\exists a \in \mathsf{Address}$ carries no discriminating content — a $\tt Panic(0x12)$ is raised by the division itself, independently of $\mathit{msg.sender}$ — so it is witnessed by the default caller and retained only for the uniform $\mathsf{FailExec}$ convention.

Before stating the derivation rules, we record how each conjunct of $\mathsf{DivZero}(c)$ maps to exactly one test phase and its concrete template realization:

| Spec element | Phase | Template realization |
|---|---|---|
| $\exists \sigma \in \mathsf{State}$ *(witness)* | *setUp* | $h_{\mathit{init}}$; setters to reach the vulnerable path |
| $\mathsf{Influence}(\mathsf{srcs}(m), d)$ | *setUp* | static data-dependence confirmed by Slither (no hole); inputs are left symbolic so Kontrol explores the full domain |
| $d(\mathit{args},\sigma) = 0$ | *ctrl* | Kontrol solves path constraint $h_D = 0 \land \bigwedge_{d' \prec h_D} d' \neq 0$ on a feasible path to the division (the preceding-denominator clause pins the captured $\tt 0x12$ to $h_D$; a solution exists only if no effective guard blocks it) |
| $\mathsf{FailExec}(a, m(\mathit{args}),\sigma,\sigma_{\mathit{err}})$ | *action* | $\tt try\ victim.h\_m(h\_args)\ \{\}\ catch\ Panic(err)\{...\}\ catch\ \{\}$ |
| $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}})$ | *assert* | $\tt if\ (err == 0x12)\ \{\ revert("DivZero");\ \}$ |

## Derivation Rules for $\vdash$

This section gives a rigorous definition of the relation $\Phi(c) \vdash \tau$, read "defect specification $\Phi$ derives template schema $\tau$". We develop it through the Division by Zero running example.

The relation $\Phi(c) \vdash \tau$ is defined by the following six rules.

Witnesses become typed holes:

$$\dfrac{}{\displaystyle \Phi \vdash \bigl\{ h_m : \mathsf{Method},\; h_D : \mathsf{ArithExpr},\; h_{\mathit{args}} : \mathsf{InputArgs},\; h_{\mathit{init}} : \mathsf{State} \bigr\}} \quad \text{[Holes]}$$

Preconditions $(\exists \sigma \in \mathsf{State})$ and $\mathsf{Influence}(\mathsf{srcs}(m), d)$ derive the *setUp* phase:

$$\dfrac{\displaystyle \sigma \in \mathsf{State}\ \text{existential witness of}\ \Phi \quad \mathsf{Influence}(\mathsf{srcs}(m), d) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{setUp}} \bigl[\, h_{\mathit{init}} \,\bigr]} \quad \text{[Pre]}$$

Control-analysis conditions derive the *ctrl* phase:

$$\dfrac{\displaystyle (d(\mathit{args},\sigma)=0) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{ctrl}} [\text{Kontrol solves: } h_D = 0 \land \textstyle\bigwedge_{d' \prec h_D} d'(\mathit{args},\sigma) \neq 0 \text{ on path to division}]} \quad \text{[Ctrl]}$$

Here $d' \prec h_D$ ranges over the denominators of $\mathsf{Denom}(m)$ evaluated *before* $h_D$ on the chosen path; conjoining $\bigwedge_{d' \prec h_D} d'(\mathit{args},\sigma) \neq 0$ forces $h_D$ to be the *first* zero denominator reached, so the captured $\tt Panic(0x12)$ provably originates from $h_D$. When $\mathsf{Denom}(m)$ is a singleton the conjunction is empty and the constraint reduces to $h_D = 0$.

Control-analysis result derives the *action* phase:

$$\dfrac{\displaystyle \Phi \vdash_{\mathit{ctrl}} C \quad \mathsf{FailExec}(a, m(\mathit{args}),\sigma,\sigma_{\mathit{err}}) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{action}} \bigl[\,\texttt{try}\ \mathit{victim}.h_m(h_{\mathit{args}})\ \{\}\ \texttt{catch Panic(uint256 err)}\{\ldots\}\ \texttt{catch}\ \{\}\,\bigr]} \quad \text{[Act]}$$

The reachable-zero conjunct derives the *assert* phase:

$$\dfrac{\displaystyle \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}}) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{assert}} \bigl[\,\texttt{if}\ (\mathit{err} == \texttt{0x12})\ \texttt{revert("DivZero");}\,\bigr]} \quad \text{[Assrt]}$$

All phases combine into the full schema:

$$\dfrac{\displaystyle \Phi \vdash H \qquad \Phi \vdash_{\mathit{setUp}} S \qquad \Phi \vdash_{\mathit{ctrl}} C \qquad \Phi \vdash_{\mathit{action}} A \qquad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H,\, S,\, C,\, A,\, \mathit{AS} \rangle} \quad \text{[Template]}$$


## Derived Division-by-Zero Multi-Shot Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, stdError} from "../lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The solidity files are in "../src/". The name of the file is the same as the name of the contract.

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Identify if an external actor can influence a denominator to
// zero without passing through a semantic guard (e.g., a require statement).
// This identifies the Control Gap—when a denominator is computable from user
// input or fuzzed state and lacks a "require" check, leading to potential DoS
// on critical arithmetic.
// ═══════════════════════════════════════════════════════════════════════════════

// [LLM_INSTRUCTION]: Name the contract 'TestDivisionByZero[ContractName]'
contract TestDivisionByZeroTemplate is Test {
    // [LLM_INSTRUCTION]: Use StdStorage if needed for complex state setup: using stdStorage for StdStorage;

    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Declare the contract under test. Identify arithmetic operations
    // where the denominator is derived from user-supplied fuzzed parameters or
    // mutable contract state variables.
    // ─────────────────────────────────────────────────────────────────────────

    // [LLM_INSTRUCTION]: Declare the contract under test variable
    // DivideByZeroMinimal public _contractUnderTest;

    // ─────────────────────────────────────────────────────────────── [/Setup]

    function setUp() public {
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Initialize the contract under test.
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // _contractUnderTest = new DivideByZeroMinimal();

        // ───────────────────────────────────────────────────────── [/Setup]
    }

    // [LLM_INSTRUCTION]: Analyze the method being tested.
    // 1. If it accepts arguments, ADD them to this function signature to enable Fuzzing.
    // Example: function test_highlightThrowsDivisionByZeroException(uint256 amount) public {
    function test_highlightThrowsDivisionByZeroException() public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain fuzz/symbolic inputs and configure pre-conditions.
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: Inputs are left symbolic; Kontrol explores the full
        // value domain, so no blanket range bound is needed. Add a vm.assume only
        // to encode a genuine, contract-specific precondition.

        // [LLM_INSTRUCTION]: Set up the state required to reach the vulnerable code.
        // _contractUnderTest.setVal(fuzzArg);

        // ───────────────────────────────────────────────────────── [/Setup]

        // ─────────────────────────────────────────────────────────────────────
        // [Control Analysis] Leverage symbolic execution (Kontrol) to solve
        // for the path constraint DenominatorExpression == 0, attempting to
        // find a concrete value that triggers the fault.
        // ─────────────────────────────────────────────────────────────────────

        // [LLM_INSTRUCTION]: The symbolic solver will attempt to find inputs
        // where the denominator evaluates to zero. If a satisfying assignment
        // is found, the test proceeds to execute the target method with those
        // specific inputs.

        // ─────────────────────────────────────────────────── [/Control Analysis]

        // ─────────────────────────────────────────────────────────────────────
        // [Action] Execute the target method with the identified inputs to
        // confirm reachability of the division-by-zero fault.
        // ─────────────────────────────────────────────────────────────────────

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] Use a try/catch block to intercept the specific Solidity
        // Panic code 0x12 (division by zero). If the revert occurs at the
        // division operation rather than a preceding guard, a Control Gap is
        // formally flagged.
        // ─────────────────────────────────────────────────────────────────────
        
        try _contractUnderTest.methodName(/* [LLM_INSTRUCTION]: Replace 'methodName' with the vulnerable method and insert its arguments here */) {
            // [LLM_INSTRUCTION]: Case: Execution Succeeded. 
            // If the test MUST fail on division by zero, we do nothing here (pass).
        } 
        catch Panic(uint256 errorCode) {
            // Panic Code 0x12 = Division or Modulo by Zero
            if (errorCode == 0x12) {
                console2.log("--------------------------------------------------");
                console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
                
                // [LLM_INSTRUCTION]: Log relevant variables to debug the crash
                // console2.log(" Input Amount:", amount);
                
                console2.log("--------------------------------------------------");

                // [LLM_INSTRUCTION]: Force the test to fail. 
                // This stops the Fuzzer and displays the logs immediately.
                revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
            }
        } 
        catch {
            // [LLM_INSTRUCTION]: Catch other unrelated errors (e.g., standard reverts) and ignore them.
        }

        // ─────────────────────────────────────────────────────── [/Action]

        // ────────────────────────────────────────────────────── [/Assertion]
    }
}
```

### Rule Application

The derivation $\mathsf{DivZero}(c) \vdash \tau$ proceeds by applying the six rules in sequence. For each step we identify the triggering conjunct(s) from $\mathsf{DivZero}(c)$, state what the rule derives, and map the output to the specific region of the code template above.

---

**Step 1 — [Holes]** (no premise)

The axiom fires unconditionally and establishes the hole signature:

$$H = \bigl\{\, h_m : \mathsf{Method},\quad h_D : \mathsf{ArithExpr},\quad h_{\mathit{args}} : \mathsf{InputArgs},\quad h_{\mathit{init}} : \mathsf{State} \,\bigr\}$$

Each hole appears in the template as a $\tt [LLM\_INSTRUCTION]$ placeholder:

| Hole | Sort | Stands for | Filled by |
|---|---|---|---|
| $h_m$ | $\tt Method$ | the vulnerable method containing the division | Slither (e.g., $\tt \_contractUnderTest.methodName$) |
| $h_D$ | $\tt ArithExpr$ | the denominator subexpression extracted from $m$ | Slither (e.g., $\tt amount$ or $\tt totalSupply - reserved$) |
| $h_{\mathit{args}}$ | $\tt InputArgs$ | concrete inputs satisfying $h_D = 0$ | Kontrol (symbolic execution) |
| $h_{\mathit{init}}$ | $\tt State$ | the state-initializing statements in $\tt setUp()$ | LLM (e.g., $\tt \_contractUnderTest = new\ VulnerableContract()$) |

---

**Step 2 — [Pre]** fires on $C_1$ and $C_2$

Triggering conjuncts:
- $C_1 = (\exists \sigma \in \mathsf{State}) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$ — there exists a reachable state from which the vulnerable path can be taken.
- $C_2 = \mathsf{Influence}(\mathsf{srcs}(m), d) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$ — the chosen denominator is data-dependent on the inputs or the state.

Derives:
$$\Phi \vdash_{\mathit{setUp}} \bigl[\, h_{\mathit{init}};\; \texttt{vm.assume}(h_{\mathit{args}} \leq \texttt{type(uint128).max}) \,\bigr]$$

Template realization — the $\tt [Setup]$ regions cover two locations:

- In $\tt setUp()$: the $\tt [LLM\_INSTRUCTION]$ for $h_{\mathit{init}}$ instantiates the victim (e.g., $\tt \_contractUnderTest = new\ DivideByZeroMinimal()$), establishing the initial state $\sigma$.
- In $\tt test\_highlightThrowsDivisionByZeroException()$: $\tt vm.assume(amount \leq type(uint128).max)$ constrains the fuzz/symbolic variable so that $\mathsf{Influence}(\mathsf{srcs}(m), d)$ holds (the fuzzed input reaches $h_D$) while preventing spurious arithmetic overflow. Any setter calls (e.g., $\tt \_contractUnderTest.setVal(fuzzArg)$) establish additional state required to make the vulnerable path reachable.

---

**Step 3 — [Ctrl]** fires on $C_3$

Triggering conjunct:
- $C_3 = (d(\mathit{args},\sigma) = 0) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$ — there exist inputs driving the chosen denominator to zero on a feasible path. A satisfying assignment for $h_D = 0$ exists **iff** no effective guard blocks that path (any $\tt require(d \neq 0)$ would make $h_D = 0$ unsatisfiable), so the reachable-zero conjunct already subsumes guard-absence — no separate $\mathsf{Logic}(d \neq 0) = \varnothing$ conjunct is needed.

Derives:
$$\Phi \vdash_{\mathit{ctrl}} [\text{Kontrol solves: } h_D = 0 \text{ on path to division}]$$

Template realization — the $\tt [Control\ Analysis]$ region:

```solidity
// [LLM_INSTRUCTION]: The symbolic solver will attempt to find inputs
// where the denominator evaluates to zero. If a satisfying assignment
// is found, the test proceeds to execute the target method with those
// specific inputs.
```

Kontrol receives the path condition accumulated through $\tt setUp$ and $\tt vm.assume$, then adds the constraint $h_D = 0$ (where $h_D$ is the denominator subexpression Slither extracted from $h_m$). If a satisfying model exists, Kontrol produces the concrete witness $h_{\mathit{args}}$ that will be used in the action phase. Satisfiability already entails that no $\tt require(h\_D != 0)$ intercepts the path (such a guard would make $h_D = 0$ unsatisfiable), so the EVM reaches the division instruction with $h_D = 0$.

---

**Step 4 — [Act]** fires on the *ctrl* derivation $C$ and the execution conjunct $C_4$

Triggering premises: $\Phi \vdash_{\mathit{ctrl}} C$ — Kontrol has produced a satisfying input for $h_D = 0$ — together with $C_4 = \mathsf{FailExec}(a, m(\mathit{args}), \sigma, \sigma_{\mathit{err}}) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$, the observed reverting run that witnesses the division is actually reached and executed.

Derives:
$$\Phi \vdash_{\mathit{action}} \bigl[\,\texttt{try}\ \mathit{victim}.h_m(h_{\mathit{args}})\ \{\}\ \texttt{catch Panic(uint256 err)}\{\ldots\}\ \texttt{catch}\ \{\}\,\bigr]$$

Template realization — the $\tt [Action]$ region in $\tt test\_highlightThrowsDivisionByZeroException()$:

```solidity
try _contractUnderTest.methodName(/* h_args inserted here */) {
    // Case: Execution Succeeded — no division by zero on this path.
} 
catch Panic(uint256 errorCode) {
    ...
} 
catch {
    // Catch other unrelated errors and ignore them.
}
```

The $\tt try$ block executes $\mathit{victim}.h_m(h_{\mathit{args}})$ with the zero-denominator witness. Because $h_D$ evaluates to $0$ and no guard intercepts, the EVM raises a Panic(0x12) at the division instruction, causing the outer $\tt catch\ Panic$ branch to fire — this is the run recorded by $C_4 = \mathsf{FailExec}(a, m(\mathit{args}), \sigma, \sigma_{\mathit{err}})$, with $\sigma_{\mathit{err}}$ the resulting error state. The bare $\tt catch$ absorbs unrelated reverts to prevent false positives.

---

**Step 5 — [Assrt]** fires on $C_5$

Triggering conjunct: $C_5 = \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}}) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$ — the captured Panic(0x12) confirms the division was reached with a zero denominator; by guard-subsumption the revert came from the division itself, not from a preceding guard.

Derives:
$$\Phi \vdash_{\mathit{assert}} \bigl[\,\texttt{if}\ (\mathit{err} == \texttt{0x12})\ \texttt{revert("DivZero");}\,\bigr]$$

Template realization — the $\tt [Assertion]$ region inside $\tt catch\ Panic$:

```solidity
if (errorCode == 0x12) {
    console2.log("--------------------------------------------------");
    console2.log(" [!] DIVISION BY ZERO FOUND (Control Gap)");
    // console2.log(" Input Amount:", amount);
    console2.log("--------------------------------------------------");
    revert("Division by Zero Detected — Control Gap flagged (Logs Printed)");
}
```

Panic code $\tt 0x12$ is the EVM's signal for division or modulo by zero. Checking $\mathit{err} == \tt 0x12$ distinguishes a true division-by-zero Panic from other Panic codes (e.g., $\tt 0x11$ for arithmetic overflow). The explicit $\tt revert$ in response halts the fuzzer run and surfaces the confirming log output. Because reaching $h_D = 0$ on a feasible path already entails that no $\tt require$ guard fired first, a $\tt 0x12$ Panic is proof that the control gap — the missing $d \neq 0$ check — was reached.

---

**Step 6 — [Template]** assembles all five sub-derivations

All premises of [Template] are now established:

| Premise | Established in |
|---|---|
| $\Phi \vdash H$ | Step 1 |
| $\Phi \vdash_{\mathit{setUp}} S$ | Step 2 |
| $\Phi \vdash_{\mathit{ctrl}} C$ | Step 3 |
| $\Phi \vdash_{\mathit{action}} A$ | Step 4 |
| $\Phi \vdash_{\mathit{assert}} \mathit{AS}$ | Step 5 |

Applying [Template] yields $\mathsf{DivZero}(c) \vdash \langle H, S, C, A, \mathit{AS} \rangle = \tau$, which is exactly the code template above with four open holes for Slither, Kontrol, and the LLM to fill. The conjuncts of $\mathsf{DivZero}(c)$ map onto the five phases of $\tau$ as recorded in the Phase–Conjunct table above, though not bijectively: the *setUp* and *ctrl* phases discharge the structural conjuncts $C_1$–$C_3$ ($\exists\sigma$, $\mathsf{Influence}$, $d(\mathit{args},\sigma)=0$), while the *action* and *assert* phases witness the execution pair $C_4 = \mathsf{FailExec}(a, m(\mathit{args}),\sigma,\sigma_{\mathit{err}})$ and $C_5 = \mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}})$, completing the derivation. The key structural difference from Reentrancy is the presence of a dedicated *ctrl* phase: rather than witnessing the defect through a runtime callback counter, the defect manifests as a Panic(0x12) raised by the EVM's division instruction itself, and its zero-denominator input is constructed constructively by Kontrol before execution.

## Soundness of $\vdash$ for $\mathsf{DivZero}(c)$

**Theorem (Soundness of $\vdash$ for $\mathsf{DivZero}(c)$).** Let $\mathsf{DivZero}(c) \vdash \tau$ be derivable by the rules above, let $\tau[\theta]$ be a ground instance of $\tau$ obtained by resolving all holes in $H$ (Slither for $h_m$ and $h_D$, the symbolic solver for $h_{\mathit{args}}$, the LLM for $h_{\mathit{init}}$), and let $M_{\tau[\theta]}$ be the EVM execution trace produced by running $\tau[\theta]$. Assume $\tau[\theta]$ is *non-vacuous* — the *setUp* path constraints and the [Ctrl] constraint $h_D = 0 \land \bigwedge_{d' \prec h_D} d'(\mathit{args},\sigma) \neq 0$ are jointly satisfiable on a path reaching the division, so that $M_{\tau[\theta]}$ is a genuine, non-empty execution — and that the chosen $\sigma$ satisfies the reachability convention above. Then

$$\tau[\theta] \text{ exhibits its defect-indicating outcome (a captured } \texttt{Panic(0x12)}\text{)} \;\Longrightarrow\; M_{\tau[\theta]} \models \mathsf{DivZero}(c).$$

That is, a run that triggers the defect-indicating outcome induces an execution trace $M_{\tau[\theta]}$ that is a model of, hence a *constructive witness* for, the existential statement $\mathsf{DivZero}(c)$. Here $\models$ interprets every atom of the specification on $\mathcal{P}_0/\mathcal{P}_1$ in the usual way: the structural conjuncts are read statically off $\mathcal{P}_0 = \mathrm{Slither}(c)$ and the behavioral conjuncts off the trace $\mathcal{P}_1$.

**Setup.** Recall the division-by-zero specification, with its four conjuncts labelled:

$$\begin{aligned}
\mathsf{DivZero}(c) \equiv{} &
  \exists m \in \mathsf{methods}(c).\;
  \exists \sigma \in \mathsf{State}.\;
  \exists \mathit{args} \in \mathsf{Dom}(m).\;
  \exists d \in \mathsf{Denom}(m).\\
  &\exists a \in \mathsf{Address}.\;
  \exists \sigma_{\mathit{err}} \in \mathsf{State}.\;
  \underbrace{\mathsf{Influence}(\mathsf{srcs}(m), d)}_{C_1} \;\land\;
  \underbrace{(d(\mathit{args}, \sigma) = 0)}_{C_2} \;\land{}\\
  &\underbrace{\mathsf{FailExec}(a, m(\mathit{args}), \sigma, \sigma_{\mathit{err}})}_{C_3} \;\land\;
  \underbrace{\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}})}_{C_4}
\end{aligned}$$

The derivation $\mathsf{DivZero}(c) \vdash \tau$ is a flat tree whose leaves are the phase judgements [Holes], [Pre], [Ctrl], [Act], and [Assrt], and whose root is [Template]. By inversion on the derivation rules, we show that each conjunct $C_1,\ldots,C_4$ is satisfied in the test-induced model $M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle$, where $\mathcal{S}$ is the underlying many-sorted domain (EVM states, methods, arithmetic expressions, etc.), $\mathcal{P}_0 = \mathrm{Slither}(c)$, $\mathcal{P}_1$ is extracted from the EVM execution trace of $\tau[\theta]$, and the witness tuple is $\mathcal{W} = (\theta(h_m),\, \theta(h_D),\, v,\, \sigma,\, a,\, \sigma_{\mathit{err}})$, where $\theta(h_m) = m$ is the chosen method, $\theta(h_D) = d$ is the chosen denominator expression, $v$ is the concrete argument vector witnessing $\mathit{args}$ (the model the symbolic solver returns for $h_{\mathit{args}}$), $\sigma$ is the state established by $h_{\mathit{init}}$ and the *setUp* setters, $a$ is the harness's default caller, and $\sigma_{\mathit{err}}$ is the $\tt 0x12$ panic state read off $\mathcal{P}_1$ (Steps 4–5). The tuple thus assigns a concrete value to every one of the six existentials bound by the prefix of the specification.

**Step 1 ([Holes]): witnesses are well-typed.** The [Holes] rule establishes the hole signature

$$H = \bigl\{ h_m : \mathsf{Method},\; h_D : \mathsf{ArithExpr},\; h_{\mathit{args}} : \mathsf{InputArgs},\; h_{\mathit{init}} : \mathsf{State} \bigr\}$$

with the resolution strategy $\mathit{res}(h_m) = \mathit{res}(h_D) = \mathsf{Slither}$, $\mathit{res}(h_{\mathit{args}}) = \mathsf{Kontrol}$ (symbolic), and $\mathit{res}(h_{\mathit{init}}) = \mathsf{LLM}$. By assumption:

- $\theta(h_m) \in \mathsf{methods}(c)$ per Slither's output, so $\theta(h_m)$ is a valid existential witness for $m$;
- $\theta(h_D) \in \mathsf{Denom}(m)$ per Slither's denominator extraction, so $\theta(h_D)$ is a valid existential witness for $d$ (Denominator-extraction premise);
- $\theta(h_{\mathit{args}})$ and $\theta(h_{\mathit{init}})$ are syntactically valid Solidity, so $\tau[\theta]$ is a type-correct Forge/Kontrol test.

The caller $a$ carries no hole; it is witnessed by the harness's default caller, since a $\tt Panic(0x12)$ is raised by the division itself, independently of $\mathit{msg.sender}$. The error state $\sigma_{\mathit{err}}$ carries no hole; it is witnessed at runtime by the captured panic (Step 4).

**Lemma (Hole Typing).** If $\vdash H : \tau$ and $\tau[\theta]$ does not revert on a type error, then $\mathcal{W}$ is a valid witness candidate for the existential prefix of $\mathsf{DivZero}(c)$. ✓

**Step 2 ([Pre]): conjunct $C_1$ satisfied, state $\sigma$ established.** The [Pre] rule fires because $\mathsf{Influence}(\mathsf{srcs}(m),d) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$ and derives the $\tt setUp$ phase $[\,h_{\mathit{init}}\,]$. When the run reaches the division (Steps 3–4), the *setUp* phase — deployment and public setters — executed without reverting, so the state $\sigma$ in which the vulnerable method is invoked is established and, by the reachability convention, is constructible through $c$'s public interface (not fabricated). The conjunct $C_1 = \mathsf{Influence}(\mathsf{srcs}(m),d)$ is a *static* ($\mathcal{P}_0$) fact discharged by Slither at $h_D$ selection: the chosen denominator $d$ data-depends on the parameter and state sources $\mathsf{srcs}(m)$, so $\mathsf{Influence}(\mathsf{srcs}(m),d) \in \mathcal{P}_0$, which establishes $C_1$ ($M_{\tau[\theta]} \models C_1$). Following the placement convention, this conjunct is cited where its consequence gates the setup; it is never confirmed on the trace, so its soundness is the standing Dependence-precision premise rather than a runtime observation. ✓

**Step 3 ([Ctrl]): conjunct $C_2$ satisfied.** The [Ctrl] rule fires because $(d(\mathit{args},\sigma) = 0) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$ and derives the $\tt ctrl$ phase, in which Kontrol solves

$$h_D = 0 \;\land\; \textstyle\bigwedge_{d' \prec h_D} d'(\mathit{args},\sigma) \neq 0 \quad\text{on a feasible path to the division.}$$

When the solver returns a model, it yields a concrete argument vector $v$ (witnessing $\mathit{args}$) which, together with $\sigma$ from *setUp*, drives the chosen denominator to zero: $d(v,\sigma) = 0$, so $(d(\mathit{args},\sigma) = 0) \in \mathcal{P}_1$ with $\mathit{args} \mapsto v$, which establishes $C_2$ ($M_{\tau[\theta]} \models C_2$). The accompanying clause $\bigwedge_{d' \prec h_D} d'(v,\sigma) \neq 0$ forces $h_D$ to be the *first* zero denominator reached on the path, so the zero the run encounters is provably the chosen $d$ rather than an earlier denominator — sharpening the expression-level witness so the *same* $d$ serves $C_1$ and $C_2$. Method-level satisfaction is independent of this, since $\mathsf{DivZero}(c)$ is existential in $d$ and any influenceable firing denominator already witnesses it; the clause's residual role is to exclude a non-influenceable first zero. Feasibility of the constraint additionally certifies that no effective in-method guard blocks the zero path: an effective $\tt require(d \neq 0)$ along the path would surface as a path constraint rendering $h_D = 0$ unsatisfiable, contradicting non-vacuity. ✓

**Step 4 ([Act]): conjunct $C_3$ satisfied.** The [Act] rule fires because $\Phi \vdash_{\mathit{ctrl}} C$ (the $\tt ctrl$ derivation of Step 3) and $\mathsf{FailExec}(a, m(\mathit{args}),\sigma,\sigma_{\mathit{err}}) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$, and derives the $\tt action$ phase

$$\texttt{try}\;\mathit{victim}.h_m(h_{\mathit{args}})\;\texttt{\{\}}\; \texttt{catch Panic(uint256 err)\{\ldots\}}\;\texttt{catch \{\}}$$

When the call is executed with the witnessing arguments $v$ on $\sigma$, control reaches the division (by the feasibility established in Step 3) and the EVM raises $\tt Panic(0x12)$ at the zero denominator. The call to $\mathit{victim}.h_m(v)$ therefore reverts, producing the error state $\sigma_{\mathit{err}}$, so $\mathsf{FailExec}(a, m(v), \sigma, \sigma_{\mathit{err}}) \in \mathcal{P}_1$ with $a$ the default caller, which establishes $C_3$ ($M_{\tau[\theta]} \models C_3$). The reverting run is intercepted by the $\tt catch\ Panic(uint256\ err)$ branch, binding $\tt err$ to the panic code; the trailing generic $\tt catch\ \{\}$ absorbs every non-$\tt Panic$ revert and every other panic code, so only a genuine $\tt Panic$ reaches the classifier of Step 5. ✓

**Step 5 ([Assrt]): conjunct $C_4$ satisfied.** The [Assrt] rule fires because $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}}) \in \mathrm{conjuncts}(\mathsf{DivZero}(c))$ and derives the $\tt assert$ phase $[\,\texttt{if (err == 0x12) revert("DivZero");}\,]$. The defect-indicating outcome — the harness re-reverting with $\tt "DivZero"$ — occurs *iff* $\texttt{err} = \texttt{0x12}$, i.e. iff the intercepted panic carries code $\texttt{0x12} = \mathsf{P_{div0}}$. Hence the captured $\sigma_{\mathit{err}}$ is a division-by-zero panic: $\mathsf{IsPanic}(\sigma_{\mathit{err}}, \mathsf{P_{div0}}) \in \mathcal{P}_1$, which establishes $C_4$ ($M_{\tau[\theta]} \models C_4$). Because the generic $\tt catch\ \{\}$ of Step 4 discards all other reverts — other panic codes (e.g. $\tt 0x11$ overflow), $\tt Error(string)$ from a guard, custom errors, and an empty $\tt revert()$ — the re-revert fires *only* on an observed $\tt Panic(0x12)$, so the defect-indicating outcome corresponds exactly to a captured zero-denominator division and never to an incidental revert along the path. ✓

**Key observation.** An intercepted $\tt Panic(0x12)$ (concretely in Forge, symbolically in Kontrol) is equivalent to the satisfaction of the observed FOL atoms $\mathsf{FailExec}$ and $\mathsf{IsPanic}(\cdot, \mathsf{P_{div0}})$ in $\mathcal{P}_1$; together with the structural conjuncts discharged in *setUp*/*ctrl*, every conjunct $C_1$–$C_4$ is read off the run — statically for $C_1$, symbolically and operationally for $C_2$–$C_4$. ✓

**Step 6 ([Template]): global assembly.** The [Template] rule at the root of the derivation tree is

$$\dfrac{\displaystyle \Phi \vdash H \quad \Phi \vdash_{\mathit{setUp}} S \quad \Phi \vdash_{\mathit{ctrl}} C \quad \Phi \vdash_{\mathit{action}} A \quad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H, S, C, A, \mathit{AS}\rangle} \quad \text{[Template]}$$

with $\Phi = \mathsf{DivZero}(c)$. By Steps 1–5, each of the five premises is established and each of the four conjuncts $C_1,\ldots,C_4$ is satisfied in $M_{\tau[\theta]}$, with every conjunct covered by a phase (Phase–conjunct correspondence). Since $\mathcal{W} = (\theta(h_m), \theta(h_D), v, \sigma, a, \sigma_{\mathit{err}})$ witnesses all six existentials — $\theta(h_m) = m$ and $\theta(h_D) = d$ extracted statically by Slither, $v$ the concrete arguments returned by the [Ctrl] solver, $\sigma$ established in *setUp*, $a$ the default caller, and $\sigma_{\mathit{err}}$ the $\tt 0x12$ panic state extracted from the trace — all conjuncts hold simultaneously under $(\mathcal{P}_0, \mathcal{P}_1, \mathcal{W})$:

$$M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle \;\models\; \mathsf{DivZero}(c). \qquad\square$$

**Scope.** The theorem does *not* claim that $\tau[\theta]$ is the unique defect model: other inputs or denominators may also satisfy $\mathsf{DivZero}(c)$. It is also silent on completeness: if no witnessing input drives some denominator to zero — every run returns, or reverts for an unrelated reason — the harness does not re-revert and the theorem does not apply, possibly a false negative (e.g. a zero reachable only from a state $h_{\mathit{init}}$ does not set up, or a division missed by an incomplete $\mathsf{Denom}(m)$). Soundness is moreover conditional on the two static premises — Denominator extraction (completeness and exact slicing of $\mathsf{Denom}(m)$) and Dependence precision (accuracy of $\mathsf{Influence}$ on $d$) — and on the reachability convention for $\sigma$; an over-approximate $\mathsf{Influence}$ that flags a constant denominator, or a fabricated unreachable $\sigma$, is the sole false-positive channel.
