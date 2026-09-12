# Parser Implementation Integrity

## Mechanism Overview
A parser transforms raw, untrusted bytes into structured, trusted objects. This is the **most dangerous interaction** in any architecture. Vulnerabilities occur when the parser makes unsafe assumptions about the data's size, type, or structure.

## 1. Length-Field & Arithmetic Logic (AOSSA Ch 6)
Modern protocols (gRPC, Protobuf, custom TCP) often use length-prefixed data.

### **The "Calculation Overflow" Pattern**
*   **Logic:** `Total_Size = Header_Size + Payload_Length`.
*   **Failure:** If `Payload_Length` is `0xFFFFFFFF`, the addition overflows to a small number (e.g., `4`). The system allocates 4 bytes, but copies `Payload_Length` bytes.
*   **Offensive Pivot:** Look for size calculations involving user-supplied integers. Target `malloc`, `realloc`, and array indexers.

### **Signedness Confusion**
*   **Logic:** The parser treats a length as `signed int`, but the memory function treats it as `unsigned size_t`.
*   **Failure:** A length of `-1` (0xFFFFFFFF) passes a check like `if (len < MAX_BUFFER_SIZE)`, but then acts as a massive positive number in `memcpy`.
*   **Audit Goal:** Identify where a value transitions between signed and unsigned types.

---

## 2. Type-Length-Value (TLV) Pitfalls
Common in binary protocols and ASN.1.

### **Nested TLV Exhaustion**
*   **Mechanism:** A TLV object contains other TLV objects.
*   **Failure:** Deep nesting leads to stack exhaustion (DoS) or "Length Masking" where an inner length exceeds the outer length's remaining space.
*   **Audit Goal:** Send "Inconsistent Lengths" (Outer < Inner) to see if the parser reads past the outer boundary.

### **Type Confusion**
*   **Mechanism:** The "Type" field defines how the "Value" is processed.
*   **Failure:** Forcing the parser to treat a `String` type as an `Object` or `Pointer`.
*   **Audit Goal:** Swap types while keeping lengths consistent to trigger unintended code paths.

### **Recursive Resource Exhaustion**
*   **Mechanism:** Highly nested structures (JSON objects in JSON, XML Entities).
*   **Failure:** The parser attempts to reconstruct the full tree, exhausting stack space or CPU (Billion Laughs attack).
*   **Audit Goal:** Send deeply nested objects or recursive definitions to trigger 100% CPU or crash.

---

## 3. Schema Evolution & Distributed Divergence (DDIA Ch 4)
In distributed systems, different services often use different versions of the same schema (Avro, Protobuf, Thrift).

### **Backward/Forward Compatibility Drift**
*   **Mechanism:** Service A (Old) sends data to Service B (New). Service B adds a "Required" field that Service A doesn't know about.
*   **Failure:** Service B might default the missing field to an insecure value (e.g., `is_admin = true` or `check_permissions = false`) or crash, causing a logic bypass or DoS.
*   **Offensive Pivot:** Identify "Version Headers" or "Schema IDs". Send old-version payloads to new-version consumers.

### **Optional-to-Required Escalation**
*   **Logic:** A field changes from `Optional` to `Required` in a schema update.
*   **Failure:** If the parser logic assumes the field is *always* present and validated, removing the field from the payload might skip a critical authorization check.
*   **Audit Goal:** Remove "Required" fields from structured payloads to see if the backend defaults to a privileged state.

---

## 4. Constraint Propagation Checklist
When auditing a parser, verify these AOSSA & DDIA primitives:
1.  **Atomicity:** Does the parser process the *entire* message before acting, or does it perform actions incrementally (partial state)?
2.  **Range Validation:** Are integers checked for *both* `MIN` and `MAX` values?
3.  **Consistency:** Do the "Length" field and the "Actual Bytes Received" match?
4.  **Idempotency:** Does parsing the same malicious input twice result in the same state (no memory leaks)?
5.  **Schema Versioning:** How does the parser handle "Unknown Fields"? (Are they forwarded, dropped, or executed?).

## Recognition Patterns
*   **gRPC/Protobuf:** Target the field-index vs type mapping.
*   **GraphQL:** Target batching (array of objects) and recursive fragment definitions.
*   **JSON:** Target large integer precision (Number vs String).
