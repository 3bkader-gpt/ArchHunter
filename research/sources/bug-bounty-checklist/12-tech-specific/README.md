# Tech-Specific Playbooks

Product/framework-specific enumeration and known-CVE checklists. Once `00-recon/04-fingerprinting.md` tells you the stack, come here for the paths, servlets, and CVEs that only apply to *that* product. These are high-hit, low-competition when the target runs an unpatched or misconfigured instance.

| File | Stack |
|------|-------|
| `01-django.md` | Django (debug panel → RCE, exposed paths, fuzzing) |
| `02-symfony.md` | Symfony (profiler exposure, secret fragment RCE) |
| `03-jira-confluence.md` | Atlassian Jira / Confluence (SSRF, XSS, file read, user enum CVEs) |
| `04-aem.md` | Adobe Experience Manager (dispatcher bypass, JCR dump, SSRF, Groovy RCE) |
| `05-nextjs-nuxt.md` | Next.js / Nuxt (CVE-2025-29927 middleware bypass, cache-poisoning DoS/XSS, CP-DoS headers) |
| `06-aspnet-iis.md` | ASP.NET / IIS (ViewState→RCE, 8.3 short-name, cookieless path bypass, diagnostic leaks) |

Bundled nuclei templates: `exposing-django.yaml`, `symfony-template_1..4.yaml`.
