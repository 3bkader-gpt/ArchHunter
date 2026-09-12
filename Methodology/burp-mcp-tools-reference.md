# Burp MCP Tools Reference

Reference for the available `user-burp_mcp` tools and where to use each one during testing.

## Proxy / Interception / Editor

- `set_proxy_intercept_state`: Toggle Burp Proxy intercept on/off.
- `get_active_editor_contents`: Read current request/response from active Burp editor.
- `set_active_editor_contents`: Replace active Burp editor contents.

## HTTP / WebSocket History

- `get_proxy_http_history`: Fetch HTTP Proxy history entries.
- `get_proxy_http_history_regex`: Search HTTP Proxy history with regex.
- `get_proxy_websocket_history`: Fetch WebSocket Proxy history entries.
- `get_proxy_websocket_history_regex`: Search WebSocket history with regex.

## Request Sending / Repeater / Intruder

- `send_http1_request`: Send raw HTTP/1.1 request.
- `send_http2_request`: Send raw HTTP/2 request.
- `create_repeater_tab`: Open/create a Repeater tab with request.
- `send_to_intruder`: Send request to Intruder.

## Scanner / Findings / Collaboration

- `get_scanner_issues`: Retrieve scanner findings/issues.
- `generate_collaborator_payload`: Generate Burp Collaborator payload.
- `get_collaborator_interactions`: Fetch interactions for Collaborator payloads.

## Configuration / Options

- `set_project_options`: Set Burp project-level options.
- `set_user_options`: Set Burp user-level options.
- `output_project_options`: Export/read project options.
- `output_user_options`: Export/read user options.
- `set_task_execution_engine_state`: Enable/disable task execution engine.

## Encoding / Utility Helpers

- `base64_encode`
- `base64_decode`
- `url_encode`
- `url_decode`
- `generate_random_string`

## Suggested Usage by Methodology Phase

- **Phase 4 (Deep URL/API/Parameter Discovery):**
  - `get_proxy_http_history*`, `get_active_editor_contents`, `url_encode`, `url_decode`
- **Phase 5 (Automated Scanning):**
  - `set_task_execution_engine_state`, `get_scanner_issues`, `set_project_options`
- **Phase 6 (Manual Exploitation):**
  - `create_repeater_tab`, `send_http1_request`, `send_http2_request`, `send_to_intruder`, `generate_collaborator_payload`
- **Phase 7 (Impact Demonstration):**
  - `get_collaborator_interactions`, `get_scanner_issues`, `output_project_options`

