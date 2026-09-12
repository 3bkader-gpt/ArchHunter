# WebSocket Sequence & State Abuse

## Objective & Context
*   **Security Assumption Failure:** The system assumes that because the initial WebSocket handshake was authenticated, all subsequent messages on that connection are authorized for the original context.
*   **Trust Boundary Violation:** The server fails to validate ownership or scope for individual messages sent over a stateful connection.

## Recognition Patterns
*   **Mechanism:** Single-page applications (SPAs) or collaboration tools (e.g., Grammarly, Figma, Slack) using WebSockets for real-time updates.
*   **Architecture:** `ws://` or `wss://` connections established after login.
*   **Behaviors:** 
    *   Actions occurring instantly without separate HTTP requests.
    *   Binary or JSON frames exchanged in the "Frames" tab of Burp Proxy.
    *   ID values (e.g., `doc_id`, `chat_id`) included in JSON frames rather than the URL.

## Attack Preconditions
*   A valid authenticated WebSocket connection.
*   Predictable or leaked identifiers for other users' resources.

## Step-by-Step Validation Strategy
1.  **Handshake Inspection:** Capture the initial `GET` request for the WebSocket upgrade. Note if auth tokens are in headers or query parameters.
2.  **Message Enumeration:** Capture frames for common actions (edit, delete, view).
3.  **Identifier Mutation:** Manually send a frame (via Burp Repeater or match-and-replace) substituting your resource ID for a victim's resource ID.
4.  **Sequence Bypass:** Skip the "initialization" frame (where scope is typically set) and directly send "action" frames targeting other objects.
5.  **Expected Indicators:** `200` or `Success` status in the response frame, or seeing the change reflected when viewing the victim's resource.

## Common Weak Implementations
*   Standardizing auth on the handshake but using a generic "message handler" that lacks per-message authorization logic.
*   Binding a connection to a specific `user_id` but not a specific `object_id`.

## Escalation Paths
*   **Unauthorized Data Access:** Reading real-time streams of other users' documents.
*   **State Manipulation:** Modifying content, permissions, or settings via WebSocket frames.

## Detection Opportunities
*   **Message/Session Mismatch:** Telemetry flagging a message targeting an object ID that doesn't belong to the session's user.
*   **High-Volume Frame Injection:** Rate-limiting frame transmission.

## Notes
*   **False Positives:** Some frames might be purely for UI synchronization and not actually persist changes in the database.
*   **Constraints:** Requires the browser to maintain the connection; if the server terminates on invalid IDs, automation is harder.
