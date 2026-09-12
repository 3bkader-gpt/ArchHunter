# 01 — Strategic Target Selection & Business Deconstruction (Phase 0)

## Operational Goal
Identify targets with the highest logical density, payout reliability, and monetization surface. Avoid "Payload Sinks" (hardened static marketing sites) in favor of "Mechanism Hubs" (complex SaaS dashboards, multi-tenant B2B portals, and active API gateways).

---

## 1. Program Strategy: Bug Bounty (BBP) vs. Vulnerability Disclosure (VDP)

| Criteria | Bug Bounty Program (BBP) | Vulnerability Disclosure Program (VDP) |
|---|---|---|
| **Primary Reward** | Cash Bounties ($$$), Badges, Hall of Fame | Hall of Fame, Reputation points, Swag (T-shirts, vouchers) |
| **Competition Level** | Very High (Seasoned full-time hunters) | Low to Medium (Ideal for finding zero-day business logic) |
| **Best Used For** | Maximizing earnings once methodology is sharp | Rapid reputation building, testing new toolchains, private invites |
| **Platform vs Self-Hosted** | HackerOne / Bugcrowd / Intigriti / YesWeHack | Direct security.txt / `.well-known/security.txt` / Self-managed |

### 💡 High-Yield Program Selection Heuristics:
1. **Response Efficiency & Triage Speed:** Filter for programs with `< 5 days` average time to first response and bounty award. Avoid unresponsive programs with high dispute ratios.
2. **Freshness Index:** Hunt on programs updated within the last **30 days** or recently added domains to avoid duplicate exhaustion.
3. **Scope Geometry:** Prioritize wildcard scopes (`*.target.com`) with API access over restrictive single-URL static assets.

---

## 2. Target Selection Criteria (Highest ROI)
1. **Multi-Tenancy & Role Diversity:** Prioritize platforms offering free self-registration with Organization/Team hierarchies (`Owner`, `Admin`, `Member`, `Billing Manager`, `Support Guest`).
2. **Monetization & Feature Density:** Look for tiered subscription models (Free vs Pro vs Enterprise), coupon redemption, balance wallets, and credit transfers.
3. **Complex State Transitions:** Target multi-step asynchronous operations (Onboarding $\rightarrow$ Invite Team $\rightarrow$ Link OAuth Provider $\rightarrow$ Webhook Delivery $\rightarrow$ Bulk Export).
4. **Target Breadth:** Scan for staging, beta, and development subdomains (`dev-api.target.com`, `app-staging.target.com`, `qa-v2.target.com`).

---

## 3. Phase 0: Business Model Deconstruction Checklist
Before executing a single recon command, answer these 4 foundational questions:
- [ ] **How does this company make money?** (SaaS subscription tiers, transaction fees, API call quotas, e-commerce checkout).
- [ ] **What is the most sensitive asset in their database?** (Customer PII, payment tokens, internal team documents, API keys, private tickets).
- [ ] **What roles and tenant boundaries exist?** (Org A vs Org B, Admin vs Member, Low privilege vs Superuser).
- [ ] **Which features have high logical complexity?** (Member invitations, webhook callbacks, CSV/PDF bulk exports, passwordless/OAuth login, custom role creation).

---

## 4. Preparation & Two-Account Setup
1. Create **Account A (Attacker)**: `attacker@wearehackerone.com` in Org A.
2. Create **Account B (Victim)**: `victim@wearehackerone.com` in Org B.
3. Configure **Burp Suite Autorize / Match & Replace** following **[PRACTICAL_BURP_HUNTING_GUIDE.md](../Methodology/PRACTICAL_BURP_HUNTING_GUIDE.md)**.

---

## Transition to Recon
Proceed to **[02 — Passive Recon](02_passive_recon.md)** with a clear operational focus on mapping live SaaS applications, API gateways, and cloud origins.

