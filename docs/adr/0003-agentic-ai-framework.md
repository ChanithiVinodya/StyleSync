# ADR 0003: Agentic AI Framework and Orchestration Method

**Status:** Accepted
**Date:** 2026-08-20
**Deciders:** Team (all 4 members)

## Context

The assignment requires at least 4 distinct agents that plan, delegate, use
controlled tools, validate results deterministically, persist workflow
state, and pause for human approval on a high-impact action (§9.1 of the
spec). We need a framework that gives us this structure without having to
hand-build plan tracking, state persistence, and pause/resume logic from
scratch — and the framework choice needs to be justifiable in the viva,
not just "it worked."

## Decision

We will use **LangGraph** to implement the Agentic AI subsystem as a
Python service (FastAPI), called internally by the ASP.NET Core backend
only — never directly by React or Flutter, per the assignment's mandatory
backend rule.

Each of our 4 agents (Style Analysis, Designer-Matching, Budget/Scope,
Validation) is implemented as a node in a LangGraph `StateGraph`, with
explicit edges defining the delegation order. Each node is bound only to
the specific tools it needs (allow-listing). The human approval gate uses
LangGraph's `interrupt()` mechanism to pause graph execution after the
Validation Agent passes, resuming once the backend reports the client's
decision.

## Alternatives Considered

- **Microsoft Agent Framework** — a valid alternative also named in the
  spec. Rejected mainly because our team has more hands-on familiarity
  with LangGraph from the module's own labs, which reduces implementation
  risk given the 9-week timeline, and LangGraph's Python ecosystem
  integrates more directly with our chosen FastAPI service.
- **LlamaIndex agents** — strong for retrieval-heavy agent workflows, but
  our pipeline is more about structured multi-step delegation and state
  management than document retrieval, which is LangGraph's more direct
  strength.
- **Google ADK** — considered, but has less first-party documentation and
  community support at the time of writing compared to LangGraph, adding
  risk for a team without prior production experience with it.
- **Fully custom orchestration (plain Python, no framework)** — this is
  what our early skeleton used (a simple sequential function-call chain).
  Rejected as the final approach because it would require us to hand-build
  state persistence, pause/resume, and execution logging ourselves —
  exactly the plumbing LangGraph already provides, and reimplementing it
  adds risk without adding marks.

## Consequences

- The team needs to learn LangGraph's `StateGraph`, node, and
  `interrupt()` APIs specifically — mitigated by prior lab exposure.
- Workflow state persistence (ADR 0004) is naturally tied to this choice,
  since LangGraph ships an official Postgres checkpointer that fits our
  existing database.
- Because all 4 agent nodes live in one graph definition, the team must
  coordinate carefully when each person implements their own node function
  to avoid merge conflicts in the graph-wiring file — each agent's *node
  function body* lives in its own file (`app/agents/<agent>.py`), while
  only the graph construction itself is a shared file.
- If LangGraph proves too heavy or buggy for our timeline, the fallback is
  documented here: revert to the custom orchestration approach and
  hand-implement state persistence and approval pausing — this ADR should
  be updated (marked Superseded) if that happens.
