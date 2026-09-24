import streamlit as st
import pandas as pd
import requests
import os
import json


# ============================================================
# PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="RiskForge",
    page_icon="🛡️",
    layout="wide"
)


# ============================================================
# SNOWFLAKE CONNECTION
# ============================================================

conn = st.connection("snowflake")
session = conn.session()


# ============================================================
# SESSION TOKEN
# ============================================================

def get_session_token() -> str:
    """Read the Snowflake OAuth/session token."""

    token_path = "/snowflake/session/token"

    if not os.path.exists(token_path):
        raise RuntimeError(
            "Snowflake session token was not found."
        )

    with open(
        token_path,
        "r",
        encoding="utf-8"
    ) as file:

        token = file.read().strip()

    if not token:
        raise RuntimeError(
            "Snowflake session token is empty."
        )

    return token


# ============================================================
# CREATE CORTEX AGENT THREAD
# ============================================================

def create_agent_thread() -> dict:
    """Create a new Cortex Agent thread."""

    host = os.getenv("SNOWFLAKE_HOST")

    if not host:
        raise RuntimeError(
            "SNOWFLAKE_HOST environment variable is not available."
        )

    url = (
        f"https://{host}"
        "/api/v2/cortex/threads"
    )

    headers = {
        "Authorization": f"Bearer {get_session_token()}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Snowflake-Authorization-Token-Type": "OAUTH"
    }

    response = requests.post(
        url,
        headers=headers,
        json={
            "origin_application": "riskforge"
        },
        timeout=30
    )

    if not response.ok:
        raise RuntimeError(
            f"Thread creation failed "
            f"({response.status_code}): "
            f"{response.text}"
        )

    result = response.json()

    if "thread_id" not in result:
        raise RuntimeError(
            f"Thread creation returned no thread_id: {result}"
        )

    return result


# ============================================================
# CALL RISKFORGE AGENT
# ============================================================

def call_riskforge_agent(
    prompt: str,
    thread_id: int,
    parent_message_id: int
) -> dict:
    """Send one user message to RiskForge."""

    host = os.getenv("SNOWFLAKE_HOST")

    if not host:
        raise RuntimeError(
            "SNOWFLAKE_HOST environment variable is not available."
        )

    url = (
        f"https://{host}"
        "/api/v2/databases/RFR_COPILOT"
        "/schemas/AI"
        "/agents/RISKFORGE_AGENT:run"
    )

    headers = {
        "Authorization": f"Bearer {get_session_token()}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Snowflake-Authorization-Token-Type": "OAUTH"
    }

    request_body = {
        "thread_id": thread_id,
        "parent_message_id": parent_message_id,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt
                    }
                ]
            }
        ],
        "stream": False,
        "background": False
    }

    response = requests.post(
        url,
        headers=headers,
        json=request_body,
        timeout=900
    )

    if not response.ok:
        raise RuntimeError(
            f"Agent request failed "
            f"({response.status_code}): "
            f"{response.text}"
        )

    return response.json()


# ============================================================
# DYNAMIC TABLE RENDERER
# ============================================================

def render_agent_table(table_item: dict) -> None:
    """Render an Agent-generated table dynamically."""

    table = table_item.get(
        "table",
        {}
    )

    result_set = table.get(
        "result_set",
        {}
    )

    data = result_set.get(
        "data",
        []
    )

    metadata = result_set.get(
        "resultSetMetaData",
        {}
    )

    row_type = metadata.get(
        "rowType",
        []
    )

    columns = [
        column.get("name")
        for column in row_type
        if column.get("name")
    ]

    if not data:
        st.info("The Agent returned an empty table.")
        return

    if columns:
        rows = [
            dict(zip(columns, row))
            for row in data
        ]
    else:
        rows = data

    df = pd.DataFrame(rows)

    st.dataframe(
        df,
        use_container_width=True,
        hide_index=True
    )


# ============================================================
# DYNAMIC CHART RENDERER
# ============================================================

