# Predictable Random Number Generation

This vulnerability arises when a smart contract tries to generate "random" values by using environmental data that is predictable, manipulable, or observable by adversaries — especially miners or validators.

## Specification primitives

Our defect specifications rely on standard Solidity datatypes — $\mathsf{Contract}$, $\mathsf{Method}$, $\mathsf{Address}$, $\mathsf{Env}$(ironment), and $\mathsf{State}$. A brief description of the necessary predicates and functions over these types is included in the table below. The evaluation of these primitives is stratified: structural properties are derived statically via Slither, while behavioral properties are verified at runtime via Forge/Kontrol assertions within the LLM-generated test harness.

| Symbol | Semantics |
|--------|-----------|
| ***Static Analysis (Slither)*** | |
| $\texttt{methods}(c)$ | The set of externally-callable functions (entry points) of contract *c*, which includes its public/external functions and the special $\tt receive$ and $\tt fallback$ functions. |
| $E_{\mathit{unsafe}}$ | The attacker-observable block-environment fields readable at action time ($\tt block.timestamp$, $\tt block.number$, $\tt block.prevrandao$, $\tt block.coinbase$, $\tt block.basefee$) that an attacker can observe or influence. ($\tt blockhash$, though attacker-observable, is excluded: Forge exposes no cheatcode to control it.) |
| $\texttt{IsCriticalDecision}(m)$ | Holds if the random output of *m* seeds a state transition of high financial impact (e.g., selecting a lottery winner or NFT rarity). Distinct from $\texttt{IsCritical}(m)$ of Unrestricted Access: $\texttt{IsCritical}$ classifies the *operation* as security-critical (e.g. $\tt selfdestruct$, ownership transfer), whereas $\texttt{IsCriticalDecision}$ classifies the method's *random draw* as seeding a high-impact decision. |
| $\texttt{EnvOnly}(F)$ | Holds if the mirror function *F* is computable from *attacker-observable data* alone — defined as the closure under pure (deterministic, side-effect-free) computation of: (a) all victim storage in the reachable state $\sigma$, under any Solidity visibility ($\tt public$/$\tt private$/$\tt internal$), since every storage slot is publicly readable off-chain; (b) all external-contract state the draw reads (foreign storage slots and $\tt view$ results); (c) attacker-controlled transaction context ($\tt msg.*$, $\tt tx.*$, and calldata/arguments); and (d) the predictable block fields $E_{\mathit{unsafe}}$ (observable or miner/validator-influenced). It *excludes* any value not present in a constructible state at draw time — future-block entropy and unrevealed commit–reveal/VRF secrets (the latter additionally excluded by $\mathsf{Influence}$, since once revealed they are ordinary storage of class (a)). Observability requires only that the attacker can *know* the value, not set it; hence *F* is reproducible by an attacker. |
| $\texttt{Influence}(S, e)$ | The same data-flow predicate as for Division by Zero: the expression *e* data-depends on the *source set* *S*, a value-independent static property whose arguments are syntactic. As noted there, *e* may be a *derived* expression; here it is instantiated as $\texttt{Influence}(E_{\mathit{unsafe}}, \texttt{Draw}(m,\cdot))$ — the draw of *m*, viewed as a function of the environment, data-depends on the manipulable block-field sources $E_{\mathit{unsafe}}$ rather than on committed storage or externally-delivered values. |
| ***Runtime Verification (LLM-generated based on specific template)*** | |
| $\texttt{Draw}(m, \sigma)$ | The value produced by the "random" computation of *m* when executed in state σ; $\mathsf{Result}$ is the result type of *m*. |
| $F : \mathsf{State} \times \mathsf{Env} \to \mathsf{Result}$ | A local mirror function replicating the contract's "random" computation from the observable state and environment; the existential second-order witness, instantiated by the LLM as $h_F$. It genuinely depends on $\sigma$ — recomputing the draw from on-chain *storage* as well as from $E$ — so it is not a constant function of state, even though the witness fixes a single $\sigma$ (only $E$ is universally quantified). |


## Formal Specification

Predictable randomness is defined as the existence of a mirror function $F$ that depends only on unsafe, observable environment fields and reproduces the contract's random output across all environments:

$$\begin{aligned}
\mathsf{Predictable}(c) \equiv {} & \exists m \in \mathsf{methods}(c).\ \exists \sigma \in \mathsf{State}.\ \exists F : \mathsf{State} \times \mathsf{Env} \to \mathsf{Result}.\\
& \mathsf{IsCriticalDecision}(m) \land \mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot)) \land \mathsf{EnvOnly}(F) \land {}\\
& (\forall E \in \mathsf{Env}.\ \mathsf{Draw}(m, \sigma[E]) = F(\sigma, E))
\end{aligned}$$

where $\sigma[E]$ denotes state $\sigma$ with its block environment set to $E$, and $\mathsf{Draw}(m, \cdot)$ is the "random" value computed by $m$. The mirror function $F$ is the existential second-order witness: $\mathsf{EnvOnly}(F)$ restricts $F$ to attacker-observable data (classes (a)–(d) of the primitives table: victim storage, external-contract state, transaction context, and the manipulable block fields $E_{\mathit{unsafe}}$), so $F$ is attacker-computable, while the *universal* quantifier $\forall E$ forces $F$ to reproduce the contract's output across *all* environments. A point equality $\exists E.\ \mathsf{Draw}(m,\sigma[E]) = F(\sigma, E)$ would be vacuous, since some $F$ trivially matches any single observed value; but the universal $\forall E$ *alone* is also vacuous, since the cheating mirror $F := \mathsf{Draw}(m,\cdot)$ reproduces the draw on every environment. It is $\mathsf{EnvOnly}(F)$ that excludes such a mirror by requiring $F$ to recompute the draw from attacker-observable data only; the two together state the genuine defect: the random outcome is a deterministic function of attacker-observable on-chain data, with no dependence on externally-delivered or future-block entropy (e.g., a VRF callback or a future block's $\tt prevrandao$/$\tt blockhash$), which therefore lies outside this observable input space and is correctly not flagged. The remaining conjunct $\mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot))$ requires the draw to *genuinely data-depend* on the manipulable block fields $E_{\mathit{unsafe}}$, not merely to be reproducible from a fixed state: because $\sigma$ is fixed and only $E$ is quantified, the universal equality is satisfied by any draw that is constant in $E$ — including one reading a committed VRF result or a revealed commit–reveal secret from storage. Such a draw is publicly readable (hence reproducible by $h_F$) yet does not depend on $E_{\mathit{unsafe}}$, so $\mathsf{Influence}$ fails and the contract is correctly not flagged.

