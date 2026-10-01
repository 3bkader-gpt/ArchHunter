# Report #1735622: Reflected XSS in chatbot

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/1735622](https://hackerone.com/reports/1735622)
- **Program:** MTN Group
- **Reporter:** @roland_hack
- **Status:** RESOLVED
- **Severity:** medium
- **Weakness:** Cross-site Scripting (XSS) - Reflected
- **Bounty:** No Bounty / Swag
- **Submitted:** 2022-10-14T14:27:13.365Z
- **Disclosed:** 2022-11-19T15:56:51.530Z
- **Community Upvotes:** 9

---

## Executive Summaries

No formal disclosure summary provided.

---

## Full Vulnerability Description & Reproduction Steps

Reflected XSS attacks, also known as non-persistent attacks, occur when a malicious script is reflected off of a web application to the victim's browser. The script is activated through a link, which sends a request to a website with a vulnerability that enables execution of malicious scripts
Proof of Concept
1)Go to the website https://mtn.com.gh/
2)click on the MTN chat and where it asks to enter a number enter an xss payload
3)In my case I put the following payload:<button onClick="alert('xss')">Submit</button>

## Impact

If an attacker can control a script running in the victim's browser, they can usually completely compromise that user. Among other things, the attacker can: Perform any action in the application that the user can perform.

---

