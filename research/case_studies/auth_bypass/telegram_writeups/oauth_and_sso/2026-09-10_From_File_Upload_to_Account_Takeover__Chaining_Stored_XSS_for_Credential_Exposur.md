# From File Upload to Account Takeover: Chaining Stored XSS for Credential Exposure and Privilege Escalation

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-09-10
- **Source Channel:** CyberSec WriteUps
- **Original Source URL:** [https://medium.com/p/c13d80e909d0](https://medium.com/p/c13d80e909d0)

---

## Detailed Writeup & Technical Breakdown

## From File Upload to Account Takeover: Chaining Stored XSS for Credential Exposure and Privilege Escalation


--


Listen


Share


While testing a web application, I came across an interesting attack chain that started with what initially looked like a simple file upload issue.


The application allowed users to upload files, and at first glance, the functionality appeared to perform basic validation. However, after looking beyond the file extension and focusing on how the uploaded content was subsequently served and rendered, I discovered that attacker-controlled JavaScript could be stored and executed in the application’s origin.


I discovered a chain of vulnerabilities that allowed a remote attacker to:


· Bypass file upload restrictions (MIME type spoofing)


· Achieve Stored Cross-Site Scripting (XSS)


· Steal authentication tokens and plaintext credentials


· Perform full account takeover without any user interaction beyond clicking a link.


## Understanding the Attack Surface


File upload functionality is commonly associated with vulnerabilities such as:


· Unrestricted file upload


· Malicious file upload


· Remote Code Execution


· Path traversal


· Content-type bypass


· Stored Cross-Site Scripting


· Server-side request forgery


· Malware hosting


However, one scenario that can easily be overlooked is:


What happens if the uploaded file is treated as active content by the browser?


If an application stores an attacker-controlled file and later serves it from a trusted origin, the browser may interpret the content as HTML or JavaScript.


That can transform a seemingly harmless upload feature into a Stored XSS vulnerability.


## 1. File Upload Bypass — The First Foothold


The first step was to identify endpoints responsible for uploading and retrieving files.


The endpoint /api/v1/media/add accepted multipart/form-data and required a file field. We observed that the server used Multer (a Node.js middleware) and had a fileFilter that checked the MIME type of the uploaded file. Only images (image/jpeg, image/png, etc.) were allowed.


However, the fileFilter only validated the Content-Type header, not the actual file content. This meant we could change the Content-Type to image/jpeg while uploading an HTML or JavaScript file.


After identifying that arbitrary files could be uploaded by bypassing the MIME type validation, I attempted to upload an SVG file containing an XSS payload to determine whether the application would execute the embedded script.


Example Request :


### Example Response:


After successfully bypassing the file upload validation and uploading an SVG file containing an XSS payload, I accessed the generated SVG file directly through its uploaded URL.


The SVG was served and rendered by the browser, confirming that the application accepted and made the uploaded SVG accessible. However, the embedded JavaScript was not executed.


The browser console displayed a CSP violation similar to:


## Proof of Concept: Chaining JavaScript and HTML File Uploads


## Step 1 — Uploading the Malicious JavaScript File


A JavaScript file containing a controlled XSS payload was uploaded while manipulating the MIME type to appear as an allowed image type.


Request:


Response:


### The response confirmed that the JavaScript file was successfully stored on the server and that the application generated a URL through which the uploaded file could be accessed.


## Step 2 — Leveraging the Stored JavaScript File


After confirming that the JavaScript file was stored and accessible from the application’s origin, I explored whether the uploaded JavaScript could be executed through another uploaded file.


An HTML file was therefore created that referenced the previously uploaded JavaScript file.


## Step 3 — XSS Execution


The generated HTML file was then accessed through its uploaded URL. The HTML document loaded the previously stored JavaScript file from the same origin.


The JavaScript payload subsequently executed and the controlled XSS popup was displayed in the browser.


## CSP Bypass Observation


An initial SVG-based XSS attempt was blocked by the application’s Content Security Policy because the inline JavaScript was not permitted.


However, the subsequent approach used an external JavaScript file hosted on the same origin. Since the observed CSP permitted scripts from 'self', the browser was allowed to load the uploaded JavaScript resource from the application's own origin.


## Step 4 — Post-XSS Exploitation: Accessing Application Data


After achieving JavaScript execution, I wanted to determine what an attacker could actually access from the application’s browser context.


### 4.1 The Authentication Token


The first target was the authenticated session token. The token was stored in a cookie protected with both HttpOnly and Secure.


Because of HttpOnly, the cookie could not be accessed through JavaScript using document.cookie.


So the obvious attack path:


```
XSS ↓Read authentication cookie ↓Steal session token
```


was not possible.


However, this did not prevent the JavaScript from executing within the authenticated application context.


### 4.2 Looking Beyond the Cookie


I then examined the application’s client-side storage and found several application-specific values in localStorage, including the UID, username, API key, and unique key.


Unlike an HttpOnly cookie, localStorage is directly accessible to JavaScript executing within the same origin.


This changed the attack path to:


```
Authenticated browser Session          ↓    HttpOnly Cookie          ↓   Cannot be read directly          ↓   Application values in       localStorage          ↓      XSS accesses them          ↓   Authenticated API requests
```


The important realization was that XSS does not necessarily require stealing the session cookie to abuse an authenticated session. The injected JavaScript can potentially perform actions using the browser’s existing authenticated context.


## Step 5 — Identifying an Interesting API Endpoint


At this stage, the objective was to determine whether the accessible application APIs exposed sensitive information that could be accessed using the compromised browser context.


The required API endpoint was not initially known.


Therefore, the application’s available API functionality was reviewed and endpoint discovery was performed within the authorized testing scope.


During this process, an endpoint associated with transaction/log information was identified.


The endpoint returned application log information that was potentially more sensitive than ordinary application data.


This changed the attack scenario from:


XSS ↓ Execute JavaScript


to:


XSS ↓ Execute JavaScript in authenticated origin ↓ Access application APIs ↓ Retrieve sensitive application information


## Step 6 — Chaining Stored XSS With the Transaction Log API


At this stage, three pieces of the puzzle were in place:


· JavaScript could execute from the application’s origin.


· Application-specific request parameters were accessible through localStorage.


· A transaction-log API returned potentially sensitive information.


The next step was to combine them into a single proof of concept.


The objective was simple:


Use the authenticated browser context to request the transaction logs, search the response for credential-related information, and send the required PoC data to a controlled testing endpoint.


### 6.1 Obtaining the User Context


The payload first retrieved the required identifiers from localStorage:


The username was also obtained from the application’s stored user object.


These values were JavaScript-accessible, unlike the authentication token stored in the HttpOnly cookie.


### 6.2 Reconstructing the API Request


The payload then constructed the headers expected by the application:


The important part was that I did not need to extract the HttpOnly cookie.


Instead, the browser’s existing authenticated context was reused:


XSS ↓ JavaScript execution ↓ Read application values ↓ Make authenticated API request


### 6.3 Requesting the Transaction Logs


The payload then sent a request to the transaction-log endpoint:


The credentials: 'include' option ensured that the browser included the applicable credentials with the request.


At this point, the Stored XSS was no longer just a browser popup — it was being used to interact with a legitimate authenticated API.


### 6.4 Searching the Returned Data


After receiving the response, the payload parsed the returned JSON and examined the transaction records.


Rather than processing every log entry, I searched specifically for records containing indicators such as:


```
emailpasswordIpaddress
```


For matching entries, the payload attempted to extract the logged request body and identify the relevant fields.


Conceptually, the process was:


```
Transaction Logs           ↓Find credential-related entries      ↓Extract logged request body      ↓Parse JSON      ↓Identify relevant fields
```


6.5 Sending the PoC Result


Finally, the extracted test data was sent to a controlled testing endpoint:


This callback served as the confirmation point for the attack chain.


It allowed me to verify that data obtained through the authenticated application context could be transmitted outside the application’s origin.


Full POC —


## Step 7 — The Moment the Hypothesis Became Reality


This was the point where the test became particularly interesting.


I knew the XSS worked.


I knew that JavaScript could access the application’s Local Storage.


I knew that the transaction-log endpoint was accessible from the authenticated browser context.


But I still didn’t know whether the logs actually contained usable credentials.


So this part was essentially a gamble.


The payload was designed to answer one question:


Were authentication credentials actually being recorded inside the transaction logs?


After the payload executed, I monitored my controlled testing endpoint for the callback.


And then the callback arrived.


The response contained data matching the extraction conditions implemented in the JavaScript.


The screenshot below shows the corresponding callback received during testing.


## Step 8 — Using the Recovered Credentials


The next step was to determine whether the recovered credentials had any practical value.


The extracted credentials were tested against the application’s authentication functionality within the authorized scope.


The credentials were valid.


More importantly, they were associated with an administrative account.


This changed the severity of the attack chain significantly.


What initially looked like:


```
File Upload↓Stored XSS
```


had now become:


```
File restriction Bypass                     ↓      Stored XSS            ↓Authenticated API Access            ↓Transaction Log Exposure            ↓Credential Disclosure            ↓Administrative Credentials            ↓Administrative Account Access
```


The administrative account provided access to functionality that was not available to the original lower-privileged account.


This demonstrated privilege escalation.


## Step 9 — From Privilege Escalation to Account Takeover


The final impact was therefore not limited to credential disclosure.


The compromised credentials provided access to an administrative account, demonstrating a complete account-compromise scenario.


This was the key lesson from the assessment:


A vulnerability that initially appeared to be “just” a file-upload issue or Stored XSS became substantially more severe when chained with the application’s client-side storage and sensitive transaction logging.


## Remediation


The issue can be mitigated by implementing strict server-side file-upload validation, including extension, file-signature, and content validation, while rejecting executable and active-content formats unless explicitly required. Uploaded files should preferably be served from a separate, isolated origin rather than the application’s trusted domain.


The application should prevent stored XSS and maintain a restrictive CSP as an additional security layer. Sensitive authentication values and reusable secrets should not be stored in JavaScript-accessible localStorage.


Transaction logs must never contain plaintext passwords, tokens, API keys, or other sensitive information and should be properly redacted. Sensitive APIs, particularly transaction-log endpoints, must enforce server-side authentication, authorization, and data-level access controls and should return only the minimum information required. Finally, existing logs should be reviewed for previously exposed credentials or secrets, with affected credentials rotated where necessary.


## Thank You for Reading


Thank you for taking the time to read this write-up.


I really appreciate you giving up your valuable time to go through the entire attack chain with me. I hope this write-up was useful and that it provided some practical insight into how a seemingly simple file-upload issue can evolve into a much more serious security impact when multiple weaknesses are chained together.


If you enjoyed the write-up, feel free to share it with other security enthusiasts, researchers, and developers. Hopefully, it helps someone identify and prevent a similar attack chain in their own applications.


Thanks for reading, and keep hacking responsibly! 🔐

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