**Scope.** The defect targets randomness that data-depends on the manipulable block environment $E_{\mathit{unsafe}}$, as required by $\mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot))$. Two secure patterns are thereby excluded, for *distinct* reasons. A draw reading a *future-block* value (a future $\tt prevrandao$) depends on data absent from any state $\sigma$ the harness can build, so no $F$ over the observable inputs reproduces it and the universal equality already fails. Independently — and as a *tooling*, not semantic, limitation — a draw over $\tt blockhash$, even of a past block an attacker *can* observe, falls outside the current harness, since Forge exposes no cheatcode to set the value $\tt blockhash$ returns; symbolising that field is left to future tooling, so $E_{\mathit{unsafe}}$ as realised here omits it. A draw consuming a *committed* value — a verifiable-randomness (VRF) callback result or a revealed commit–reveal secret already written to storage — is, by contrast, perfectly reproducible by the harness (the value is public on-chain, surfaced via $\tt vm.load$), so it would spuriously satisfy the universal equality; it is excluded instead by $\mathsf{Influence}$, since $\mathsf{Draw}$ then depends on stored randomness rather than on $E_{\mathit{unsafe}}$. This is the intended boundary for an *environment-dependency* defect: a draw that is predictable yet free of $E_{\mathit{unsafe}}$ dependence (e.g., a deterministic function of a public counter) is likewise outside this category by design.

**Assumption (Read-set completeness).** Soundness of the symbolic discharge rests on the read subset $R = \{e \in E_{\mathit{unsafe}} \mid \mathsf{Influence}(\{e\}, \mathsf{Draw}(m,\cdot)) \lor \mathsf{Influence}(\{e\}, F)\}$ identified by Slither being *complete*: every block field read by the draw *or by the mirror $F$* is in $R$ and hence made symbolic. Including the mirror's reads is essential: were $R$ to track only the draw's reads, a mirror $h_F$ that consults an $E_{\mathit{unsafe}}$ field the draw ignores — say $\tt block.coinbase$ — would have that field pinned to a constant, and an $h_F$ coinciding with $\mathsf{Draw}$ only at that pin would pass $\tt assertEq$ spuriously although $\forall E.\,\mathsf{Draw}=F$ is false; $\mathsf{EnvOnly}(F)$ does not exclude this, since $\tt coinbase$ is attacker-observable. If Slither *under*-approximates $R$ (misses a field either the draw or the mirror reads), that field is held constant during the test and the equality may pass spuriously — a false negative for the universal $\forall E$. Under this completeness assumption the fields outside $R$ are read by neither $\mathsf{Draw}$ nor $F$, so both are invariant in them and $\forall E$ is discharged trivially there; symbolising exactly $R$ then proves the identity over the entire input space on which either side depends.

**Assumption (Critical-decision identification).** The conjunct $\mathsf{IsCriticalDecision}(m)$ is discharged by a static Slither/LLM classifier over $h_m$, a heuristic recognising draws whose output seeds a high-impact state transition (lottery winner, NFT rarity, fund allocation). Its soundness rests on this classifier being *accurate* on $h_m$: an over-broad classifier flags a draw of no financial consequence (a false positive), while an over-narrow one misses a genuinely critical draw (a false negative). We therefore assume the classifier correctly decides the criticality of the selected $h_m$; like the other static $\mathcal{P}_0$ conjuncts — and exactly as $\mathsf{IsCritical}$ for Unrestricted Access — $\mathsf{IsCriticalDecision}(m)$ is never confirmed on the trace, so this precision is a standing premise.

**Assumption (Mirror-observability soundness).** The conjunct $\mathsf{EnvOnly}(F)$ is discharged statically over the LLM-resolved mirror $h_F$, certifying that $h_F$ reads *only* attacker-observable data — the closure under pure computation of classes (a)–(d) above. Its soundness rests on this check being *sound*: if $\mathsf{EnvOnly}$ wrongly passes for an $h_F$ that in fact consumes a value outside the observable closure (an externally-delivered or future-block input), the equality $\mathsf{Draw} = h_F$ would certify a "predictable" draw that no attacker can actually predict — a false positive. A spuriously *failing* $\mathsf{EnvOnly}$ only loses a witness (a false negative). It is complementary to $\mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot))$: $\mathsf{EnvOnly}$ bounds what the mirror *may* read (observable data only), while $\mathsf{Influence}$ requires the draw to *actually* depend on the manipulable subset $E_{\mathit{unsafe}}$, jointly excluding committed-randomness (VRF/commit–reveal) patterns.

## Specific test template design

**Testing Goal** — Prove that a critical decision of $m$, intended to be random, is a deterministic mirror function $F$ of the attacker-observable environment ($\mathsf{EnvOnly}(F)$), reproducing the contract's output across *all* environments.

**Setup** — The harness uses Forge cheatcodes to fix the manipulable block-environment fields (timestamp, block number, and similar) to specific fuzzed or symbolic values.

**Correlation Check** — The test executes the target random function multiple times within the same simulated block, or across identical environmental parameters, to verify consistency.

**Action** — In the test contract, the LLM instantiates the mirror function $F$ to pre-calculate the expected result from the same observable block data, then calls the target method to capture its actual output. Synthesising this mirror (the hole $h_F$) is the central LLM contribution for this defect.

**Assertion** — The framework asserts that the contract's output matches the pre-calculated value. If these match across multiple fuzzed environments, the randomness is confirmed to be predictable and potentially manipulable by miners or validators.

## Template Derivation and LLM Instantiation

