# STATE MACHINE MAP — [TARGET_NAME]

> **Feature under analysis:** [e.g. Team Invites] · **Session:** [DATE] · **Workflow:** [`Workflow/10_depth_first_web_api.md`](../Workflow/10_depth_first_web_api.md) Phase 1
> **Rule:** no authz probes before this map exists. You are documenting how the application is *supposed* to work.

## 1. Accounts Provisioned
| Role | Identifier | Notes (plan tier, org, permissions) |
|---|---|---|
| Victim | | |
| Attacker | | |
| Admin | | |

## 2. Object State Machines
For every business object in the feature, draw its legal transitions.

### Object: [e.g. `invite`]
| From | Action / Endpoint | To | Roles allowed to trigger | Backend side effects |
|---|---|---|---|---|
| (none) | `POST /api/teams/{id}/invites` | `sent` | admin, owner | email + webhook |
| `sent` | `POST /invites/{token}/accept` | `accepted` | invited user | membership created |
| `sent` | `DELETE /invites/{id}` | `revoked` | admin, owner | — |
| `accepted` | `DELETE /members/{id}` | `removed` | admin | audit log |

### Object: [e.g. `subscription`]
| From | Action / Endpoint | To | Roles | Side effects |
|---|---|---|---|---|
| | | | | |

## 3. State × Role Access Grid
Mark who can *see/touch* the object at each state (from the UI, then verify by replay).

| State | Victim | Attacker | Admin | Unauthenticated |
|---|---|---|---|---|
| `sent` | | | | |
| `accepted` | | | | |
| `revoked` | | | | |

## 4. Transition-Timing Side Effects
What happens *after* a transition (these are second-order sinks):
- Emails sent (to whom, containing what links/tokens)
- Webhooks fired (to which URLs — attacker-controllable?)
- Cache invalidations / purges
- Background jobs enqueued (export, billing, provisioning)

## 5. Spec-vs-Reality Drift (Shadow APIs)
Endpoints the clients call (JS bundle / APK) but the public spec does not list:

| Endpoint | Discovered in | Authz tested? |
|---|---|---|
| | | |

---
**Next:** fill [`AUTHZ_MATRIX`](AUTHZ_MATRIX_TEMPLATE.md) for every endpoint above, then probe ([`Workflow/10`](../Workflow/10_depth_first_web_api.md) Phase 2-3).
