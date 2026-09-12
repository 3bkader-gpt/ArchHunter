# Cryptographic Failures & Operational Exploits

## Description
Advanced cryptographic exploitation is rarely about factoring large primes. It is about exploiting implementation flaws, architectural trust placed in cryptosystems, state management, and protocol downgrade attacks. 

## High-Impact Operational Vectors

### 1. Downgrade Attacks (Protocol & Cipher)
**Concept:** The system supports modern, strong cryptography but retains backward compatibility for legacy clients.
**Mechanism:** An active MitM intercepts the handshake and modifies the supported cipher list, forcing the server to negotiate a weak, exploitable protocol (e.g., TLS 1.0, export ciphers, null ciphers).
**Operational Test:** Use `testssl.sh` or `nmap --script ssl-enum-ciphers` to identify supported legacy protocols.

### 2. Reflection Attacks
**Concept:** A protocol that authenticates by requiring the client to encrypt a server-provided challenge.
**Mechanism:** If mutual authentication is flawed, the attacker initiates a parallel connection to the server, sending the challenge from Connection A as the challenge for Connection B. The server encrypts its own challenge, giving the attacker the valid response for Connection A.
**Operational Test:** Look for custom challenge-response handshakes, particularly in proprietary thick clients or IoT firmware. 

### 3. Length Extension Attacks
**Concept:** The system uses a vulnerable hash construct (like `MD5(secret || message)` or `SHA1(secret || message)`) to generate a MAC (Message Authentication Code) or signature.
**Mechanism:** Because of the Merkle-Damgård construction, an attacker who knows the original `message` and its `signature` can append arbitrary data and calculate a valid new signature *without* knowing the `secret`.
**Operational Test:** Look for custom API signatures, download token generation, or legacy SSO tokens appending data. Use tools like `HashPump` to forge new signed payloads.

### 4. Oracle Attacks (Padding & Error)
**Concept:** The system reveals whether decryption was successful or failed due to padding/formatting errors before MAC validation.
**Mechanism:** By sending thousands of modified ciphertexts, the attacker observes timing or error differences to decrypt the payload byte-by-byte.
**Operational Test:** Look for CBC mode ciphers (e.g., `AES-CBC`) without proper Encrypt-then-MAC (like GCM). Test by flipping bits in the ciphertext block and observing HTTP 500s vs HTTP 200s.
