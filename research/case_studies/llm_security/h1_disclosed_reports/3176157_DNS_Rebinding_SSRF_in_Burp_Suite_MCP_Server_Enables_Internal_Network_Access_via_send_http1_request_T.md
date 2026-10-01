# Report #3176157: DNS Rebinding SSRF in Burp Suite MCP Server Enables Internal Network Access via send_http1_request Tool

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/3176157](https://hackerone.com/reports/3176157)
- **Program:** PortSwigger Web Security
- **Reporter:** @farmer
- **Status:** RESOLVED
- **Severity:** none
- **Weakness:** Server-Side Request Forgery (SSRF)
- **Bounty:** Yes (Undisclosed Amount)
- **Submitted:** 2025-06-03T19:27:11.482Z
- **Disclosed:** 2025-10-08T14:26:27.617Z
- **Community Upvotes:** 142

---

## Executive Summaries

No formal disclosure summary provided.

---

## Full Vulnerability Description & Reproduction Steps

The Burp Suite MCP (Model Context Protocol) server on port 9876 lacks proper origin validation and CORS protection, enabling DNS rebinding attacks to bypass the Same-Origin Policy.

Pre-Requisites: attackers need to trick a victim who has Burp Suite installed with MCP Server enabled to open a malicious link . On that link domain, the attackers need to host malicious webpage

Step2:  Setup  a DNS server for a domain that you  controls that answers the first DNS request on this domain with the IP of a server he controls (in this example 192.168.80.154), and all other DNS requests with 127.0.0.1. One way to do this is to use the https://github.com/mogwailabs/DNSrebinder  and launching it like this:
python3 dnsrebinder.py --domain rebind.mydomain.eu. --rebind 127.0.0.1 --ip 192.168.1.3  --counter 1 --udp

On IP Attacker needs to host a webserver that serves malicious web page. See attached html 

# Serve malicious page
python3 -m http.server 8080

Step1: Setup DNS Rebinding: 
> 1. Visit: https://lock.cmpxchg8b.com/rebinder.html
>2. Enter IP where web server with malicious web page would be hosted (in my case I hosted on localhost so enterd private IP)
>3. Click generate to generate rebinding hostname. in my case it was: 7f000001.c0a80103.rbndr.us

Step2: Setup Server with Malicious page:
> 1. start webserver that server malicious page with  python3 -m http.server 9876 (I am using same port as Burp MCP Server). Since test was done from localhost, I am temporarily turning OFF MCP server so that there is no port conflict.
> 2. Once DNS rebinding is done, stop/kill web server
>3. Start Burp Suit's MCP Server, JS code will now try to connect with MCP Server


Attached Index.html contains POC code. 

Step3: Actual POC Flow
  Once   Web page URL is opened on machine which would look something like: http://7f000001.c0a80103.rbndr.us/, It loads embedded malicious JS Script which does following:
>1. Establishes connection to MCP Server and fetches session ID which will be used in subsequent interactions.
>3. Calls MCP server's  send_http1_request tool to initiate http request to any internal/external hosts
>4. Retrieves http history using  get_proxy_http_history 

This essentially enables any remote attacker to not only  access Burp's MCP Server tools to but also initiate SSRF requests to company internal sites which are not accessible otherwise.

## Impact

This allows malicious websites to:
1. Connect to the victim's local MCP server (127.0.0.1:9876)
2. Use the send_http1_request MCP tool to make arbitrary HTTP requests
3. Access internal networks, localhost services, and cloud metadata endpoints
4. Retrieve full HTTP responses including sensitive data

---

## Attachments
- [index.html](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/44id8tj6n8af9g2jko11siv9nn63?response-content-disposition=attachment%3B%20filename%3D%22index.html%22%3B%20filename%2A%3DUTF-8%27%27index.html&response-content-type=application%2Foctet-stream&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQYRULDMZV%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151032Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQCpHVN0SFSCXy06cUd2EPolqxh0A9afKuNuvSVt%2Bd4IIQIgEwBs7g0ExaV6r%2FnmKEaW%2FcHbwzYSoXeVUsyQLKos1%2FkquwUIuP%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARADGgwwMTM2MTkyNzQ4NDkiDH4ax%2FmrZveUQPSN9SqPBUHKwnD7%2BywOpu6er01pEANtU5VggRPA%2B2uik9BIGkm82z9bJG5O3rMu7TH6dagDM75g5djL6t5d93z2gWb739%2BxdOb27FNlCO4mz44BlFBOUxkun2dfz1gJUed7aWWQW2sPp0sWKeU0waXb51G8AYmyCql7WpIsUL1ZrPg3Fq%2FTCrsyYZrNZJu2XS02EFidPowpMqN2utvmlJF2iS4NOxLJraqq27au1NPw2onxLfH43qBHiz98uXXHw9oeXLc7XXj5w3Nurbdkg7tauUFvLx6H1bBExjPeR0bV7wqDniMny%2FkC9kLszHJQMMWjJwm1m%2FEFJbWTdQYAC3wx6HMsWL5ZGIu98fc8UMO7S6NU5iJbGIzEf2a3t%2FiMFWSqChtYhtrLb8LZd6Ge0Ty%2FRKQY8krn90J7NdhQUUZJZwtuGs2xnIACI59wuRVrLnOmdBON03RjrbR7GfOxbS22pjArIKwiC157ckAuuNRJoDCpPEG7Oe6MgY5Tgk%2F6VLirOO4YSqONmPLx0YBF7dZ3f6jLzxSJh2Mz5Gj%2F0RjUTsRAWAf689GLp%2BO%2FctY59m1lVtEC3lNYNqiTjxfxdsliVKbKBuxtOg9uslVlyopumeUJa8LdcgSmLRHMOe8iABccVrdjqXFjQuCD6jQZ0J5ycDvvN68EoCPenA3Iy5r%2F7UvxrxCyHOR2iJ43jIYgNZP0qxF%2FLv0cRqzJ1tq%2FGWRZp0z3oxyyXEl%2BPU8uYdpFI6jPa8GT4DCOB6za9vG5BuS%2BJDYTeTYUOWs5HcA9MwZDAB7ia729JSH38%2FoS5%2F%2B2H5s5TP5Nm%2FqyUKL%2BJ3BY6%2BKQupQnT5q00yWINarXvFoedLyhDVTrrbyTbzmmnWNQ6vHyKjQwpcKV1QY6sQFRUVBjD78jIB27UIVdSDVSEFCXAzqO4t%2Bvyc1tQnS45YrIUKjyIGuIitF3PT0fVCqS%2BFtPwg%2BpP%2FfGDE4rkS6klrDqnjKVDCxo1hFmFBVPEj%2B92avioLvb%2FnY38%2FH3r7JL6Bp7GXgneqNLvsXzIMpPLorEaxc3AZ%2BPmpJeMV66vdFC3Dwy2rZINtRsvpMiwdCI4NT%2F4PoMMQ%2BcaXq1dl7HwY6IZDebKRRCL0EcU0ABr9Y%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=c6106303ee00b3369c7b4d73001496c98491b503c499f49eac4c7a767c3827ee) (attachment)
- [burp_mcp.png](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/9vdg3w7g1qsyqrsszx9nvs3xajo2?response-content-disposition=attachment%3B%20filename%3D%22burp_mcp.png%22%3B%20filename%2A%3DUTF-8%27%27burp_mcp.png&response-content-type=image%2Fpng&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQYRULDMZV%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151032Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQCpHVN0SFSCXy06cUd2EPolqxh0A9afKuNuvSVt%2Bd4IIQIgEwBs7g0ExaV6r%2FnmKEaW%2FcHbwzYSoXeVUsyQLKos1%2FkquwUIuP%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARADGgwwMTM2MTkyNzQ4NDkiDH4ax%2FmrZveUQPSN9SqPBUHKwnD7%2BywOpu6er01pEANtU5VggRPA%2B2uik9BIGkm82z9bJG5O3rMu7TH6dagDM75g5djL6t5d93z2gWb739%2BxdOb27FNlCO4mz44BlFBOUxkun2dfz1gJUed7aWWQW2sPp0sWKeU0waXb51G8AYmyCql7WpIsUL1ZrPg3Fq%2FTCrsyYZrNZJu2XS02EFidPowpMqN2utvmlJF2iS4NOxLJraqq27au1NPw2onxLfH43qBHiz98uXXHw9oeXLc7XXj5w3Nurbdkg7tauUFvLx6H1bBExjPeR0bV7wqDniMny%2FkC9kLszHJQMMWjJwm1m%2FEFJbWTdQYAC3wx6HMsWL5ZGIu98fc8UMO7S6NU5iJbGIzEf2a3t%2FiMFWSqChtYhtrLb8LZd6Ge0Ty%2FRKQY8krn90J7NdhQUUZJZwtuGs2xnIACI59wuRVrLnOmdBON03RjrbR7GfOxbS22pjArIKwiC157ckAuuNRJoDCpPEG7Oe6MgY5Tgk%2F6VLirOO4YSqONmPLx0YBF7dZ3f6jLzxSJh2Mz5Gj%2F0RjUTsRAWAf689GLp%2BO%2FctY59m1lVtEC3lNYNqiTjxfxdsliVKbKBuxtOg9uslVlyopumeUJa8LdcgSmLRHMOe8iABccVrdjqXFjQuCD6jQZ0J5ycDvvN68EoCPenA3Iy5r%2F7UvxrxCyHOR2iJ43jIYgNZP0qxF%2FLv0cRqzJ1tq%2FGWRZp0z3oxyyXEl%2BPU8uYdpFI6jPa8GT4DCOB6za9vG5BuS%2BJDYTeTYUOWs5HcA9MwZDAB7ia729JSH38%2FoS5%2F%2B2H5s5TP5Nm%2FqyUKL%2BJ3BY6%2BKQupQnT5q00yWINarXvFoedLyhDVTrrbyTbzmmnWNQ6vHyKjQwpcKV1QY6sQFRUVBjD78jIB27UIVdSDVSEFCXAzqO4t%2Bvyc1tQnS45YrIUKjyIGuIitF3PT0fVCqS%2BFtPwg%2BpP%2FfGDE4rkS6klrDqnjKVDCxo1hFmFBVPEj%2B92avioLvb%2FnY38%2FH3r7JL6Bp7GXgneqNLvsXzIMpPLorEaxc3AZ%2BPmpJeMV66vdFC3Dwy2rZINtRsvpMiwdCI4NT%2F4PoMMQ%2BcaXq1dl7HwY6IZDebKRRCL0EcU0ABr9Y%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=f2e62ec67d49ca8c3cce8368b075092686fc2ec31f6323c348bb5eed7e49fc03) (attachment)
- [image.png](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/heqmsuc6c9nrclcaazq2zsxzu76e?response-content-disposition=attachment%3B%20filename%3D%22image.png%22%3B%20filename%2A%3DUTF-8%27%27image.png&response-content-type=image%2Fpng&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQYRULDMZV%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151032Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQCpHVN0SFSCXy06cUd2EPolqxh0A9afKuNuvSVt%2Bd4IIQIgEwBs7g0ExaV6r%2FnmKEaW%2FcHbwzYSoXeVUsyQLKos1%2FkquwUIuP%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARADGgwwMTM2MTkyNzQ4NDkiDH4ax%2FmrZveUQPSN9SqPBUHKwnD7%2BywOpu6er01pEANtU5VggRPA%2B2uik9BIGkm82z9bJG5O3rMu7TH6dagDM75g5djL6t5d93z2gWb739%2BxdOb27FNlCO4mz44BlFBOUxkun2dfz1gJUed7aWWQW2sPp0sWKeU0waXb51G8AYmyCql7WpIsUL1ZrPg3Fq%2FTCrsyYZrNZJu2XS02EFidPowpMqN2utvmlJF2iS4NOxLJraqq27au1NPw2onxLfH43qBHiz98uXXHw9oeXLc7XXj5w3Nurbdkg7tauUFvLx6H1bBExjPeR0bV7wqDniMny%2FkC9kLszHJQMMWjJwm1m%2FEFJbWTdQYAC3wx6HMsWL5ZGIu98fc8UMO7S6NU5iJbGIzEf2a3t%2FiMFWSqChtYhtrLb8LZd6Ge0Ty%2FRKQY8krn90J7NdhQUUZJZwtuGs2xnIACI59wuRVrLnOmdBON03RjrbR7GfOxbS22pjArIKwiC157ckAuuNRJoDCpPEG7Oe6MgY5Tgk%2F6VLirOO4YSqONmPLx0YBF7dZ3f6jLzxSJh2Mz5Gj%2F0RjUTsRAWAf689GLp%2BO%2FctY59m1lVtEC3lNYNqiTjxfxdsliVKbKBuxtOg9uslVlyopumeUJa8LdcgSmLRHMOe8iABccVrdjqXFjQuCD6jQZ0J5ycDvvN68EoCPenA3Iy5r%2F7UvxrxCyHOR2iJ43jIYgNZP0qxF%2FLv0cRqzJ1tq%2FGWRZp0z3oxyyXEl%2BPU8uYdpFI6jPa8GT4DCOB6za9vG5BuS%2BJDYTeTYUOWs5HcA9MwZDAB7ia729JSH38%2FoS5%2F%2B2H5s5TP5Nm%2FqyUKL%2BJ3BY6%2BKQupQnT5q00yWINarXvFoedLyhDVTrrbyTbzmmnWNQ6vHyKjQwpcKV1QY6sQFRUVBjD78jIB27UIVdSDVSEFCXAzqO4t%2Bvyc1tQnS45YrIUKjyIGuIitF3PT0fVCqS%2BFtPwg%2BpP%2FfGDE4rkS6klrDqnjKVDCxo1hFmFBVPEj%2B92avioLvb%2FnY38%2FH3r7JL6Bp7GXgneqNLvsXzIMpPLorEaxc3AZ%2BPmpJeMV66vdFC3Dwy2rZINtRsvpMiwdCI4NT%2F4PoMMQ%2BcaXq1dl7HwY6IZDebKRRCL0EcU0ABr9Y%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=3faa2826662d271a43cbffedbfad969b483dee976296c3434aa5c574ac6cdaf9) (attachment)
- [image.png](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/oja37fn7kc45syf16r0c8jifyzx5?response-content-disposition=attachment%3B%20filename%3D%22image.png%22%3B%20filename%2A%3DUTF-8%27%27image.png&response-content-type=image%2Fpng&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQYRULDMZV%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151032Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQCpHVN0SFSCXy06cUd2EPolqxh0A9afKuNuvSVt%2Bd4IIQIgEwBs7g0ExaV6r%2FnmKEaW%2FcHbwzYSoXeVUsyQLKos1%2FkquwUIuP%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARADGgwwMTM2MTkyNzQ4NDkiDH4ax%2FmrZveUQPSN9SqPBUHKwnD7%2BywOpu6er01pEANtU5VggRPA%2B2uik9BIGkm82z9bJG5O3rMu7TH6dagDM75g5djL6t5d93z2gWb739%2BxdOb27FNlCO4mz44BlFBOUxkun2dfz1gJUed7aWWQW2sPp0sWKeU0waXb51G8AYmyCql7WpIsUL1ZrPg3Fq%2FTCrsyYZrNZJu2XS02EFidPowpMqN2utvmlJF2iS4NOxLJraqq27au1NPw2onxLfH43qBHiz98uXXHw9oeXLc7XXj5w3Nurbdkg7tauUFvLx6H1bBExjPeR0bV7wqDniMny%2FkC9kLszHJQMMWjJwm1m%2FEFJbWTdQYAC3wx6HMsWL5ZGIu98fc8UMO7S6NU5iJbGIzEf2a3t%2FiMFWSqChtYhtrLb8LZd6Ge0Ty%2FRKQY8krn90J7NdhQUUZJZwtuGs2xnIACI59wuRVrLnOmdBON03RjrbR7GfOxbS22pjArIKwiC157ckAuuNRJoDCpPEG7Oe6MgY5Tgk%2F6VLirOO4YSqONmPLx0YBF7dZ3f6jLzxSJh2Mz5Gj%2F0RjUTsRAWAf689GLp%2BO%2FctY59m1lVtEC3lNYNqiTjxfxdsliVKbKBuxtOg9uslVlyopumeUJa8LdcgSmLRHMOe8iABccVrdjqXFjQuCD6jQZ0J5ycDvvN68EoCPenA3Iy5r%2F7UvxrxCyHOR2iJ43jIYgNZP0qxF%2FLv0cRqzJ1tq%2FGWRZp0z3oxyyXEl%2BPU8uYdpFI6jPa8GT4DCOB6za9vG5BuS%2BJDYTeTYUOWs5HcA9MwZDAB7ia729JSH38%2FoS5%2F%2B2H5s5TP5Nm%2FqyUKL%2BJ3BY6%2BKQupQnT5q00yWINarXvFoedLyhDVTrrbyTbzmmnWNQ6vHyKjQwpcKV1QY6sQFRUVBjD78jIB27UIVdSDVSEFCXAzqO4t%2Bvyc1tQnS45YrIUKjyIGuIitF3PT0fVCqS%2BFtPwg%2BpP%2FfGDE4rkS6klrDqnjKVDCxo1hFmFBVPEj%2B92avioLvb%2FnY38%2FH3r7JL6Bp7GXgneqNLvsXzIMpPLorEaxc3AZ%2BPmpJeMV66vdFC3Dwy2rZINtRsvpMiwdCI4NT%2F4PoMMQ%2BcaXq1dl7HwY6IZDebKRRCL0EcU0ABr9Y%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=71f1bcd50a87ccfbf7c623d46694e54087a6ba96d0eb4e1dcc94b149831bf75e) (attachment)
- [image.png](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/wa2067zdw00qfety3lcdm0v1g4pa?response-content-disposition=attachment%3B%20filename%3D%22image.png%22%3B%20filename%2A%3DUTF-8%27%27image.png&response-content-type=image%2Fpng&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQYRULDMZV%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151032Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQCpHVN0SFSCXy06cUd2EPolqxh0A9afKuNuvSVt%2Bd4IIQIgEwBs7g0ExaV6r%2FnmKEaW%2FcHbwzYSoXeVUsyQLKos1%2FkquwUIuP%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARADGgwwMTM2MTkyNzQ4NDkiDH4ax%2FmrZveUQPSN9SqPBUHKwnD7%2BywOpu6er01pEANtU5VggRPA%2B2uik9BIGkm82z9bJG5O3rMu7TH6dagDM75g5djL6t5d93z2gWb739%2BxdOb27FNlCO4mz44BlFBOUxkun2dfz1gJUed7aWWQW2sPp0sWKeU0waXb51G8AYmyCql7WpIsUL1ZrPg3Fq%2FTCrsyYZrNZJu2XS02EFidPowpMqN2utvmlJF2iS4NOxLJraqq27au1NPw2onxLfH43qBHiz98uXXHw9oeXLc7XXj5w3Nurbdkg7tauUFvLx6H1bBExjPeR0bV7wqDniMny%2FkC9kLszHJQMMWjJwm1m%2FEFJbWTdQYAC3wx6HMsWL5ZGIu98fc8UMO7S6NU5iJbGIzEf2a3t%2FiMFWSqChtYhtrLb8LZd6Ge0Ty%2FRKQY8krn90J7NdhQUUZJZwtuGs2xnIACI59wuRVrLnOmdBON03RjrbR7GfOxbS22pjArIKwiC157ckAuuNRJoDCpPEG7Oe6MgY5Tgk%2F6VLirOO4YSqONmPLx0YBF7dZ3f6jLzxSJh2Mz5Gj%2F0RjUTsRAWAf689GLp%2BO%2FctY59m1lVtEC3lNYNqiTjxfxdsliVKbKBuxtOg9uslVlyopumeUJa8LdcgSmLRHMOe8iABccVrdjqXFjQuCD6jQZ0J5ycDvvN68EoCPenA3Iy5r%2F7UvxrxCyHOR2iJ43jIYgNZP0qxF%2FLv0cRqzJ1tq%2FGWRZp0z3oxyyXEl%2BPU8uYdpFI6jPa8GT4DCOB6za9vG5BuS%2BJDYTeTYUOWs5HcA9MwZDAB7ia729JSH38%2FoS5%2F%2B2H5s5TP5Nm%2FqyUKL%2BJ3BY6%2BKQupQnT5q00yWINarXvFoedLyhDVTrrbyTbzmmnWNQ6vHyKjQwpcKV1QY6sQFRUVBjD78jIB27UIVdSDVSEFCXAzqO4t%2Bvyc1tQnS45YrIUKjyIGuIitF3PT0fVCqS%2BFtPwg%2BpP%2FfGDE4rkS6klrDqnjKVDCxo1hFmFBVPEj%2B92avioLvb%2FnY38%2FH3r7JL6Bp7GXgneqNLvsXzIMpPLorEaxc3AZ%2BPmpJeMV66vdFC3Dwy2rZINtRsvpMiwdCI4NT%2F4PoMMQ%2BcaXq1dl7HwY6IZDebKRRCL0EcU0ABr9Y%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=1ece0861fe0f165dfe6fb7810d10a259be234dbe52fef7d46ce2c7d06861c093) (attachment)
