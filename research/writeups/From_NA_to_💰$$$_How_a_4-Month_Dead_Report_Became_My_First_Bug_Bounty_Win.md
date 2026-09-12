Title: From N/A to 💰$$$: How a 4-Month Dead Report Became My First Bug Bounty Win

URL Source: https://medium.com/@Brian_Bange/from-n-a-to-how-a-4-month-dead-report-became-my-first-bug-bounty-win-3b2338c86a31

Published Time: 2026-09-11T14:00:02Z

Markdown Content:
[![Image 1: Brian Bange](https://miro.medium.com/v2/da:true/resize:fill:32:32/0*SmTAkqyzgk_qAwWT)](https://medium.com/@Brian_Bange?source=post_page---byline--3b2338c86a31-----------------------------------------)

3 min read

1 day ago

If you’re grinding your first year in bug bounty, you know the feeling. You spend hours hunting, finally submit what looks like a great bug, and wake up to the dreaded “Not Applicable” (N/A) or “Duplicate.”

For months, my dashboard was a graveyard of rejected reports. But my very first bounty payout didn’t come from a fresh submission — it came from a 4-month-old N/A report that miraculously came back from the dead.

Here is the story of how I found a supply chain vulnerability, lost it to strict triage rules, and used a little bit of professional social engineering to secure the win.

## The Find: Leaking Internal Scopes

While hacking on a massive private program (`[REDACTED_COMPANY]`), I started digging through their compiled frontend JavaScript bundles. Inside a heavily obfuscated `clientlib` file, I spotted a recurring module path:

`@redacted-scope/core`

Press enter or click to view image in full size

![Image 2](https://miro.medium.com/v2/resize:fit:700/1*gxT7Hut_3t8SWE4_cIOcmg.png)

I immediately checked the public npm registry. **The**`@redacted-scope`**organization didn't exist.**

Knowing the risk of Dependency Confusion (where a misconfigured internal proxy pulls a public malicious package instead of the internal one), I moved fast. To protect the company and prove the concept, I registered the scope on the public npm registry and published a completely empty, benign PoC package. I secured the namespace before a real threat actor could.

## The Brick Wall: Triage Says “No”

I wrote up a detailed report and submitted it. I was hyped.

Days later, triage closed it as N/A.

![Image 3](https://miro.medium.com/v2/resize:fit:364/1*WNNjwdMzTi1hisUebHEIDg.png)

Their reasoning? I didn’t provide a pingback or run `whoami` on the internal build servers. Without proof of execution, triage assumed the company's internal proxies successfully blocked public fallbacks. Because I played it safe and ethical—refusing to drop a reverse shell in my package—the report was killed. I took the reputation hit and moved on.

## The Plot Twist: “Can we have our namespace back?”

Four months passed. I was still grinding away when an email suddenly landed in my inbox from a Product Owner at `[REDACTED_COMPANY]`.

## Get Brian Bange’s stories in your inbox

Join Medium for free to get updates from this writer.

Remember me for faster sign in

They noticed my PoC on npm. They politely explained they needed the namespace for their internal developers and asked if I would transfer ownership to them.

This was my golden ticket.

## The Reversal: Professionalism Pays Off

I replied immediately. I didn’t hold the scope hostage, and I didn’t demand money. I simply said:

_“I am happy to transfer this to your maintainers today. However, I actually responsibly disclosed this exact issue to your bug bounty program months ago, but it was closed as N/A because I refused to execute unauthorized code on your servers to prove impact. Could your security team take a second look?”_

A few days later, the client logged directly into the platform. They confirmed that while my package was technically blocked by their defenses, leaving the namespace vulnerable to hijacking was a major administrative oversight. They cited my report as highlighting a critical “best practice,” completely overruled the triage team, and reopened the ticket.

Press enter or click to view image in full size

![Image 4](https://miro.medium.com/v2/resize:fit:700/1*yqxCmmFbPjCcZbU2jZQjSA.png)

Shortly after, I was awarded my very first bounty **$$$**.

## The Takeaway

1.   **Stay Ethical:** If I had tried to force an RCE to please triage, I might have violated the rules of engagement. Playing it safe allowed me to have a professional conversation with the client months later.
2.   **Never Hold Assets Hostage:** Gracefully handing over the npm scope built the goodwill needed for the client to advocate for me internally.
3.   **Keep Grinding:** If you are drowning in N/As, keep going. Your breakthrough is coming.

The first win is the hardest. Now, it’s back to the hunt!
