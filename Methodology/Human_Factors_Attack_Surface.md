# Attacker Cognition: Human-in-the-Loop Exploitation

## Operational Philosophy
The human is the ultimate, unpatchable trust boundary. Systems are designed by humans, operated by humans, and secured by policies that humans must follow. Exploiting the cognitive load, biases, and compliance exhaustion of system operators is a critical pathway to compromise.

## Cognitive Exploitation Heuristics

### 1. "Scamicry" & Semantic Confusion
**Concept:** Organizations teach users to look for specific visual cues (padlocks, logos) or URL patterns to verify authenticity.
**Offensive Implication:** Attackers can mimic the *legitimate* but confusing authentication flows of the organization.
*   **Execution:** Use Open Redirects to chain into OAuth authorization flows. Exploit SSO complexity where users cannot distinguish between a legitimate tenant login and an attacker-controlled tenant login. 

### 2. The "Compliance Budget" Exhaustion
**Concept:** Security compliance has a budget. Users have a finite amount of time and mental energy to comply with security prompts (MFA, warnings, captchas).
**Offensive Implication:** MFA fatigue and warning fatigue.
*   **Execution:** Spamming MFA prompts to a target until they approve it just to silence their phone. Triggering non-fatal security warnings repeatedly until the SOC or operator whitelists the behavior or ignores the alert (Alert Fatigue masking true exploitation).

### 3. WYSIATI (What You See Is All There Is)
**Concept:** Based on Kahneman's System 1 thinking, operators and developers build trust based on immediate, visible evidence and fail to consider invisible variables.
**Offensive Implication:** Developers trust the visible `Host` header or the apparent `Content-Type`. 
*   **Execution:** HTTP Request Smuggling, Host Header Injection. Send a payload that *looks* safe to the front-end WAF (System 1) but is parsed maliciously by the backend (System 2). 

### 4. Ceremony Analysis & Out-of-Band Abuse
**Concept:** Security is often a "ceremony" (e.g., password reset flow, hardware token registration) involving multiple steps, channels, and out-of-band communication (email, SMS).
**Offensive Implication:** The ceremony itself is a state machine with race conditions.
*   **Execution:** Request a password reset (Step 1), intercept the token via email tampering/Host header injection (Step 2), and race the user to consumption (Step 3). Break the sequence of the ceremony.