## Attachments
- [mtn_chatbot_xss_2.png](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/go9pbbf1xpi1zbnbya472r64q7sm?response-content-disposition=attachment%3B%20filename%3D%22mtn_chatbot_xss_2.png%22%3B%20filename%2A%3DUTF-8%27%27mtn_chatbot_xss_2.png&response-content-type=image%2Fpng&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQ7QT5CAKX%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151015Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJGMEQCIHCRufs3KlvHCn%2FkO%2B3pyoIFglWwJ%2Frb6fK1NpcFSPHaAiBL8JmDPrKPUBi83OK7WBx5zQC1P3mZf3wlJwskF%2FRxFCq7BQi4%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAMaDDAxMzYxOTI3NDg0OSIMEzfHNCaBnG61Y71uKo8FvCteFtj%2B3vRgUjGVZaOfSJZFsrCWV4MdAX8kX5XjLav8asBT%2FZ%2BtmIRZ2lb8qnVQW5M3FmSTqbpLlllboduWUsgLLzzPpRbEQry1lS9rc7oR63RdgqrNGXA1wCde2yDa69mDMQ6LWWdI99lDsKkCMnY9PP52WQCWrxisAVaSbCoJkaOLw%2Bwl7arC5QreHk9htwAyvL9hF3V6eSnL5t3DLpYWW8TVCw1c3jIM4ZQxOhwp%2F7DhMDlIptF9uvbGTuvsiA6oXBMV10UQOoZQUNww3ZGhUaOaiiEL86ztTAjLKwDe2flV5jf1fk%2BTLT3Mnfp46Ta43SXie0l%2FAqJdbDj4OhqZdchKqSyUTQRN1qa0FMVWuHy9Q9gQSVreZBz87STq97%2FPQn%2B4U%2B4pedlues4Wl%2B6IO1uaJn%2BtIBkXiIGxCeYHCEwjnKEHhwsfi8dbDcMU7FJpnYcNWUf8EH%2B5pfcB9Mc1OF0toIa1sBCVrLQa8XingG9XjPOF2amqxEOHxON23%2FTJaYkTHfxJF53SKW8faju1ZH0dhhHUrXyQiPUQCh9yZg%2BYlmF4qMC2x620sATGjROmGwjp0hDMSmvXYG5hrqEpX1ts8MO%2FdKgvxvjR9%2FKWau36U6NO9bt59JcCTEcr5wtGFSNZ8cZUBhb41B56sfl4%2BhSC5wXDKwpWLFDr2K0cA8m9Iv3YyIF%2BNigXlxtVdM072LwnR5Xrtx3iOvrEmHpQZbMoaESqkou6sYn3FzUwcuyrlGZloCnu5bPyTjEQ4W%2FPUhKAgbFJsOzLIbgmDZvFbJvOQ50R1aJlZLTL5cgsHQvr0p9mF5j5%2FEpapcDWfjzcQ0Y26I5KvQ23az7HC3FSzOK27%2FHDpIR4rTJd%2FjC8wpXVBjqyAR2sv4D4OzT69yvNl5hfs%2BMv2dg8Pj8dgKtuIe0T3MMD1vh259DDsnSKWk9TpDGJkLvDJejin1REbSw9oRYwrxn0NgZ%2FzzEIIaOcruwsdyAKPbHC%2BSsJ4qTkgDgZuFi4ReGs7gbhFi6qGyTltMavd25k1LPGORXL9iW8t8jGlTJW7N3CDAX4119U%2F4FBxiE6z66rJdr3XguTCqrma8pZoXxkjBAaAFLLEQEDhBYxo%2BLaPRs%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=207e63e631159216a948ed8b0dca21c34858eb31f2009f6d06d6521bb1f6399e) (attachment)
- [recording-1665764779722.webm](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/0aecdjimvt4j51suspxu0j672aj7?response-content-disposition=attachment%3B%20filename%3D%22recording-1665764779722.webm%22%3B%20filename%2A%3DUTF-8%27%27recording-1665764779722.webm&response-content-type=video%2Fwebm&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQ7QT5CAKX%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151015Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJGMEQCIHCRufs3KlvHCn%2FkO%2B3pyoIFglWwJ%2Frb6fK1NpcFSPHaAiBL8JmDPrKPUBi83OK7WBx5zQC1P3mZf3wlJwskF%2FRxFCq7BQi4%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAMaDDAxMzYxOTI3NDg0OSIMEzfHNCaBnG61Y71uKo8FvCteFtj%2B3vRgUjGVZaOfSJZFsrCWV4MdAX8kX5XjLav8asBT%2FZ%2BtmIRZ2lb8qnVQW5M3FmSTqbpLlllboduWUsgLLzzPpRbEQry1lS9rc7oR63RdgqrNGXA1wCde2yDa69mDMQ6LWWdI99lDsKkCMnY9PP52WQCWrxisAVaSbCoJkaOLw%2Bwl7arC5QreHk9htwAyvL9hF3V6eSnL5t3DLpYWW8TVCw1c3jIM4ZQxOhwp%2F7DhMDlIptF9uvbGTuvsiA6oXBMV10UQOoZQUNww3ZGhUaOaiiEL86ztTAjLKwDe2flV5jf1fk%2BTLT3Mnfp46Ta43SXie0l%2FAqJdbDj4OhqZdchKqSyUTQRN1qa0FMVWuHy9Q9gQSVreZBz87STq97%2FPQn%2B4U%2B4pedlues4Wl%2B6IO1uaJn%2BtIBkXiIGxCeYHCEwjnKEHhwsfi8dbDcMU7FJpnYcNWUf8EH%2B5pfcB9Mc1OF0toIa1sBCVrLQa8XingG9XjPOF2amqxEOHxON23%2FTJaYkTHfxJF53SKW8faju1ZH0dhhHUrXyQiPUQCh9yZg%2BYlmF4qMC2x620sATGjROmGwjp0hDMSmvXYG5hrqEpX1ts8MO%2FdKgvxvjR9%2FKWau36U6NO9bt59JcCTEcr5wtGFSNZ8cZUBhb41B56sfl4%2BhSC5wXDKwpWLFDr2K0cA8m9Iv3YyIF%2BNigXlxtVdM072LwnR5Xrtx3iOvrEmHpQZbMoaESqkou6sYn3FzUwcuyrlGZloCnu5bPyTjEQ4W%2FPUhKAgbFJsOzLIbgmDZvFbJvOQ50R1aJlZLTL5cgsHQvr0p9mF5j5%2FEpapcDWfjzcQ0Y26I5KvQ23az7HC3FSzOK27%2FHDpIR4rTJd%2FjC8wpXVBjqyAR2sv4D4OzT69yvNl5hfs%2BMv2dg8Pj8dgKtuIe0T3MMD1vh259DDsnSKWk9TpDGJkLvDJejin1REbSw9oRYwrxn0NgZ%2FzzEIIaOcruwsdyAKPbHC%2BSsJ4qTkgDgZuFi4ReGs7gbhFi6qGyTltMavd25k1LPGORXL9iW8t8jGlTJW7N3CDAX4119U%2F4FBxiE6z66rJdr3XguTCqrma8pZoXxkjBAaAFLLEQEDhBYxo%2BLaPRs%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=8cf39abb8dbdc0e0f1e14aa45d0c5d4baa2383c78e5bca62f8a11877e0c6421d) (attachment)