def render_agent_chart(chart_item: dict) -> None:
    """Render Agent-generated Vega-Lite charts."""

    chart_obj = chart_item.get(
        "chart",
        {}
    )

    chart_spec = chart_obj.get(
        "chart_spec"
    )

    if chart_spec:

        if isinstance(
            chart_spec,
            str
        ):

            try:
                chart_spec = json.loads(chart_spec)

            except json.JSONDecodeError:

                st.warning(
                    "Unable to parse Agent chart specification."
                )

                return

        st.vega_lite_chart(
            chart_spec,
            use_container_width=True
        )

        return

    charts = chart_obj.get(
        "charts",
        []
    )

    if charts:

        for chart in charts:

            if isinstance(
                chart,
                str
            ):

                try:
                    chart_spec = json.loads(chart)

                except json.JSONDecodeError:

                    continue

            elif isinstance(
                chart,
                dict
            ):

                chart_spec = chart

            else:

                continue

            st.vega_lite_chart(
                chart_spec,
                use_container_width=True
            )

        return

    st.info(
        "The Agent returned a chart, "
        "but no usable chart specification was found."
    )


# ============================================================
# DYNAMIC SOURCES / CITATIONS
# ============================================================

def render_agent_annotations(item: dict) -> None:
    """Render Cortex Search citations."""

    annotations = item.get(
        "annotations",
        []
    )

    if not annotations:
        return

    with st.expander(
        "📚 Sources & Policy Evidence"
    ):

        seen = set()

        for annotation in annotations:

            doc_title = annotation.get(
                "doc_title",
                "Source"
            )

            doc_id = annotation.get(
                "doc_id",
                ""
            )

            text = annotation.get(
                "text",
                ""
            )

            key = (
                doc_id,
                text
            )

            if key in seen:
                continue

            seen.add(key)

            st.markdown(
                f"**{doc_title}**"
            )

            if doc_id:
                st.caption(doc_id)

            if text:
                st.write(text)

            st.divider()


# ============================================================
# EXTRACT SUGGESTED QUESTIONS
# ============================================================

def extract_suggested_queries(
    agent_response: dict
) -> list[str]:

    content = agent_response.get(
        "content",
        []
    )

    queries = []

    for item in content:

        if "suggested_queries" not in item:
            continue

        suggested = item.get(
            "suggested_queries",
            []
        )

        for query in suggested:

            if isinstance(
                query,
                dict
            ):

                text = query.get(
                    "query"
                )

            elif isinstance(
                query,
                str
            ):

                text = query

            else:

                text = None

            if text and text not in queries:

                queries.append(text)

    return queries


# ============================================================
# DYNAMIC AGENT RESPONSE
# ============================================================

def render_agent_response(
    agent_response: dict,
    message_key: str = "current"
) -> None:
    """
    Render text, tables, charts, citations and suggested questions.
    """

    content = agent_response.get(
        "content",
        []
    )

    suggested_questions = []

    for item in content:

        item_type = item.get(
            "type"
        )

        # ----------------------------------------------------
        # TEXT
        # ----------------------------------------------------

        if item_type == "text":

            text = item.get(
                "text",
                ""
            ).strip()

            if text:

                st.markdown(
                    text
                )

        # ----------------------------------------------------
        # TABLE
        # ----------------------------------------------------

        elif item_type == "table":

            title = item.get(
                "title"
            )

            if title:

                st.markdown(
                    f"#### {title}"
                )

            render_agent_table(
                item
            )

        # ----------------------------------------------------
        # CHART
        # ----------------------------------------------------

        elif item_type == "chart":

            render_agent_chart(
                item
            )

        # ----------------------------------------------------
        # ANNOTATIONS
        # ----------------------------------------------------

        elif (
            item_type == "annotations"
            or
            "annotations" in item
        ):

            render_agent_annotations(
                item
            )

        # ----------------------------------------------------
        # SUGGESTIONS
        # ----------------------------------------------------

        suggestions = extract_suggested_queries(
            {
                "content": [item]
            }
        )

        suggested_questions.extend(
            suggestions
        )

    unique_questions = list(
        dict.fromkeys(
            suggested_questions
        )
    )

    # --------------------------------------------------------
    # Clickable suggestions
    # --------------------------------------------------------

    if unique_questions:

        st.markdown(
            "### 💡 Suggested Questions"
        )

        for index, question in enumerate(
            unique_questions
        ):

            button_key = (
                f"suggested_"
                f"{message_key}_"
                f"{index}"
            )

            if st.button(
                question,
                key=button_key,
                use_container_width=True
            ):

                st.session_state.pending_prompt = (
                    question
                )

                st.rerun()