The conceptual test design is materialized into a standardized Foundry test template (e.g., $\tt PredictableRandomNumberGeneration.t.sol$). To bridge the gap between static analysis and generation, the template embeds explicit $\tt [LLM\_INSTRUCTION]$ comments alongside structural markers for the Setup, Correlation Check, Action, and Assertion phases.

Each hole is assigned to either Slither or the LLM for resolution, as summarized in the table below. The specification $\mathsf{Predictable}(c)$ contains three existential witnesses and one universally-quantified environment. Each maps to a typed hole in the template schema:

| Spec witness | Hole | Sort | Resolved by |
|---|---|---|---|
| $\exists m \in \mathsf{methods}(c)$ (random outcome method) | $h_m$ | $\mathsf{Method}$ | Slither |
| $F : \mathsf{State} \times \mathsf{Env} \to \mathsf{Result}$ (mirror function) | $h_F$ | $\mathsf{FunctionExpr}$ | LLM (logic replica) |
| $\exists \sigma \in \mathsf{State}$ (context) | $h_{\mathit{init}}$ | $\mathsf{State}$ | LLM |
| $\forall E \in \mathsf{Env}$ (symbolic environment) | $h_{\mathit{env}}$ | $\mathsf{BlockEnvParams}$ | LLM / Kontrol |
| $\forall E.\ \mathsf{Draw}(m, \sigma[E]) = F(\sigma, E)$ | witnessed at runtime | | Forge/Kontrol |

The equality $\forall E.\ \mathsf{Draw}(m,\sigma[E])=F(\sigma, E)$ carries no explicit hole: its *truth* is witnessed at runtime by the $\tt assertEq$ passing for every fuzzed or symbolic environment, making it an implicit universal that is *verified* rather than *filled*. Under Kontrol, $E$ is symbolic so a passing equality proves the identity for all feasible environments; under Forge the same equality is sampled at concrete environments. Accordingly, the soundness conclusion "$\tau[\theta]$ passes $\Rightarrow M_{\tau[\theta]} \models \mathsf{Predictable}(c)$" holds *only under Kontrol*, where symbolising the read fields discharges the universal $\forall E$; a passing Forge run samples finitely many environments and is corroborating evidence, not a constructive witness for the $\forall E$ conjunct.

Before stating the derivation rules, we record how each conjunct of $\mathsf{Predictable}(c)$ maps to exactly one test phase and its concrete template realization:

| Spec element | Phase | Template realization |
|---|---|---|
| $\forall E \in \mathsf{Env}$ *(binder)* | *setUp* | make symbolic each block field read by the draw *or* the mirror (the subset $R \subseteq E_{\mathit{unsafe}}$ with $\mathsf{Influence}(\{e\},\mathsf{Draw}(m,\cdot))\lor\mathsf{Influence}(\{e\},F)$) via its cheatcode ($\tt vm.warp$/$\tt vm.roll$/$\tt vm.prevrandao$/$\tt vm.coinbase$/$\tt vm.fee$); fields read by neither stay constant, with $\mathsf{Draw}$, $F$ invariant there, so symbolic over $R \Rightarrow$ all $E$ |
| $\mathsf{IsCriticalDecision}(m)$ | *setUp* | identified by Slither; no hole needed |
| $\mathsf{EnvOnly}(F)$ | *setUp* | static precondition discharged by Slither/LLM before runtime; no hole needed |
| $\mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot))$ | *setUp* | static data-dependence confirmed by Slither (the draw reads a manipulable block field); no hole needed |
| $\mathsf{Draw}(m, \sigma[E])$ | *action* | $\tt actualRandom = victim.h\_m()$ |
| $F(\sigma, E)$ | *action* | $\tt expectedRandom = h\_F(\sigma_{view},\ h\_env)$ (local replica synthesized by LLM; $\sigma_{view}$ reads every attacker-observable input the draw depends on — victim $\tt private$/$\tt internal$ slots via $\tt vm.load$/$\tt stdstore$, external-contract state, and $\tt msg.*$/$\tt tx.*$/calldata: classes (a)–(c) of $\mathsf{EnvOnly}$) |
| $\forall E.\ \mathsf{Draw}(m,\sigma[E]) = F(\sigma, E)$ | *assert* | $\tt assertEq(actualRandom,\ expectedRandom)$ |

## Derivation Rules for $\vdash$

This section gives a rigorous definition of the relation $\Phi(c) \vdash \tau$, read "defect specification $\Phi$ derives template schema $\tau$". We develop it through the Predictable Random Number Generation running example.

The relation $\Phi(c) \vdash \tau$ is defined by the following five rules.

Witnesses become typed holes:

$$\dfrac{}{\displaystyle \Phi \vdash \bigl\{ h_m : \mathsf{Method},\; h_F : \mathsf{FunctionExpr},\; h_{\mathit{init}} : \mathsf{State},\; h_{\mathit{env}} : \mathsf{BlockEnvParams} \bigr\}} \quad \text{[Holes]}$$

Static preconditions $\mathsf{IsCriticalDecision}(m)$, $\mathsf{EnvOnly}(F)$, and $\mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot))$ derive the *setUp* phase:

$$\dfrac{\displaystyle \mathsf{IsCriticalDecision}(m) \in \mathrm{conjuncts}(\Phi) \quad \mathsf{EnvOnly}(F) \in \mathrm{conjuncts}(\Phi) \quad \mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot)) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{setUp}} \left[\begin{array}{l} h_{\mathit{init}};\; \texttt{vm.assume}(\cdot);\; \bigl(\mathit{cheat}_e(h_{\mathit{env}}.e)\bigr)_{e \in R} \end{array}\right]} \quad \text{[Pre]}$$

where $R = \{e \in E_{\mathit{unsafe}} \mid \mathsf{Influence}(\{e\}, \mathsf{Draw}(m,\cdot)) \lor \mathsf{Influence}(\{e\}, F)\}$ is the subset of block fields read by the draw *or* the mirror $F$, and $\mathit{cheat}_e$ its Forge cheatcode ($\tt vm.warp$, $\tt vm.roll$, $\tt vm.prevrandao$, $\tt vm.coinbase$, $\tt vm.fee$); fields outside $R$ stay constant, over which the universal $\forall E$ is trivial.

