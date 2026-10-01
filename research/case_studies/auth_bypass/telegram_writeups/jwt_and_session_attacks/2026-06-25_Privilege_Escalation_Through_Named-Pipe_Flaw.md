# Privilege Escalation Through Named-Pipe Flaw

- **Category:** JWT & Session Flaws
- **Publication Date:** 2026-06-25
- **Source Channel:** Daily Bounty Writeups
- **Original Source URL:** [https://medium.com/@defidev59/privilege-escalation-through-named-pipe-flaw-7617eb238e91?source=rss------bug_bounty-5](https://medium.com/@defidev59/privilege-escalation-through-named-pipe-flaw-7617eb238e91?source=rss------bug_bounty-5)

---

## Detailed Writeup & Technical Breakdown

## Privilege Escalation Through Named-Pipe Flaw


--


Listen


Share


> Overview


Overview


This flaw was in the way the System-priveleged process authenticated and established the Websocket connection with the browser extension to perform the system-level actions restricted to the User-level user.


> Technical Flow: [ I’ll keep the information about the product as minimal as possible ]


Technical Flow: [ I’ll keep the information about the product as minimal as possible ]


The browser extension sends the message to the local “User level” process through Native Messaging HostThen the local user-process generated the auth-token using that data and then sends the auth token to the “System-Level” process through the “Named-Pipe” as well as the Browser Extension.


```
A "Named-Pipe" is an Inter Process Communication (IPC) mechanism that processesrunning on the local system use to exchange data.
```


Now the browser extension will send a websocket connection request to the system-level process with the same token that was generated and shared both ways by the local user-level process.The system-level process checks the token value and if the check matches the connection is established and then system level actions can be performed.


> The Flaw


The Flaw


The flaw was in the token check mechanism of the System Process coming in through the named pipe.


The SYSTEM process connects to the User-process as a “Client” to the pipe.The SYSTEM process treated whatever token appeared on an attacker-chosen named pipe as ground truth, without proving that pipe was created by the trusted helper and the attacker could supply both the pipe and the matching WebSocket proof.


> Exploit


Exploit

- Any local user can create a named pipe at a path they choose (using a self-generated session identifier), wait for the SYSTEM process to connect as a pipe client, supply an attacker-chosen token on that pipe, then open a WebSocket connection.
- The system-process accepts the request and the connection is established. Now we can send the system level operation requests to the system process.

(The operation we could perform were really sensitive for User-Level userto access, therefore this was critical vulnerability)


```
┌─────────────────────────────────────────────────────────────────┐│  CHROME BROWSER (user session)                                  ││  ┌──────────────┐    native msg (stdin/stdout)    ┌────────────┐││  │  Extension   │ ──────────────────────────────►│  Helper     │││  │  (JS)        │◄──────────────────────────────│  (user)      │││  └──────┬───────┘                                 └─────┬──────┘││         │                                               │       ││         │ WebSocket JSON                                │ creates││         │ ws://127.0.0.1:45567                          │ pipe   │└─────────┼───────────────────────────────────────────────┼────────┘          │                                               │          ▼                                               ▼┌─────────────────────────────────────────────────────────────────┐│  WINDOWS (Session 0 / services)                                 ││  ┌──────────────────────────────────────────────────────────┐  ││  │  (SYSTEM-Level Process)                                  │  ││  │  - listens TCP 45567                                     │  ││  └──────────────────────────────────────────────────────────┘  ││         ▲                                                       ││         │  \\.\pipe\<name>\{session_id}                         │└─────────┴───────────────────────────────────────────────────────┘
```


Hope you liked this article. This was a great learning experience for me.Also, for learning more about the Named Pipes you can refer to the following link: https://learn.microsoft.com/en-us/windows/win32/ipc/named-pipes


Thank you all for reading.


Note: I cannot disclose any part of the company information as this was not exactly a “Bug bounty”. But, as this vulnerability found was the most interesting one for me and also new, so here’s the writeup.

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
