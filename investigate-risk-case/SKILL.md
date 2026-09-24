---
name: investigate-risk-case
description: Perform a structured risk investigation for a customer or account by combining customer and account profile data, computed risk signals, transaction-level evidence, and applicable RiskForge policy and investigation procedure guidance. Use this skill for questions such as why a case is high or critical risk, investigation of a customer/account, review of detected signals, supporting evidence, applicable policy, escalation guidance, or a complete investigation report.
---

# RiskForge Case Investigation Skill

## Purpose

Perform a repeatable, evidence-grounded investigation of a RiskForge
customer or account.

Use the structured RiskAnalyst tool for customer, account,
transaction, signal, risk score, and finding information.

Use the RegulatorySearch tool for RiskForge policy and investigation
procedure information.

When the request requires both structured evidence and policy
guidance, use both tools and combine their results.

---

## Investigation Workflow

### Step 1 — Identify the case

Determine the customer ID and, when available, the account ID
relevant to the investigation.

If the user provides a customer identifier such as C00506,
use that identifier to investigate the corresponding case.

Do not assume a customer or account identifier when the request
does not provide enough information.

---

### Step 2 — Retrieve the customer and account profile

Use RiskAnalyst to retrieve relevant profile information including,
when available:

- customer ID
- customer name
- customer type
- customer home country
- baseline customer risk
- KYC status
- account ID
- account type
- account currency
- account balance
- annual income
- finding type
- finding risk level
- computed risk score

Only report fields that are actually returned by the data.

---

### Step 3 — Retrieve computed risk findings

Use RiskAnalyst to identify:

- total signal count
- signal types
- signal severities
- signal scores
- finding risk level
- finding type
- finding summary

Group signals by signal type where useful.

Clearly distinguish:

- computed risk signals
- observed transaction evidence

Do not describe an automated signal as proof of financial crime.

---

### Step 4 — Retrieve transaction-level evidence

Use RiskAnalyst to retrieve transactions associated with the
detected signals.

Where available, include:

- transaction ID
- transaction timestamp
- amount
- currency
- transaction type
- channel
- merchant
- transaction country
- signal type
- signal severity
- signal score
- signal evidence

When a signal uses a rolling window, explicitly state the
window duration and the transactions counted in the window.

Do not assume that a transaction is part of a window unless the
retrieved evidence supports that conclusion.

---

### Step 5 — Retrieve applicable policy guidance

Use RegulatorySearch to retrieve policy and procedure sections
that directly relate to the detected signals.

Typical relevant sections may include:

- Transaction Velocity
- Unusual Transaction Amounts
- Near-Threshold Activity
- Geographic Activity
- Multiple Risk Indicators
- Case Review
- Evidence Documentation
- Escalation

Only cite policy sections returned by RegulatorySearch.

Treat the RiskForge regulatory documents as demonstration
documents, not as actual external regulatory requirements.

---

### Step 6 — Compare evidence with policy

For each major detected signal:

1. Identify the computed signal.
2. Identify the relevant observed transaction evidence.
3. Identify the supporting policy section.
4. Explain the relationship without adding unsupported conclusions.

Preserve the strength of the policy language.

For example:

- "may indicate" must remain "may indicate".
- "should be reviewed" must remain "should be reviewed".
- "should be escalated" must not become "must be escalated".

---

### Step 7 — Form the investigation assessment

Clearly separate the answer into:

1. Customer and Account Profile
2. Observed Transaction Evidence
3. Computed Risk Signals
4. Applicable Policy Guidance
5. Investigator Recommendation

The recommendation must be derived from the retrieved
RiskForge investigation procedure and the observed/computed
evidence.

---

## Grounding Rules

### Evidence rules

Do not invent:

- transactions
- customers
- accounts
- signal values
- policy sections
- regulatory requirements
- counterparties
- historical patterns

If information is unavailable, explicitly state that the retrieved
evidence does not establish it.

Do not infer the absence of evidence from an incomplete result.

---

### Risk interpretation rules

Do not infer criminal intent.

Do not infer:

- money laundering
- layering
- deliberate threshold avoidance
- criminal activity
- illicit activity

unless the retrieved data or policy explicitly supports that
wording.

A risk score is a computed indicator for investigation, not a
final determination of illicit activity.

---

### Customer-profile rules

Do not treat the following as independent risk signals unless
the RiskAnalyst output explicitly does so:

- account currency
- customer type
- annual income
- account balance
- KYC status
- country

Do not claim that a profile characteristic is suspicious solely
because it appears unusual.

---

### Currency rules

Preserve the currency exactly as stored in the database.

Do not convert currencies.

Do not infer exchange rates.

If the database reports INR, use INR or ₹.

---

### Threshold rules

Use the terminology present in the RiskForge data and policies.

Refer to the configured value as a "monitoring threshold" unless
the source explicitly describes it differently.

Do not convert a synthetic monitoring threshold into a claim about
a real-world regulatory reporting threshold.

---

## Output Format

For a complete case investigation, use this structure:

### Investigation Summary

State the customer, account, finding risk level, computed score,
signal count, and signal categories.

### Observed Evidence

List the relevant transaction-level facts retrieved from
RiskAnalyst.

### Computed Risk Signals

Describe each signal type, severity, score, and the evidence
supporting that computed signal.

### Applicable Policy Guidance

Identify the relevant RiskForge policy/procedure sections and
summarize what they state.

### Investigator Recommendation

Provide the documented investigation action supported by the
RiskForge Investigation Procedure.

### Analyst Caution

State that automated risk signals are indicators for investigation
and should not by themselves be treated as a final determination
of illicit activity.

---

## Missing Evidence

When the requested evidence is unavailable:

- do not fabricate it
- state exactly what is missing
- identify what should be retrieved next
- distinguish retrieved evidence from recommended next steps

---

## Multi-signal investigations

When multiple independent signal types occur for the same
customer/account:

1. summarize each signal independently
2. show the transaction evidence
3. retrieve the Multiple Risk Indicators policy section
4. retrieve the Investigation Procedure sections when relevant
5. produce a combined investigator recommendation
6. do not collapse all signals into a conclusion of wrongdoing