# ============================================================
# LOAD CASES
# ============================================================

cases = session.sql(
    """
    SELECT
        FINDING_ID,
        CUSTOMER_ID,
        ACCOUNT_ID,
        CUSTOMER_NAME,
        CUSTOMER_COUNTRY,
        CUSTOMER_TYPE,
        CUSTOMER_RISK_LEVEL,
        KYC_STATUS,
        ACCOUNT_TYPE,
        CURRENCY,
        BALANCE,
        FINDING_TYPE,
        RISK_LEVEL,
        RISK_SCORE,
        SIGNAL_COUNT,
        SIGNAL_TYPES,
        FINDING_TITLE,
        FINDING_SUMMARY,
        RECOMMENDED_ACTION,
        FINDING_STATUS,
        CREATED_AT

    FROM RFR_COPILOT.ANALYTICS.RISK_CASE_OVERVIEW

    ORDER BY
        RISK_SCORE DESC,
        SIGNAL_COUNT DESC
    """
).to_pandas()


if cases.empty:

    st.warning(
        "No investigation cases were found."
    )

    st.stop()


# ============================================================
# SIDEBAR
# ============================================================

st.sidebar.header(
    "🔎 Investigation"
)

customer_ids = (
    cases["CUSTOMER_ID"]
    .dropna()
    .tolist()
)

default_index = (
    customer_ids.index("C00506")
    if "C00506" in customer_ids
    else 0
)

selected_customer = st.sidebar.selectbox(
    "Select customer",
    customer_ids,
    index=default_index
)


# ============================================================
# SELECTED CASE
# ============================================================

selected_case = (
    cases[
        cases["CUSTOMER_ID"]
        == selected_customer
    ]
    .iloc[0]
)

customer_id = selected_case[
    "CUSTOMER_ID"
]

account_id = selected_case[
    "ACCOUNT_ID"
]


# ============================================================
# THREAD MANAGEMENT
# ============================================================

thread_missing = (
    "agent_thread_id"
    not in st.session_state
)

customer_changed = (
    st.session_state.get(
        "thread_customer_id"
    )
    != selected_customer
)

if (
    thread_missing
    or
    customer_changed
):

    with st.spinner(
        "Starting investigation thread..."
    ):

        try:

            thread = create_agent_thread()

            st.session_state.agent_thread_id = (
                thread["thread_id"]
            )

            st.session_state.parent_message_id = 0

            st.session_state.thread_customer_id = (
                selected_customer
            )

            st.session_state.chat_messages = []

            st.session_state.latest_agent_response = None

        except Exception as e:

            st.error(
                f"Unable to create Agent thread: {str(e)}"
            )

            st.stop()


# ============================================================
# NEW INVESTIGATION
# ============================================================

if st.sidebar.button(
    "🆕 New Investigation"
):

    with st.spinner(
        "Creating new investigation..."
    ):

        try:

            thread = create_agent_thread()

            st.session_state.agent_thread_id = (
                thread["thread_id"]
            )

            st.session_state.parent_message_id = 0

            st.session_state.thread_customer_id = (
                selected_customer
            )

            st.session_state.chat_messages = []

            st.session_state.latest_agent_response = None

            st.session_state.pop(
                "pending_prompt",
                None
            )

            st.rerun()

        except Exception as e:

            st.sidebar.error(
                f"Unable to create new investigation: {str(e)}"
            )


