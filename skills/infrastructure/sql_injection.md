# SQL and ORM Injection

## Objective & Context
SQL Injection (SQLi) occurs when untrusted user input is concatenated directly into a database query. In modern applications, classic SQLi is less common due to Object-Relational Mapping (ORM) libraries, but *ORM Injection* is a rising threat where the abstraction layer itself is abused.

## Recognition Patterns
*   **Parameters:** `id`, `sort`, `order`, `filter`, `query`, `search`.
*   **JSON Bodies:** Arrays or complex objects passed to filtering endpoints.
*   **Headers:** `User-Agent`, `X-Forwarded-For` (often logged to the database).

## Attack Mechanisms & Heuristics

### 1. Classic SQL Injection
*   **Boolean-Based Blind:** The application returns different responses (e.g., "User exists" vs. "User not found") based on whether an injected condition evaluates to TRUE or FALSE.
    *   *Execution:* Extract data character by character using `SUBSTRING()` or `LIKE`.
*   **Time-Based Blind:** The application does not return errors or boolean differences.
    *   *Execution:* Inject `SLEEP()`, `pg_sleep()`, or `WAITFOR DELAY` to infer TRUE/FALSE based on response time.

### 2. ORM-Level Injection (e.g., Django)
*   **Concept:** ORMs protect against basic SQLi by parameterizing queries, but complex filtering mechanisms can bypass this.
*   **Django Patterns:**
    *   `Q()` objects: Injecting into the `_connector` parameter.
    *   `FilteredRelation`: Providing user-controlled annotation aliases that match SQL keywords.
    *   `HasKey` transforms: On specific backends (like Oracle or PostgreSQL), improper handling of JSONB keys can lead to raw SQL injection.
*   **Execution:** Look for endpoints that allow dynamic filtering via JSON objects or URL query arrays (e.g., `?filter[name__contains]=admin`).

### 3. Second-Order SQL Injection
*   **Concept:** The payload is safely inserted into the database but is later retrieved and used unsafely in a different query.
*   **Execution:** Inject payloads into profile fields (e.g., username) and trigger actions that use that profile field (e.g., generating an invoice or a report).

## Chaining Logic
*   `SQL Injection` -> `Extract Admin Hash` -> `Crack Hash` -> `Account Takeover`
*   `SQL Injection` -> `Modify Serialized Object in DB` -> `Application Deserializes Object` -> `Remote Code Execution (RCE)`

## Remediation & Validation
*   Strictly use parameterized queries or prepared statements.
*   Do not allow user input to dictate column names, table names, or sort orders directly; map user input to a strict allowlist.
*   When using ORMs, avoid raw query methods (e.g., `Raw()`, `execute()`) and validate dynamic filter structures.
