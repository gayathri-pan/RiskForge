# 🛡️ RiskForge

## Risk, Fraud & Regulatory Intelligence Copilot

RiskForge is a Snowflake-native investigation copilot that helps investigators connect **customer/account data, transaction activity, automated risk signals, and policy guidance** in one workflow.

The project combines Snowflake structured analytics, Cortex Search, Cortex Agents, Agent Skills, and Streamlit to create an evidence-grounded investigation experience.

> **Disclaimer:** This project uses synthetic demonstration data and synthetic policy/procedure documents. It is not a production AML/compliance system and must not be treated as legal or regulatory advice.

---

## 🎯 Problem

Risk and fraud investigations often require an investigator to correlate information spread across:

- Customer and account profiles
- Transaction history
- Risk detection outputs
- Supporting evidence
- Internal policies and procedures

RiskForge demonstrates how an AI agent can bring these sources together and guide an investigator through a repeatable workflow.

---

## 💡 Solution

RiskForge provides an investigation workspace where an investigator can:

1. Select a customer/case.
2. Review the customer and account profile.
3. Review computed risk signals.
4. Drill into transaction-level evidence.
5. Ask natural-language questions through a Cortex Agent.
6. Retrieve relevant policy/procedure guidance.
7. Continue the investigation through a multi-turn conversation.
8. Receive dynamically generated text, tables, charts, and source evidence.

---

## 🏗️ Architecture

```text
                     ┌─────────────────────────────┐
                     │       Streamlit UI          │
                     │  Overview | Evidence |      │
                     │  Copilot | Policy           │
                     └─────────────┬───────────────┘
                                   │
                                   ▼
                     ┌─────────────────────────────┐
                     │      Cortex Agent           │
                     │     RISKFORGE_AGENT         │
                     └─────────────┬───────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
             Investigation      RiskAnalyst   RegulatorySearch
                Skill               │              │
                    │               ▼              ▼
                    │        Semantic View    Cortex Search
                    │          RISK_          REGULATORY_
                    │       INTELLIGENCE        SEARCH
                    │
                    └──────────────┬──────────────┘
                                   ▼
                       Evidence-grounded
                        investigation
```

### Main Snowflake components

| Component | Purpose |
|---|---|
| `RFR_COPILOT.RAW.CUSTOMERS` | Customer profile data |
| `RFR_COPILOT.RAW.ACCOUNTS` | Account information |
| `RFR_COPILOT.RAW.TRANSACTIONS` | Synthetic transaction data |
| `RFR_COPILOT.ANALYTICS` | Risk findings, evidence and semantic layer |
| `RFR_COPILOT.AI.REGULATORY_SEARCH` | Policy/procedure retrieval |
| `RFR_COPILOT.AI.RISKFORGE_AGENT` | AI orchestration |
| `investigate-risk-case` | Reusable investigation workflow |
| Streamlit | Investigator-facing application |

---

## 📊 Synthetic Risk Scenarios

The demo dataset contains synthetic customers, accounts, and transactions designed to exercise multiple detection scenarios.

Key scenarios include:

- **Transaction velocity**
- **Amount anomaly**
- **Structuring / near-threshold activity**
- **Geographic anomaly**
- **Behavioral anomaly**
- **Multi-signal investigation**

### Example: C00506

Customer `C00506` is the primary demonstration case.

The synthetic case contains:

- Risk score: `100 / 100`
- Finding level: `CRITICAL`
- 12 computed risk signals
- 4 signal categories
- 5 closely timed international transfers
- Transaction evidence across India, United Kingdom, and Singapore
- Policy evidence retrieved through Cortex Search

The application is designed to distinguish **observed transaction evidence**, **computed risk signals**, and **policy guidance**.

---

## 🤖 Cortex Agent

The `RISKFORGE_AGENT` orchestrates two main tools:

### RiskAnalyst

Uses the semantic view:

```text
RFR_COPILOT.ANALYTICS.RISK_INTELLIGENCE
```

It supports questions about:

- Customers
- Accounts
- Transactions
- Risk findings
- Risk scores
- Risk signals
- Investigation evidence

### RegulatorySearch

Uses:

```text
RFR_COPILOT.AI.REGULATORY_SEARCH
```

It retrieves relevant demonstration policy and procedure sections.

---

## 🧩 Agent Skill

RiskForge includes a reusable Cortex Agent Skill:

```text
investigate-risk-case
```

The skill defines a repeatable workflow:

```text
Identify case
    ↓
Retrieve customer/account profile
    ↓
Retrieve computed risk signals
    ↓
Retrieve transaction evidence
    ↓
Retrieve applicable policy
    ↓
Compare evidence with policy
    ↓
Produce investigation assessment
```

This separates:

- **Tools** → what the Agent can access
- **Skill** → how the Agent should perform a repeatable investigation

---

## 💬 Multi-turn Investigation

RiskForge supports threaded conversations.

Example:

```text
User:
Why is C00506 critical?

RiskForge:
[Investigation response]

User:
Show only the structuring evidence.

RiskForge:
[Structuring evidence]

User:
Which policy supports that?

RiskForge:
[Applicable policy section]
```

The conversation uses a Cortex Agent thread with a `thread_id` and `parent_message_id` to maintain context across turns.