# ============================================================
# SIDEBAR THREAD INFO
# ============================================================

with st.sidebar.expander(
    "🔗 Conversation Info"
):

    st.caption(
        f"Customer: {customer_id}"
    )

    st.caption(
        f"Thread ID: "
        f"{st.session_state.agent_thread_id}"
    )

    st.caption(
        f"Parent Message ID: "
        f"{st.session_state.parent_message_id}"
    )


# ============================================================
# HEADER
# ============================================================

st.title(
    "🛡️ RiskForge"
)

st.caption(
    "Risk, Fraud & Regulatory Intelligence Copilot"
)

st.divider()


# ============================================================
# INVESTIGATION HEADER
# ============================================================

header_col1, header_col2, header_col3, header_col4 = (
    st.columns(4)
)

header_col1.metric(
    "Customer",
    customer_id
)

header_col2.metric(
    "Account",
    account_id
)

header_col3.metric(
    "Risk Score",
    f"{float(selected_case['RISK_SCORE']):.0f} / 100"
)

header_col4.metric(
    "Signals",
    int(selected_case["SIGNAL_COUNT"])
)

st.caption(
    f"Risk Level: {selected_case['RISK_LEVEL']}  •  "
    f"Finding: {selected_case['FINDING_TYPE']}"
)


# ============================================================
# LOAD SIGNAL EVIDENCE
# ============================================================

safe_customer_id = (
    customer_id
    .replace("'", "''")
)

signals = session.sql(
    f"""
    SELECT
        TRANSACTION_ID,
        SIGNAL_TYPE,
        SIGNAL_SEVERITY,
        SIGNAL_SCORE,
        TRANSACTION_TIMESTAMP,
        AMOUNT,
        TRANSACTION_COUNTRY,
        TRANSACTION_TYPE,
        CHANNEL,
        MERCHANT,
        SIGNAL_EVIDENCE

    FROM RFR_COPILOT.ANALYTICS.INVESTIGATION_SIGNAL_EVIDENCE

    WHERE CUSTOMER_ID = '{safe_customer_id}'

    ORDER BY
        TRANSACTION_TIMESTAMP,
        SIGNAL_TYPE
    """
).to_pandas()


# ============================================================
# LOAD TABS
# ============================================================

tab_overview, tab_evidence, tab_copilot, tab_policy = st.tabs(
    [
        "📋 Overview",
        "🚩 Evidence",
        "🤖 Copilot",
        "📚 Policy"
    ]
)


# ============================================================
# TAB 1 — OVERVIEW
# ============================================================

with tab_overview:

    st.subheader(
        "📋 Case Overview"
    )

    profile_col, finding_col = st.columns(
        [1, 1]
    )

    # --------------------------------------------------------
    # Customer profile
    # --------------------------------------------------------

    with profile_col:

        st.markdown(
            "### 👤 Customer Profile"
        )

        profile_data = pd.DataFrame(
            {
                "Field": [
                    "Customer Name",
                    "Customer Type",
                    "Home Country",
                    "Baseline Risk",
                    "KYC Status",
                    "Account Type",
                    "Currency",
                    "Account Balance"
                ],

                "Value": [
                    selected_case["CUSTOMER_NAME"],
                    selected_case["CUSTOMER_TYPE"],
                    selected_case["CUSTOMER_COUNTRY"],
                    selected_case["CUSTOMER_RISK_LEVEL"],
                    selected_case["KYC_STATUS"],
                    selected_case["ACCOUNT_TYPE"],
                    selected_case["CURRENCY"],

                    (
                        f"{selected_case['CURRENCY']} "
                        f"{float(selected_case['BALANCE']):,.2f}"
                    )
                ]
            }
        )

        st.dataframe(
            profile_data,
            use_container_width=True,
            hide_index=True
        )

    # --------------------------------------------------------
    # Risk finding
    # --------------------------------------------------------

    with finding_col:

        st.markdown(
            "### 🚨 Risk Finding"
        )

        st.markdown(
            f"**Finding Type:** "
            f"{selected_case['FINDING_TYPE']}"
        )

        st.markdown(
            f"**Risk Level:** "
            f"{selected_case['RISK_LEVEL']}"
        )

        st.markdown(
            f"**Signal Types:** "
            f"{selected_case['SIGNAL_TYPES']}"
        )

        st.info(
            selected_case["FINDING_SUMMARY"]
        )

    # --------------------------------------------------------
    # Investigation action
    # --------------------------------------------------------

    st.divider()

    st.subheader(
        "✅ Documented Investigation Action"
    )

    st.warning(
        selected_case[
            "RECOMMENDED_ACTION"
        ]
    )

    st.caption(
        "Automated risk signals are indicators for investigation "
        "and are not by themselves a determination of illicit activity."
    )