The equality condition derives the *action* phase:

$$\dfrac{\displaystyle (\forall E \in \mathsf{Env}.\ \mathsf{Draw}(m,\sigma[E])=F(\sigma, E)) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{action}} \bigl[\mathit{expectedRandom} = h_F(\sigma_{\mathit{view}}, h_{\mathit{env}});\; \mathit{actualRandom} = \mathit{victim}.h_m()\bigr]} \quad \text{[Act]}$$

where $\sigma_{\mathit{view}}$ reads every attacker-observable input the draw depends on — victim storage ($\tt private$/$\tt internal$ slots via $\tt vm.load$/$\tt stdstore$), external-contract state, and the transaction context ($\tt msg.*$/$\tt tx.*$/calldata): classes (a)–(c) of $\mathsf{EnvOnly}$.

The equality condition also derives the *assert* phase:

$$\dfrac{\displaystyle (\forall E \in \mathsf{Env}.\ \mathsf{Draw}(m,\sigma[E])=F(\sigma, E)) \in \mathrm{conjuncts}(\Phi)}{\displaystyle \Phi \vdash_{\mathit{assert}} \bigl[\texttt{assertEq}(\mathit{actualRandom},\, \mathit{expectedRandom})\bigr]} \quad \text{[Assrt]}$$

All phases combine into the full schema:

$$\dfrac{\displaystyle \Phi \vdash H \qquad \Phi \vdash_{\mathit{setUp}} S \qquad \Phi \vdash_{\mathit{action}} A \qquad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H,\, S,\, A,\, \mathit{AS} \rangle} \quad \text{[Template]}$$


## Derived Predictable-RNG Multi-Shot Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
// [LLM_INSTRUCTION]: Import the artifact of the contract being tested. The solidity files are in "../src/". The name of the file is the same as the name of the contract.
// [LLM_INSTRUCTION]: If needed, import specific cheats or libraries.

// ------------------------------ 
// [Testing Goal] Prove that a critical decision or value, intended to be random,
// is a deterministic function of the unsafe observable environment set.
// ------------------------------ 

