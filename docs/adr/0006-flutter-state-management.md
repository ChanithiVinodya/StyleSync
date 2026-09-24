# ADR 0006: State Management Approach in Flutter

**Status:** Proposed — decision needed
**Date:** TBD
**Deciders:** Whoever owns the Flutter app structure (recommend deciding as a full team, since all 4 students build screens in Flutter)

## Context

The assignment explicitly requires "a suitable state-management approach"
for the Flutter app (§8), separately justified from the React choice
(§14.2 lists React and Flutter state management as two distinct required
ADR topics — don't conflate them into one decision).

Things to weigh for our specific app:
- Flutter is used mainly for the **client-facing** journey: submitting a
  room request (multi-step form with camera upload), viewing the AI
  proposal, approving/rejecting, and tracking project progress (§8). This
  involves some multi-screen form state (the request form) and some
  async data loading (proposal results, progress timeline).
- The skeleton's `pubspec.yaml` currently lists `provider` as a dependency
  — this was an initial default, **not a final decision**. It's fine to
  keep, but this ADR should confirm that choice deliberately rather than
  leaving it as an unexamined default, since the assignment wants a
  *justified* choice.
- Same cross-team consideration as React: 4 students adding screens to
  one Flutter app benefits from a consistent, easy-to-learn pattern.

## Decision

*(Fill in once decided.)*

We will use: **[Provider / Riverpod / Bloc / other]**

Reasoning: *(why this fits our team size, app shape, and timeline better
than the alternatives below)*

## Alternatives Considered

- **Provider** (currently in `pubspec.yaml` as a starting default)
  - Pros: simple, officially recommended by the Flutter team for small-
    to-medium apps, minimal boilerplate, easy to explain in a viva
  - Cons: less structure than Bloc for complex async flows; can get messy
    if the team doesn't agree on conventions upfront

- **Riverpod**
  - Pros: compile-time safety (catches some state-access bugs Provider
    can't), doesn't require a `BuildContext` to read state, good fit for
    the async data-loading screens (proposal results, progress timeline)
  - Cons: a steeper learning curve than Provider if the team hasn't used
    it before; slightly more setup

- **Bloc / flutter_bloc**
  - Pros: very explicit separation of events/state, strong for complex
    multi-step flows like our room-request form; well-documented,
    widely used in industry, easy to defend as "professional practice"
    in the viva
  - Cons: most boilerplate of the three options; may be more structure
    than this app's actual complexity needs given the 9-week timeline

## Consequences

*(Fill in once decided — e.g. "all 4 students need to follow the same
pattern when adding state for their module screens; update
`pubspec.yaml` if the final choice differs from the current `provider`
default, and document the convention in `docs/CONTRIBUTING.md`.")*