# ============================================================
# TAB 2 — EVIDENCE
# ============================================================


with tab_evidence:

    st.subheader("🚩 Risk Evidence")

    if signals.empty:

        st.info(
            "No signal evidence found for this case."
        )

    else:

        # ====================================================
        # SIGNAL SUMMARY CARDS
        # ====================================================

        st.markdown("### Signal Summary")

        signal_summary = (
            signals
            .groupby("SIGNAL_TYPE")
            .agg(
                Occurrences=(
                    "SIGNAL_TYPE",
                    "count"
                ),
                Max_Score=(
                    "SIGNAL_SCORE",
                    "max"
                ),
                Max_Severity=(
                    "SIGNAL_SEVERITY",
                    "first"
                )
            )
            .reset_index()
            .sort_values(
                "Max_Score",
                ascending=False
            )
        )

        # Display up to 4 signal cards per row.
        card_columns = st.columns(
            max(1, len(signal_summary))
        )

        for index, row in signal_summary.iterrows():

            card_position = list(
                signal_summary.index
            ).index(index)

            with card_columns[card_position]:

                signal_type = row[
                    "SIGNAL_TYPE"
                ]

                occurrences = int(
                    row["Occurrences"]
                )

                max_score = float(
                    row["Max_Score"]
                )

                severity = row[
                    "Max_Severity"
                ]

                # Friendly display name
                display_name = (
                    signal_type
                    .replace("_", " ")
                    .title()
                )

                st.metric(
                    display_name,
                    f"{occurrences} signal"
                    f"{'s' if occurrences != 1 else ''}",
                    delta=f"Max score {max_score:.0f}"
                )

                st.caption(
                    f"Highest severity: {severity}"
                )


        # ====================================================
        # TRANSACTION TIMELINE
        # ====================================================

        st.divider()

        st.markdown(
            "### 📈 Transaction Timeline"
        )

        # One row per distinct transaction.
        timeline = (
            signals[
                [
                    "TRANSACTION_ID",
                    "TRANSACTION_TIMESTAMP",
                    "AMOUNT",
                    "TRANSACTION_COUNTRY",
                    "TRANSACTION_TYPE",
                    "CHANNEL"
                ]
            ]
            .drop_duplicates(
                subset=[
                    "TRANSACTION_ID"
                ]
            )
            .sort_values(
                "TRANSACTION_TIMESTAMP"
            )
        )

        if not timeline.empty:

            # ----------------------------------------------
            # Timeline summary
            # ----------------------------------------------

            timeline_col1, timeline_col2, timeline_col3 = (
                st.columns(3)
            )

            timeline_col1.metric(
                "Transactions",
                len(timeline)
            )

            timeline_col2.metric(
                "Window Amount",
                (
                    f"{selected_case['CURRENCY']} "
                    f"{timeline['AMOUNT'].sum():,.2f}"
                )
            )

            timeline_col3.metric(
                "Countries",
                timeline[
                    "TRANSACTION_COUNTRY"
                ].nunique()
            )

            # ----------------------------------------------
            # Amount timeline chart
            # ----------------------------------------------

            chart_data = (
                timeline[
                    [
                        "TRANSACTION_TIMESTAMP",
                        "AMOUNT"
                    ]
                ]
                .set_index(
                    "TRANSACTION_TIMESTAMP"
                )
                .sort_index()
            )

            st.line_chart(
                chart_data,
                use_container_width=True
            )

            # ----------------------------------------------
            # Timeline transaction table
            # ----------------------------------------------

            timeline_display = timeline.copy()

            timeline_display[
                "AMOUNT"
            ] = timeline_display[
                "AMOUNT"
            ].apply(
                lambda value:
                    f"{selected_case['CURRENCY']} "
                    f"{float(value):,.2f}"
            )

            st.dataframe(
                timeline_display,
                use_container_width=True,
                hide_index=True
            )


        # ====================================================
        # SIGNAL DISTRIBUTION
        # ====================================================

        st.divider()

        st.markdown(
            "### 📊 Signal Score Distribution"
        )

        score_chart = (
            signals[
                [
                    "SIGNAL_TYPE",
                    "SIGNAL_SCORE"
                ]
            ]
            .copy()
        )

        # Average score by signal type.
        score_summary = (
            score_chart
            .groupby("SIGNAL_TYPE")[
                "SIGNAL_SCORE"
            ]
            .mean()
            .sort_values(
                ascending=False
            )
        )

        st.bar_chart(
            score_summary,
            use_container_width=True
        )


        # ====================================================
        # TRANSACTION-LEVEL EVIDENCE
        # ====================================================

        st.divider()

        st.markdown(
            "### 📋 Transaction-Level Evidence"
        )

        display_columns = [
            "TRANSACTION_ID",
            "SIGNAL_TYPE",
            "SIGNAL_SEVERITY",
            "SIGNAL_SCORE",
            "TRANSACTION_TIMESTAMP",
            "AMOUNT",
            "TRANSACTION_COUNTRY",
            "TRANSACTION_TYPE",
            "CHANNEL"
        ]

        evidence_display = (
            signals[
                display_columns
            ]
            .copy()
        )

        evidence_display[
            "AMOUNT"
        ] = evidence_display[
            "AMOUNT"
        ].apply(
            lambda value:
                f"{selected_case['CURRENCY']} "
                f"{float(value):,.2f}"
        )

        st.dataframe(
            evidence_display,
            use_container_width=True,
            hide_index=True
        )


        # ====================================================
        # DETAILED EVIDENCE
        # ====================================================

        with st.expander(
            "🔍 View detailed signal evidence"
        ):

            for _, row in signals.iterrows():

                st.markdown(
                    f"**{row['TRANSACTION_ID']} — "
                    f"{row['SIGNAL_TYPE']} — "
                    f"{row['SIGNAL_SEVERITY']}**"
                )

                st.write(
                    row["SIGNAL_EVIDENCE"]
                )

                st.divider()


