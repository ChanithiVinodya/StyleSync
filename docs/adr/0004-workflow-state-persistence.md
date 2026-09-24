# ADR 0004: Database Schema Strategy for Agent Workflow State

**Status:** Accepted
**Date:** 2026-08-20
**Deciders:** Team (all 4 members)

## Context

The assignment requires that workflow ID, objective, plan, completed
steps, tool results, validation results, errors, approval status, and
final outcome all be persisted in structured, durable storage (§9.1) —
not just held in memory while the AI service is running. We also need
React and the backend to be able to query workflow status and execution
history for the Agentic AI dashboard and audit requirements (§7, §12).

We already use PostgreSQL as our single database for all business data
(designers, requests, quotes, projects), and we've chosen LangGraph for
orchestration (ADR 0003), which has its own opinion about how it persists
graph state.

## Decision

We will use **LangGraph's official Postgres checkpointer**
(`langgraph-checkpoint-postgres`) to persist the raw graph execution state
(the step-by-step LangGraph run: which node ran, intermediate state,
pending interrupts) into the **same PostgreSQL database** the backend
uses — not a separate database or in-memory store.

Separately, the backend maintains its own lightweight `AgentWorkflow`
table (owned as shared backend infrastructure, not by a single student's
component) that stores just enough denormalized, business-facing data for
the app to query cheaply: workflow ID, linked `ProjectRequest` ID, current
status, started/completed timestamps, and a summary of the final outcome.
This table is what React's Agentic AI dashboard and the backend's
"execution summary" endpoint actually query — it does not duplicate
LangGraph's full internal checkpoint data, just enough to render status
without needing to reconstruct the graph.

## Alternatives Considered

- **In-memory state only (no persistence)** — rejected outright; fails
  the assignment's explicit "structured, durable storage" requirement and
  means a service restart mid-workflow loses everything.
- **A separate database/store just for AI state** (e.g. Redis, MongoDB,
  SQLite) — rejected to avoid operating two different databases for a
  9-week student project; adds deployment complexity and a second set of
  credentials to protect for no clear benefit over using Postgres, which
  we already run.
- **Store full LangGraph checkpoint data directly in our own hand-rolled
  tables instead of using the official checkpointer** — rejected because
  it means re-implementing serialization/versioning logic LangGraph
  already provides and maintains; higher risk of subtle bugs.
- **Only the lightweight `AgentWorkflow` summary table, no LangGraph
  checkpointer at all** — rejected because it would mean the graph itself
  can't actually pause/resume durably (no `interrupt()` support without a
  checkpointer), which breaks the human-approval-gate requirement.

## Consequences

- Two things persist agent-related data: LangGraph's checkpointer (the
  detailed, framework-owned execution log) and our own `AgentWorkflow`
  table (the app-facing summary). Both point at the same Postgres
  instance, but are logically separate — the team needs to keep this
  distinction clear when explaining the design in the viva.
- EF Core migrations only manage the `AgentWorkflow` summary table;
  LangGraph's checkpointer manages its own schema/tables automatically,
  so it isn't part of our `AppDbContext` model.
- We must be careful not to store hidden LLM reasoning, prompts containing
  secrets, or raw uploaded images inside either store — per the spec's
  explicit instruction to persist only what's needed, not everything.