---

## 📈 Dynamic Response Rendering

The Streamlit application does not hardcode a response schema for individual questions.

Agent response content is rendered based on its returned type:

```text
text
  → Markdown

table
  → Streamlit DataFrame

chart
  → Vega-Lite chart

annotations
  → Policy/source evidence

suggested_queries
  → Clickable follow-up questions
```

This allows different investigation questions to produce different combinations of text, tables, charts, and evidence.

---

## 🖥️ Streamlit Application

The Streamlit application contains four main areas:

### Overview

- Customer profile
- Account information
- Risk level
- Risk score
- Signal summary
- Documented investigation action

### Evidence

- Risk signal cards
- Transaction timeline
- Signal score visualization
- Transaction-level evidence
- Detailed signal evidence

### Copilot

- Multi-turn Cortex Agent chat
- Dynamic Agent responses
- Clickable suggested questions

### Policy

- Retrieved policy/procedure evidence
- Source document information
- Relevant policy sections

---

## 🚀 Setup Overview

### 1. Create Snowflake objects

Create the required:

- Database
- Schemas
- Warehouse
- Raw tables
- Analytics objects
- Semantic View
- Cortex Search Service
- Cortex Agent

Example database structure:

```text
RFR_COPILOT
├── RAW
├── ANALYTICS
└── AI
```

### 2. Load synthetic data

Populate:

```text
CUSTOMERS
ACCOUNTS
TRANSACTIONS
```

Use the SQL generation scripts in the `sql/` directory.

### 3. Build risk detection outputs

Create and populate the risk signal and investigation evidence objects.

### 4. Configure Cortex Search

Load the demonstration policy/procedure documents and create:

```text
RFR_COPILOT.AI.REGULATORY_SEARCH
```

### 5. Configure Cortex Agent

Configure:

```text
RFR_COPILOT.AI.RISKFORGE_AGENT
```

with:

- `RiskAnalyst`
- `RegulatorySearch`
- `investigate-risk-case`
- Warehouse execution environment

### 6. Run Streamlit

Deploy the Streamlit application in:

```text
RFR_COPILOT.AI
```

with:

```text
Compute Pool: SYSTEM_COMPUTE_POOL_CPU
Query Warehouse: RFR_WH
Runtime: Container Runtime
```

---

## 🧪 Example Questions

Try these in the RiskForge Copilot:

```text
Why is C00506 critical?
```

```text
Show only the structuring evidence.
```

```text
Which policy supports that?
```

```text
Are there other transactions in the same window?
```

```text
What is the home country of C00506?
```

```text
Investigate customer C00506 and produce a complete evidence-grounded investigation report.
```

```text
Compare the risk signals for C00506 and other critical findings.
```

---

## 🔐 Governance & Safety Design

The Agent instructions are designed to:

- Treat automated risk signals as indicators, not proof of financial crime.
- Separate observed evidence from computed signals.
- Preserve policy language such as `may` and `should`.
- Avoid inventing transactions or policy requirements.
- Preserve the currency stored in the database.
- Distinguish synthetic demonstration policies from actual regulations.
- State limitations when evidence is incomplete.

---



Only include SQL/scripts that are safe to publish. Do **not** commit passwords, tokens, private keys, or other credentials.

---

## 🎥 Suggested Demo Flow

A short demonstration can follow this sequence:

### 1. Open RiskForge

Show the selected case:

```text
Customer: C00506
Account: A00506
Risk Score: 100
Risk Level: CRITICAL
Signals: 12
```

### 2. Open Evidence

Show:

- 5 transactions
- 12 signal records
- 4 signal categories
- transaction timeline

### 3. Open Copilot

Ask:

```text
Why is C00506 critical?
```

### 4. Continue the investigation

Ask:

```text
Show only the structuring evidence.
```

Then:

```text
Which policy supports that?
```

### 5. Show Policy

Demonstrate the retrieved policy/procedure evidence.

### 6. Explain the architecture

Highlight:

```text
Snowflake structured data
+
Cortex Analyst
+
Cortex Search
+
Cortex Agent
+
Agent Skill
+
Streamlit
```

---

## 🏆 Project Highlights

RiskForge demonstrates:

- Snowflake-native AI orchestration
- Governed structured analytics
- Retrieval-augmented policy search
- Reusable Cortex Agent Skills
- Multi-turn Agent conversations
- Evidence-grounded investigation
- Dynamic AI-generated tables and charts
- Investigator-oriented Streamlit experience
- Synthetic end-to-end risk/fraud workflow

---

## ⚠️ Disclaimer

RiskForge is a hackathon demonstration built with synthetic data and demonstration policy documents.

It is not intended to:

- determine whether a person or organization committed financial crime
- replace compliance professionals
- provide legal or regulatory advice
- make real-world suspicious activity determinations
- represent actual regulatory reporting thresholds

All automated signals and Agent-generated assessments should be treated as investigation aids requiring appropriate human review.

---

## 📌 Hackathon

**Project:** RiskForge  
**Category:** AI / Data / Risk & Fraud Investigation  
**Platform:** Snowflake  
**AI:** Snowflake Cortex  
**UI:** Streamlit
