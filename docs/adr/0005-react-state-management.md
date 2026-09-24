# ADR 0005: State Management Approach in React

**Status:** Proposed — decision needed
**Date:** TBD
**Deciders:** Whoever owns the React app structure (recommend deciding as a full team, since all 4 students build screens in React)

## Context

The assignment explicitly requires "a suitable state-management approach
such as Context API, Redux Toolkit, Zustand or another justified option"
(§7). It's not enough to just pick one — we need to record *why*, since
this ADR is graded evidence for LO4 and may come up in the viva.

Things to weigh for our specific app:
- React is used mainly for **staff-facing** screens: dashboards, designer
  management, quote/contract review, and the Agentic AI monitoring +
  approval dashboard (§7). This is a moderate amount of shared state
  (current user/role, auth token, maybe cached lists) rather than a huge
  amount of deeply nested or frequently-changing state.
- 4 students will be adding screens to the same React app independently —
  whatever we choose needs to be easy for someone unfamiliar with a given
  screen's state to reason about, to avoid merge conflicts and confusion.
- We are already fetching most data from the backend via a shared
  `apiClient` (`src/shared/api/client.ts`) — a lot of "state" is really
  server data, which changes the calculus (see Alternatives below).

## Decision

*(Fill in once decided.)*

We will use: **[Context API / Redux Toolkit / Zustand / other]**

Reasoning: *(why this fits our team size, app shape, and timeline better
than the alternatives below)*

## Alternatives Considered

- **React Context API (built-in, no extra dependency)**
  - Pros: no new library to learn, fine for low/medium-frequency global
    state like "current logged-in user" or "selected role"
  - Cons: can cause unnecessary re-renders if used for frequently-changing
    state; requires more boilerplate to avoid this at scale

- **Redux Toolkit**
  - Pros: predictable, well-documented, strong devtools for debugging
    state changes (useful when 4 people are touching the same app);
    industry-standard, so it's a reasonable thing to defend in a viva
  - Cons: more setup/boilerplate than the alternatives; possibly more
    than this app's actual state complexity needs

- **Zustand**
  - Pros: minimal boilerplate, easy for multiple people to add their own
    slice of state without touching a central reducer; lightweight
  - Cons: less "opinionated" structure than Redux, which can lead to
    inconsistent patterns across 4 different students' code if not
    agreed on explicitly upfront

- **Server state library instead (e.g. TanStack Query) + minimal local state**
  - Worth considering separately from the above: since most of our
    "state" is actually data fetched from the backend (designer lists,
    requests, quotes), a server-state library paired with a *lighter*
    client-state solution (Context or Zustand) for the small amount of
    genuinely local/global UI state (like auth) may be the most accurate
    fit. This can be recorded as a follow-up/combined decision.

## Consequences

*(Fill in once decided — e.g. "all 4 students need to follow the same
pattern when adding state for their module screens; document the
convention in `docs/CONTRIBUTING.md` once chosen.")*