# ============================================================
# TAB 3 — COPILOT
# ============================================================

with tab_copilot:

    st.subheader(
        "🤖 Investigation Copilot"
    )

    st.caption(
        f"Active investigation: "
        f"{customer_id} / {account_id}"
    )

    # --------------------------------------------------------
    # Existing conversation
    # --------------------------------------------------------

    for message_index, message in enumerate(
        st.session_state.chat_messages
    ):

        role = message["role"]

        with st.chat_message(
            role
        ):

            if role == "user":

                st.markdown(
                    message["content"]
                )

            elif role == "assistant":

                render_agent_response(
                    message["response"],
                    message_key=f"history_{message_index}"
                )

    # --------------------------------------------------------
    # Chat input
    # --------------------------------------------------------

    user_prompt = st.chat_input(
        "Ask RiskForge about this investigation..."
    )

    # --------------------------------------------------------
    # Pending prompt from clickable suggestion
    # --------------------------------------------------------

    pending_prompt = (
        st.session_state.pop(
            "pending_prompt",
            None
        )
    )

    prompt_to_process = (
        pending_prompt
        if pending_prompt
        else user_prompt
    )

    # --------------------------------------------------------
    # Process message
    # --------------------------------------------------------

    if prompt_to_process:

        clean_prompt = (
            prompt_to_process.strip()
        )

        if not clean_prompt:

            st.warning(
                "Please enter an investigation question."
            )

        else:

            # ------------------------------------------------
            # Save user message
            # ------------------------------------------------

            st.session_state.chat_messages.append(
                {
                    "role": "user",
                    "content": clean_prompt
                }
            )

            with st.chat_message(
                "user"
            ):

                st.markdown(
                    clean_prompt
                )

            # ------------------------------------------------
            # Agent response
            # ------------------------------------------------

            with st.chat_message(
                "assistant"
            ):

                with st.spinner(
                    "RiskForge is investigating..."
                ):

                    try:

                        agent_response = (
                            call_riskforge_agent(
                                prompt=clean_prompt,

                                thread_id=(
                                    st.session_state.agent_thread_id
                                ),

                                parent_message_id=(
                                    st.session_state.parent_message_id
                                )
                            )
                        )

                        # ----------------------------------------
                        # Metadata
                        # ----------------------------------------

                        metadata = (
                            agent_response.get(
                                "metadata",
                                {}
                            )
                        )

                        returned_thread_id = (
                            metadata.get(
                                "thread_id"
                            )
                        )

                        assistant_message_id = (
                            metadata.get(
                                "assistant_message_id"
                            )
                        )

                        # ----------------------------------------
                        # Synchronize thread
                        # ----------------------------------------

                        if returned_thread_id is not None:

                            st.session_state.agent_thread_id = (
                                returned_thread_id
                            )

                        if assistant_message_id is None:

                            raise RuntimeError(
                                "Agent response did not contain "
                                "assistant_message_id."
                            )

                        st.session_state.parent_message_id = (
                            assistant_message_id
                        )

                        # ----------------------------------------
                        # Save latest Agent response
                        # ----------------------------------------

                        st.session_state.latest_agent_response = (
                            agent_response
                        )

                        # ----------------------------------------
                        # Render
                        # ----------------------------------------

                        render_agent_response(
                            agent_response,
                            message_key="live"
                        )

                        # ----------------------------------------
                        # Save conversation
                        # ----------------------------------------

                        st.session_state.chat_messages.append(
                            {
                                "role": "assistant",
                                "response": agent_response
                            }
                        )

                    except Exception as e:

                        st.error(
                            f"Unable to call RiskForge Agent: {str(e)}"
                        )


