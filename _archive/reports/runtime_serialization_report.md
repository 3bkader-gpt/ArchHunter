# Runtime Serialization Report

## Summary
Unable to execute serialization tests because the MCP tool runtime could not start the Burp MCP server. The tool returned the same startup error for every attempt, so serialization behavior could not be validated.

## Results Table

| Test | pseudoHeaders | Result | Error |
| --- | --- | --- | --- |
| A | {} | Failed | MCP server could not be started: Process exited with code 1 |
| B | {"method":"GET"} | Failed | MCP server could not be started: Process exited with code 1 |
| C | {"_method":"GET"} | Failed | MCP server could not be started: Process exited with code 1 |
| D | {"xmethod":"GET"} | Failed | MCP server could not be started: Process exited with code 1 |
| E | {":method":"GET"} | Failed | MCP server could not be started: Process exited with code 1 |

## Successful Structures

None. Tests were not executed due to MCP startup failure.

## Failed Structures

All tests failed before request serialization because the MCP server could not start.

## Root Cause Conclusion

Inconclusive. The runtime failed to start the MCP server, so serialization of colon-prefixed pseudoHeaders was not exercised.

## Runtime Compatibility Verdict

Indeterminate. Fix MCP server startup/registration and re-run the tests to confirm serialization behavior.