// [LLM_INSTRUCTION]: Name the contract 'TestWeakRandomness[ContractName]'
contract TestWeakRandomnessTemplate is Test {

// ------------------------------ 
    // [Setup] Declare the contract under test variable.
// ------------------------------ 
    
    // [LLM_INSTRUCTION]: Declare the contract under test variable
    // BadRandomNumberGen public _contractUnderTest;

// ------------------------------ [/Setup]

    function setUp() public {
// ------------------------------ 
        // [Setup] Initialize the contract under test.
// ------------------------------ 

        // [LLM_INSTRUCTION]: Initialize the contract under test.
        // 1. If constructor parameters are needed, use concrete valid values.
        // 2. If payable, use vm.deal(address(this), amount) before deployment.
        
        // _contractUnderTest = new BadRandomNumberGen();

// ------------------------------ [/Setup]
    }

    // [LLM_INSTRUCTION]: INFER BLOCK DEPENDENCIES
    // 1. Scan the contract source code for block properties.
    // 2. Add arguments ONLY for the properties found:
    //    - Found 'block.timestamp'? -> Add 'uint256 blockTimestamp'
    //    - Found 'block.number'?    -> Add 'uint256 blockNumber'
    //    - Found 'block.prevrandao' or 'block.difficulty'? -> Add 'uint256 blockPrevrandao'
    //    - Found 'block.coinbase'?  -> Add 'address blockCoinbase'
    //    - Found 'block.basefee'?   -> Add 'uint256 blockBaseFee'
    // Example: function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
    function test_highlightPredictableRandomValue(/* [LLM_INSTRUCTION]: Insert inferred arguments here */) public {
        
// ------------------------------ 
        // [Setup] Constrain the inferred symbolic variables and fix the
        // environmental state using Forge cheatcodes (vm.warp, vm.roll, etc.)
        // to specific fuzzed or symbolic values.
// ------------------------------ 

        // [LLM_INSTRUCTION]: Constrain the inferred symbolic variables.
        // Only generate lines for the arguments you added above.
        
        // If blockTimestamp used:
        // vm.assume(blockTimestamp >= block.timestamp);
        
        // If blockNumber used:
        // vm.assume(blockNumber >= block.number);
        
        // [LLM_INSTRUCTION]: Avoid arithmetic overflows.
        // Check the contract logic. If it sums these values, ensure they fit in uint256.
        // Example: vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        // [LLM_INSTRUCTION]: Funding (if needed)
        // vm.deal(address(this), 100 ether);

        // [LLM_INSTRUCTION]: MANIPULATE BLOCK ENVIRONMENT
        // Apply the inferred values using Cheatcodes. Only generate lines for the arguments you added.
        
        // If blockTimestamp used -> vm.warp(blockTimestamp);
        // If blockNumber used    -> vm.roll(blockNumber);
        // If blockPrevrandao used -> vm.prevrandao(bytes32(blockPrevrandao));
        // If blockCoinbase used  -> vm.coinbase(blockCoinbase);
        // If blockBaseFee used   -> vm.fee(blockBaseFee);

// ------------------------------ [/Setup]

// ------------------------------ 
        // [Correlation Check] Execute the target "random" function multiple
        // times within the same simulated block or across identical
        // environmental parameters to verify consistency.
// ------------------------------ 

        // [LLM_INSTRUCTION]: (Optional) Call the random function twice in the
        // same block to check that the output is identical each time.
        // uint256 firstCall  = _contractUnderTest.getRandomNumber();
        // uint256 secondCall = _contractUnderTest.getRandomNumber();
        // assertEq(firstCall, secondCall, "Output differs within the same block - not purely block-dependent");

// ------------------------------ [/Correlation Check]

// ------------------------------ 
        // [Action] Instantiate mirroring logic to pre-calculate the expected
        // result using the same observable block data (e.g.,
        // uint(keccak256(abi.encodePacked(block.timestamp)))).
// ------------------------------ 

        // [LLM_INSTRUCTION]: PREDICT THE OUTCOME
        // Replicate the vulnerable logic locally inside the test.
        // Since we control the block state, we can calculate the exact result the contract should produce.
        //
        // [LLM_INSTRUCTION]: SURFACE ON-CHAIN STATE THE DRAW DEPENDS ON
        // If the random computation also mixes in contract storage (e.g. a nonce,
        // a player count, a seed, address(this).balance), the mirror must read those
        // values too - the prediction is a function F(state, env), not env alone.
        // All EVM storage is publicly readable off-chain regardless of Solidity
        // 'private'/'internal' visibility, so surface such slots (public getter if
        // available, otherwise vm.load/stdstore) and feed them into the mirror.
        // The same applies to any EXTERNAL-CONTRACT state the draw reads (a foreign
        // storage slot or a view() result) and to the TRANSACTION CONTEXT it reads
        // (msg.sender, tx.origin, msg.value, calldata): all are attacker-observable.
        
        // Example Logic Replicated:
        // uint256 expectedRandom = uint256(keccak256(abi.encodePacked(block.prevrandao, blockNumber, blockTimestamp)));

        // [LLM_INSTRUCTION]: EXECUTE
        // Call the contract method.
        // uint256 actualRandom = _contractUnderTest.getRandomNumber();

// ------------------------------ [/Action]

// ------------------------------ 
        // [Assertion] Assert that the contract's output matches the
        // pre-calculated value (actualResult == preCalculatedResult). If
        // these values match across multiple fuzzed environments, the randomness is
        // confirmed to be predictable and potentially manipulable by miners or validators.
// ------------------------------ 

        // [LLM_INSTRUCTION]: ASSERT PREDICTABILITY
        // Prove that the contract's "random" value matches our calculated expectation.
        // assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");

// ------------------------------ [/Assertion]
    }
}
```

### Rule Application

The derivation $\mathsf{Predictable}(c) \vdash \tau$ proceeds by applying the five rules in sequence. For each step we identify the triggering conjunct(s) from $\mathsf{Predictable}(c)$, state what the rule derives, and map the output to the specific region of the code template above.

---

**Step 1 — [Holes]** (no premise)

The axiom fires unconditionally and establishes the hole signature:

$$H = \bigl\{\, h_m : \mathsf{Method},\quad h_F : \mathsf{FunctionExpr},\quad h_{\mathit{init}} : \mathsf{State},\quad h_{\mathit{env}} : \mathsf{BlockEnvParams} \,\bigr\}$$

Each hole appears in the template as a $\tt [LLM\_INSTRUCTION]$ placeholder:

| Hole | Sort | Stands for | Filled by |
|---|---|---|---|
| $h_m$ | $\mathsf{Method}$ | the vulnerable method whose output is the "random" value | Slither (e.g., $\tt \_contractUnderTest.getRandomNumber$) |
| $h_F$ | $\mathsf{FunctionExpr}$ | the local mirror function that replicates the contract's random computation | LLM (e.g., $\tt uint256(keccak256(abi.encodePacked(block.prevrandao,\ \ldots)))$) |
| $h_{\mathit{init}}$ | $\mathsf{State}$ | the state-initializing statements in $\tt setUp()$ | LLM (e.g., $\tt \_contractUnderTest = new\ BadRandomNumberGen()$) |
| $h_{\mathit{env}}$ | $\mathsf{BlockEnvParams}$ | the fuzzed or symbolic block environment parameters ($\tt blockTimestamp$, $\tt blockNumber$, etc.) | LLM / Kontrol |

The hole $h_F$ is the central LLM contribution: the model synthesises a local Solidity expression that mirrors the vulnerable computation, enabling the expected output to be pre-calculated purely from the observable environment $h_{\mathit{env}}$.

---

**Step 2 — [Pre]** fires on $C_1$, $C_2$, and $C_3$

Triggering conjuncts:
- $C_1 = \mathsf{IsCriticalDecision}(m)$ — discharged **statically**: Slither confirms that $h_m$ seeds a high-impact state transition (e.g., lottery winner selection). No runtime hole is needed.
- $C_2 = \mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot))$ — discharged **statically**: Slither confirms that the draw genuinely data-depends on a manipulable block field in $E_{\mathit{unsafe}}$ (not on committed storage or an externally-delivered value such as a VRF result), which both selects the fields to symbolise and excludes secure committed randomness.
- $C_3 = \mathsf{EnvOnly}(F)$ — discharged **statically**: Slither/LLM confirms that the mirror $h_F$ reads only attacker-observable data (block fields $E_{\mathit{unsafe}}$, victim storage of any visibility, external-contract state, and transaction context) and no externally-delivered or future-block value.

Derives (symbolising exactly the read subset $R = \{e \in E_{\mathit{unsafe}} \mid \mathsf{Influence}(\{e\}, \mathsf{Draw}(m,\cdot)) \lor \mathsf{Influence}(\{e\}, F)\}$):
$$\Phi \vdash_{\mathit{setUp}} \bigl[\,h_{\mathit{init}};\; \texttt{vm.assume}(\cdot);\; \bigl(\mathit{cheat}_e(h_{\mathit{env}}.e)\bigr)_{e \in R}\,\bigr]$$

Template realization — the $\tt [Setup]$ regions:

- In $\tt setUp()$: the $\tt [LLM\_INSTRUCTION]$ for $h_{\mathit{init}}$ instantiates the victim contract ($\tt \_contractUnderTest = new\ BadRandomNumberGen()$).
- In $\tt test\_highlightPredictableRandomValue()$: the LLM infers which block fields are used (populating $h_{\mathit{env}}$) and emits the corresponding $\tt vm.assume$ constraints together with $\tt vm.warp(blockTimestamp)$, $\tt vm.roll(blockNumber)$, and $\tt vm.prevrandao(bytes32(blockPrevrandao))$ to fix the simulated environment. Because $h_{\mathit{env}}$ is a fuzz argument (or a Kontrol symbolic variable), this single $\tt setUp$ derivation covers *all* environments $E$ simultaneously.

The three static conjuncts $C_1$, $C_2$, and $C_3$ are preconditions: once Slither discharges them, the rule fires and the setUp code is emitted. No hole is needed for $\mathsf{IsCriticalDecision}$, $\mathsf{Influence}$, or $\mathsf{EnvOnly}$ themselves.

---

**Step 3 — [Act]** fires on $C_4$

Triggering conjunct: $C_4 = (\forall E \in \mathsf{Env}.\ \mathsf{Draw}(m, \sigma[E]) = F(\sigma, E))$ — the contract's random output must equal the mirror function's output for every environment.

Derives:
$$\Phi \vdash_{\mathit{action}} \bigl[\,\mathit{expectedRandom} = h_F(h_{\mathit{env}});\; \mathit{actualRandom} = \mathit{victim}.h_m()\,\bigr]$$

Template realization — the $\tt [Action]$ region:
```solidity
// uint256 expectedRandom = uint256(keccak256(abi.encodePacked(block.prevrandao, blockNumber, blockTimestamp)));
//                        = h_F(h_env)  →  F(σ, E)  side of C₄
// uint256 actualRandom = _contractUnderTest.getRandomNumber();
//                      = victim.h_m()  →  Draw(m, σ[E])  side of C₄
```
The LLM synthesises $h_F$ by inspecting the contract source: it copies the exact computation (e.g., a $\tt keccak256$ over block fields) into the test harness so that $\tt expectedRandom$ can be computed without calling the contract. Calling $\tt victim.h_m()$ then captures $\mathsf{Draw}(m, \sigma[E])$ in $\tt actualRandom$. Both assignments together materialize both sides of the equality in $C_4$.

---

**Step 4 — [Assrt]** fires on $C_4$

Triggering conjunct: $C_4 = (\forall E \in \mathsf{Env}.\ \mathsf{Draw}(m, \sigma[E]) = F(\sigma, E))$ (same conjunct as Step 3, now used to derive the assertion).

Derives:
$$\Phi \vdash_{\mathit{assert}} \bigl[\,\texttt{assertEq}(\mathit{actualRandom},\, \mathit{expectedRandom})\,\bigr]$$

Template realization — the $\tt [Assertion]$ region:
```solidity
// assertEq(actualRandom, expectedRandom,
//     "Randomness should be predictable given block state");
```
A passing $\tt assertEq$ means $\tt actualRandom == expectedRandom$, which is the concrete witness that $\mathsf{Draw}(m, \sigma[E]) = F(\sigma, E)$ holds for the chosen environment $E$. Under Forge this is verified at every fuzzed environment; under Kontrol, where $h_{\mathit{env}}$ is symbolic, a single passing run proves the identity for all feasible $E$, completing the universal quantifier. If the assertion passes, the defect is confirmed: the contract's "random" output is fully determined by the observable, attacker-computable environment.

---

**Step 5 — [Template]** assembles all four sub-derivations

All premises of [Template] are now established:

| Premise | Established in |
|---|---|
| $\Phi \vdash H$ | Step 1 |
| $\Phi \vdash_{\mathit{setUp}} S$ | Step 2 |
| $\Phi \vdash_{\mathit{action}} A$ | Step 3 |
| $\Phi \vdash_{\mathit{assert}} AS$ | Step 4 |

Applying [Template] yields $\mathsf{Predictable}(c) \vdash \langle H, S, A, \mathit{AS} \rangle = \tau$, which is exactly the code template above with four open holes for the LLM to fill. The conjuncts $C_1$–$C_4$ of $\mathsf{Predictable}(c)$ map onto the phases of $\tau$ as recorded in the Phase–Conjunct table above ($C_1$, $C_2$, $C_3$ are static setUp preconditions; $C_4$ drives both action and assert), completing the derivation. Note that $C_4$ drives two phases (action and assert) because the universal equality $\forall E.\ \mathsf{Draw}(m,\sigma[E])=F(\sigma, E)$ has both a *computation* side (materialize $F(\sigma, E)$ and $\mathsf{Draw}(m,\sigma[E])$) and a *verification* side (assert they are equal).

## Soundness of $\vdash$ for $\mathsf{Predictable}(c)$

**Theorem (Soundness of $\vdash$ for $\mathsf{Predictable}(c)$).** Let $\mathsf{Predictable}(c) \vdash \tau$ be derivable by the rules above, let $\tau[\theta]$ be a ground instance of $\tau$ obtained by resolving all holes in $H$ (Slither for $h_m$, the LLM for $h_F$ and $h_{\mathit{init}}$, Kontrol making $h_{\mathit{env}}$ symbolic over the read subset $R$), and let $M_{\tau[\theta]}$ be the EVM execution trace produced by running $\tau[\theta]$. Assume $\tau[\theta]$ is *non-vacuous*, that the chosen $\sigma$ satisfies the reachability condition above, and the standing static premises stated above — *Read-set completeness* (every block field read by the draw or the mirror is in $R$), *Critical-decision identification* ($\mathsf{IsCriticalDecision}(m)$), and *Mirror-observability soundness* ($\mathsf{EnvOnly}(F)$). Then

$$\tau[\theta] \text{ passes under Kontrol with } R \subseteq E_{\mathit{unsafe}} \text{ held symbolic} \;\Longrightarrow\; M_{\tau[\theta]} \models \mathsf{Predictable}(c).$$

Under Forge, a passing run samples finitely many environments and yields corroborating evidence, not a constructive witness for the $\forall E$ conjunct.

That is, a passing equality test induces a trace $M_{\tau[\theta]}$ that is a model of, hence a *constructive witness* for, the $\Sigma_1^1$ statement $\mathsf{Predictable}(c)$. Here $\models$ interprets the static atoms on $\mathcal{P}_0 = \mathrm{Slither}(c)$ and the runtime equality on the trace $\mathcal{P}_1$.

**Setup.** Recall the specification, with its four conjuncts labelled:

$$\begin{aligned}
\mathsf{Predictable}(c) \equiv{} &
  \exists m \in \mathsf{methods}(c).\; \exists \sigma \in \mathsf{State}.\;
  \exists F : \mathsf{State} \times \mathsf{Env} \to \mathsf{Result}.\\
  &\underbrace{\mathsf{IsCriticalDecision}(m)}_{C_1} \;\land\;
  \underbrace{\mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot))}_{C_2} \;\land\;
  \underbrace{\mathsf{EnvOnly}(F)}_{C_3} \;\land\;
  \underbrace{\bigl(\forall E \in \mathsf{Env}.\; \mathsf{Draw}(m, \sigma[E]) = F(\sigma, E)\bigr)}_{C_4}
\end{aligned}$$

The derivation $\mathsf{Predictable}(c) \vdash \tau$ is a flat tree whose leaves are the phase judgements [Holes], [Pre], [Act], and [Assrt], and whose root is [Template]. By inversion on the derivation rules, we show that each conjunct $C_1,\ldots,C_4$ is satisfied in the test-induced model $M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle$, where $\mathcal{S}$ is the many-sorted domain (EVM states, methods, block environments, result values, etc.), $\mathcal{P}_0 = \mathrm{Slither}(c)$ (supplying the static $\mathsf{IsCriticalDecision}$, $\mathsf{Influence}$, and $\mathsf{EnvOnly}$ facts), $\mathcal{P}_1$ is extracted from the trace (the equality outcome), and the witness tuple is $\mathcal{W} = (\theta(h_m),\, \theta(h_{\mathit{init}}),\, \theta(h_F)) = (m,\, \sigma,\, F)$. The second-order witness $F = \theta(h_F)$ is constructively supplied by the LLM as the mirror $h_F$; by $\mathsf{EnvOnly}(F)$ it is *eliminable* to a first-order term $t_{\mathit{obs}}$, so fixing $\theta(h_F)$ witnesses $\exists F$ and reduces $\Phi$ to a first-order sentence over $m,\sigma$.

**Step 1 ([Holes]): witnesses are well-typed.** The [Holes] rule establishes the hole signature

$$H = \bigl\{ h_m : \mathsf{Method},\; h_{\mathit{env}} : \mathsf{BlockEnvParams},\; h_F : \mathsf{FunctionExpr},\; h_{\mathit{init}} : \mathsf{State} \bigr\}$$

with $\mathit{res}(h_m) = \mathsf{Slither}$, $\mathit{res}(h_F) = \mathit{res}(h_{\mathit{init}}) = \mathsf{LLM}$, and $h_{\mathit{env}}$ made symbolic by Kontrol. By assumption $\theta(h_m) \in \mathsf{methods}(c)$ per Slither; $\theta(h_F)$ is a syntactically valid Solidity function expression (the local mirror) and $\theta(h_{\mathit{init}})$ a valid state, so $\tau[\theta]$ is a type-correct test. The universally-quantified environment $E$ is supplied by $h_{\mathit{env}}$, held symbolic over the read subset $R$ (Step 2).

**Lemma (Hole Typing).** If $\vdash H : \tau$ and $\tau[\theta]$ does not revert on a type error, then $\mathcal{W} = (m, \sigma, F)$ is a valid witness candidate for the existential prefix of $\mathsf{Predictable}(c)$ (with $m, \sigma$ first-order and $F$ the second-order witness). ✓

**Step 2 ([Pre]): conjuncts $C_1$, $C_2$, $C_3$ discharged; $\sigma$ and the $\forall E$ binder realized.** The [Pre] rule fires because $\mathsf{IsCriticalDecision}(m)$, $\mathsf{EnvOnly}(F)$, and $\mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot))$ are conjuncts of $\Phi$, and derives the $\tt setUp$ phase

$$h_{\mathit{init}};\; \texttt{vm.assume}(\cdot);\; \bigl(\mathit{cheat}_e(h_{\mathit{env}}.e)\bigr)_{e \in R}, \quad R = \{e \in E_{\mathit{unsafe}} \mid \mathsf{Influence}(\{e\}, \mathsf{Draw}(m,\cdot)) \lor \mathsf{Influence}(\{e\}, F)\},$$

where $\mathit{cheat}_e \in \{\texttt{vm.warp}, \texttt{vm.roll}, \texttt{vm.prevrandao}, \texttt{vm.coinbase}, \texttt{vm.fee}\}$. When the test runs, *setUp* establishes $\sigma$ (reachable, by the reachability condition — the storage cheatcodes only *read* the draw's inputs, never fabricate $\sigma$) and makes each block field in $R$ symbolic. The three static conjuncts are $\mathcal{P}_0$ facts discharged at $h_m$/$h_F$ selection, never observed on the trace:

- $C_1 = \mathsf{IsCriticalDecision}(m) \in \mathcal{P}_0$, by the Slither/LLM classifier (Critical-decision-identification premise);
- $C_2 = \mathsf{Influence}(E_{\mathit{unsafe}}, \mathsf{Draw}(m,\cdot)) \in \mathcal{P}_0$, by Slither's data-flow analysis (the draw genuinely depends on a manipulable block field);
- $C_3 = \mathsf{EnvOnly}(F) \in \mathcal{P}_0$, by the static observability check on $h_F$ (the mirror reads only attacker-observable data, classes (a)–(d); Mirror-observability premise).

This establishes $C_1, C_2, C_3$ ($M_{\tau[\theta]} \models C_1 \land C_2 \land C_3$). By the Read-set-completeness premise, $R$ contains every field read by $\mathsf{Draw}$ *or* by $F$, so fields outside $R$ leave both invariant; symbolic coverage over $R$ therefore suffices for the full $\forall E$ (Step 4). ✓

**Step 3 ([Act]): the runtime draw and mirror.** The [Act] rule fires because the equality conjunct $\forall E \in \mathsf{Env}.\, \mathsf{Draw}(m,\sigma[E]) = F(\sigma, E)$ is a conjunct of $\Phi$, and derives the $\tt action$ phase $\mathit{expectedRandom} = h_F(\sigma_{\mathit{view}}, h_{\mathit{env}});\; \mathit{actualRandom} = \mathit{victim}.h_m()$. When the test runs, $\mathit{victim}.h_m()$ computes the contract's draw $\mathsf{Draw}(m, \sigma[E])$ under the symbolic environment $E = h_{\mathit{env}}$, captured as $\mathit{actualRandom}$; and $h_F(\sigma_{\mathit{view}}, h_{\mathit{env}})$ computes the mirror $F(\sigma, E)$ from the attacker-observable view $\sigma_{\mathit{view}}$ (the projection of $\sigma$ onto observable classes (a)–(c)) and the *same* $E$, captured as $\mathit{expectedRandom}$. Since $\mathsf{Draw}$ depends on $\sigma$ only through this observable view, the runtime pair $(\mathit{actualRandom}, \mathit{expectedRandom})$ faithfully realizes $(\mathsf{Draw}(m,\sigma[E]), F(\sigma,E))$ for the symbolic $E$. ✓

**Step 4 ([Assrt]): conjunct $C_4$ satisfied.** The [Assrt] rule fires because the equality conjunct is a conjunct of $\Phi$, and derives the $\tt assert$ phase $\texttt{assertEq}(\mathit{actualRandom}, \mathit{expectedRandom})$. The defect-indicating outcome — the test passing — occurs *iff* $\mathit{actualRandom} = \mathit{expectedRandom}$ on every explored environment. Under Kontrol, with the read subset $R$ held symbolic and constrained only by the *setUp* feasibility assumptions (which prune unreachable environments such as past block numbers/timestamps and overflowing values, never any realizable on-chain block), a passing $\texttt{assertEq}$ establishes $\mathsf{Draw}(m,\sigma[E]) = F(\sigma, E)$ for every feasible $E$ over the entire space on which either the draw or the mirror depends; by Read-set completeness, fields outside $R$ leave both sides invariant, so the equality extends to *all* reachable $E \in \mathsf{Env}$. Hence $\forall E \in \mathsf{Env}.\, \mathsf{Draw}(m,\sigma[E]) = F(\sigma, E)$ over the realizable environment space, establishing $C_4$ ($M_{\tau[\theta]} \models C_4$). Symbolising exactly $R$ closes the corner where a mirror coinciding with $\mathsf{Draw}$ only at a pinned default (e.g. a draw over $\tt block.basefee$) would otherwise pass spuriously. ✓

**Key observation.** A passing $\texttt{assertEq}$ under Kontrol's symbolic $R$ is equivalent to the satisfaction of the universal equality atom $\forall E.\, \mathsf{Draw}(m,\sigma[E]) = F(\sigma,E)$ in $\mathcal{P}_1$; combined with the static $C_1, C_2, C_3 \in \mathcal{P}_0$, every conjunct $C_1$–$C_4$ is established. Because $C_4$ is a genuine universal over the unbounded environment domain, only Kontrol's symbolic coverage discharges it; a passing Forge run samples finitely many $E$ and is corroborating evidence, not a constructive witness. The second-order $\exists F$ is constructively witnessed by $\theta(h_F)$: $\mathsf{EnvOnly}(F)$ makes $F$ eliminable to the first-order term $t_{\mathit{obs}} = h_F$, so the $\Sigma_1^1$ sentence reduces to the first-order $\forall E.\, \mathsf{Draw}(m,\sigma[E]) = t_{\mathit{obs}}(\sigma,E)$ that the test discharges. ✓

**Step 5 ([Template]): global assembly.** The [Template] rule at the root of the derivation tree is

$$\dfrac{\displaystyle \Phi \vdash H \quad \Phi \vdash_{\mathit{setUp}} S \quad \Phi \vdash_{\mathit{action}} A \quad \Phi \vdash_{\mathit{assert}} \mathit{AS}}{\displaystyle \Phi \vdash \langle H, S, A, \mathit{AS}\rangle} \quad \text{[Template]}$$

with $\Phi = \mathsf{Predictable}(c)$. By Steps 1–4, each premise is established and each conjunct $C_1,\ldots,C_4$ holds in $M_{\tau[\theta]}$, with $C_1, C_2, C_3$ discharged in *setUp* and $C_4$ witnessed across *action* and *assert*. Since $\mathcal{W} = (\theta(h_m), \theta(h_{\mathit{init}}), \theta(h_F)) = (m, \sigma, F)$ witnesses all three existentials — $m$ the critical-decision method selected by Slither, $\sigma$ the reachable context state, and $F$ the attacker-observable mirror (the second-order witness, eliminable to $t_{\mathit{obs}}$) — all conjuncts hold simultaneously under $(\mathcal{P}_0, \mathcal{P}_1, \mathcal{W})$:

$$M_{\tau[\theta]} = \langle \mathcal{S}, \mathcal{P}_0, \mathcal{P}_1, \mathcal{W}\rangle \;\models\; \mathsf{Predictable}(c). \qquad\square$$

**Scope.** The theorem does *not* claim uniqueness of the witness. Completeness is bounded in two ways: the universal $\forall E$ over-approximates the operational threat — a draw predictable only at the targeted block's environment $E^\ast$ but not on all of $\mathsf{Env}$ fails $\forall E$ and is a false negative — and, as a tooling limitation, $\tt blockhash$ is omitted from $E_{\mathit{unsafe}}$ (no Forge cheatcode sets it). Soundness holds *only under Kontrol*, where symbolising the read subset $R$ discharges the universal $\forall E$ (Forge merely samples), and is conditional on three static premises: *Read-set completeness* (an under-approximate $R$ holds a read field constant and is a false-negative source), *Critical-decision identification* (an over-broad classifier flags an inconsequential draw — a false positive), and *Mirror-observability soundness* (an $\mathsf{EnvOnly}$ that wrongly passes a mirror secretly reading non-observable data is the dangerous false-positive channel), together with reachability of $\sigma$. Committed-randomness (VRF/commit–reveal) is excluded by $\mathsf{Influence}$ (the draw then depends on stored randomness, not $E_{\mathit{unsafe}}$) and future-block entropy by the universal equality (no observable $F$ reproduces it).