# ============================================================
# TAB 4 — POLICY
# ============================================================

with tab_policy:

    st.subheader(
        "📚 Policy & Regulatory Evidence"
    )

    latest_response = (
        st.session_state.get(
            "latest_agent_response"
        )
    )

    if latest_response is None:

        st.info(
            "Ask the Investigation Copilot a question to "
            "retrieve policy evidence."
        )

    else:

        annotations = []

        for item in latest_response.get(
            "content",
            []
        ):

            item_annotations = item.get(
                "annotations",
                []
            )

            if item_annotations:

                annotations.extend(
                    item_annotations
                )

        if not annotations:

            st.info(
                "No policy citations were returned for the "
                "latest investigation."
            )

        else:

            seen = set()

            for annotation in annotations:

                doc_title = annotation.get(
                    "doc_title",
                    "Source"
                )

                doc_id = annotation.get(
                    "doc_id",
                    ""
                )

                text = annotation.get(
                    "text",
                    ""
                )

                key = (
                    doc_id,
                    text
                )

                if key in seen:
                    continue

                seen.add(key)

                st.markdown(
                    f"### {doc_title}"
                )

                if doc_id:

                    st.caption(
                        doc_id
                    )

                if text:

                    st.write(
                        text
                    )

                st.divider()


# ============================================================
# FOOTER
# ============================================================

st.divider()

st.caption(
    "RiskForge Demo • Synthetic data • "
    "For investigation workflow demonstration only"
)