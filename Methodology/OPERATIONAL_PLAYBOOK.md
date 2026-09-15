# MASTER OPERATIONAL PLAYBOOK: PRACTICAL BUG BOUNTY METHODOLOGY

هذا الدليل يمثل مسار العمل التكتيكي الموحد الذي يجمع بين **الفحص اليدوي الميداني في Burp Suite** و**التحليل المعماري الهجومي** و**سلاسل الاستطلاع المؤتمتة**. يجب على أي باحث أو عميل ذكاء اصطناعي تتبع هذه المراحل بالترتيب.

> 📘 **الأدلة التكتيكية ومصادر التنفيذ:**
> *   **فحص Burp Suite ومنطق الأعمال:** راجع **[PRACTICAL_BURP_HUNTING_GUIDE.md](PRACTICAL_BURP_HUNTING_GUIDE.md)** لتطبيق فحص الحسابين (User A vs User B)، سكريبتات Turbo Intruder، وتخطي حماية الصلاحيات.
> *   **سلاسل أدوات الاستطلاع والفوزنج:** راجع **[BUG_BOUNTY_TOOLKIT_PLAYBOOK.md](BUG_BOUNTY_TOOLKIT_PLAYBOOK.md)** لتشغيل بايبلاينز Subfinder + Katana + Uro + GF + Arjun.
> *   **فهرس السكريبتات التكتيكية (21 سكريبت):** راجع **[scripts/README.md](../scripts/README.md)** لأوامر التشغيل المباشرة لـ Bash و PowerShell.
> *   **قواعد بيانات الـ Payloads والتخطي:** راجع **[payloads/README.md](../payloads/README.md)** لاستخدام 5,865 ترويسة لتخطي 403 وقوالب GF الجاهزة.

---

## 0. فهم نموذج العمل وحركة الفلوس (Phase 0: Business & Money Flow)
*الهدف: الإجابة على الأسئلة الحيوية قبل تشغيل أي أداة لضمان التركيز على الميزات التي تدر مكافآت حقيقية.*

قبل إطلاق أي أمر في الـ Terminal، أجب على الـ 4 أسئلة التالية:
1. **الشركة دي بتكسب فلوس منين؟** (اشتراكات Tiered Plans، بيع منتجات، عمولات تحويل، شحن رصيد).
2. **أغلى داتا عندهم إيه؟** (بيانات بطاقات، فواتير B2B، محادثات خاصة، وثائق KYC، API Keys).
3. **مين أنواع المستخدمين؟** (Super Admin، Org Owner، Member، Guest، Support Agent، Public).
4. **أين تقع الميزات المعقدة (Feature Density)؟**
   - دعوات الأعضاء وتغيير الأدوار (`/team/invite`, `/roles`).
   - عمليات الدفع والترقية واستخدام الكوبونات (`/checkout`, `/billing`, `/coupons`).
   - عمليات التصدير والتقارير المجمعة (`/export/csv`, `/bulk_delete`).
   - استعادة الحساب وتغيير البريد (`/account/security`, `/oauth/link`).

### قواعد الانضباط الميداني الصارم (The Standing Discipline)
قبل وأثناء تنفيذ الفحوصات الميدانية، يلتزم الباحث بالقواعد المنهجية الخمس التالية:
1. **فرضية واحدة في المرة (One Hypothesis at a Time):** تجنب الاختبار العشوائي والحقن الأعمى. صغ فرضية صريحة: *"أعتقد أن السيرفر لا يتحقق من ملكية الفاتورة للمنظمة الحالية"* ثم صمم أصغر تجربة تثبت أو تنفي ذلك.
2. **مبدأ التجربة الضابطة (Negative Control Baseline):** كل ادعاء بوجود ثغرة يحتاج إلى تجربة تحكم ضابطة كان يمكن أن تفشل:
   ```
   الطلب الأصلي السليم  ──► استجابة طبيعية (Baseline A)
   الطلب المعدل بشرط TRUE ──► استجابة متطابقة / نجاح (Condition TRUE)
   الطلب المعدل بشرط FALSE ─► استجابة مختلفة / رفض (Condition FALSE)
   ```
   *تنبيه:* ظهور خطأ `500 Internal Server Error` ليس دليلاً على ثغرة، بل هو مجرد استثناء برمجي (Exception)؛ الدليل الحقيقي هو الفارق المستمر والمنطقي بين حالتي الـ Control والـ Exploit.
3. **فصل توليد الأفكار عن فلترتها (Two-Pass Lead Generation):** أثناء تصفح التطبيق ورسم المعمارية، دوّن كل سلوك غريب فوراً في قائمة الملاحظات دون التوقف للحكم النهائي. بعد اكتمال الجولة، خصص وقتاً مستقلاً لتقييم الشبهات واختبارها (هذا يمنع قتل الأفكار الواعدة مبكراً).
4. **قاعدة التدوير عند انعدام الإشارة (Rotate When Signal Fades):** إذا استمرت النتائج نظيفة بعد فحص منهجي كامل للميزة، **لا تواصل الحفر في نقطة مسدودة لساعات**. دوّر الاختبار فوراً عبر تغيير: الميزة، أو رتبة المستخدم، أو الـ Endpoint، أو زاوية الهجوم.
5. **توثيق المستبعدات وليس المكتشفات فقط (Write Down Negatives):**
   توثيق ما ثبتت سلامته وحمايته يوفر 50% من الجهد ويمنع إعادة فحص نفس النطاق:
   ```
   [NEGATIVE / CLOSED] /api/v1/admin/users
   - Tested by: Member (Org A)
   - Result: 403 Forbidden with strict server validation.
   - Status: Ruled Out / Closed.
   ```

---

## 1. مرحلة الاستطلاع المركّز (Reconnaissance)
*الهدف: تكبير مساحة الهجوم ورصد الأصول الحساسة مع التركيز على الـ Dashboards الحية والـ APIs بدلاً من النطاقات الميتة.*

### أ. الاستطلاع السلبي (Passive Recon)
*جمع البيانات دون التفاعل المباشر مع سيرفرات التارجت:*
*   **Multi-Engine Aggregation:** تجميع النطاقات السلبية من محركات متعددة مع كشف الشهادات (`crt.sh`):
    ```bash
    subfinder -d target.com -all -silent | anew recon/subs/passive_subs.txt
    assetfinder --subs-only target.com | anew recon/subs/passive_subs.txt
    findomain -t target.com -q | anew recon/subs/passive_subs.txt
    curl -s "https://crt.sh/?q=%.target.com&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | anew recon/subs/passive_subs.txt
    ```
*   **ASN & Reverse DNS:** تحويل نطاقات الـ ASN والـ CIDRs إلى نطاقات فرعية عبر الـ PTR:
    ```bash
    asnmap -d target.com -silent | hakrevdns -d | grep -i "target.com" | awk '{print $2}' | anew recon/subs/passive_subs.txt
    ```
*   **OSINT & GitHub Dorks:** البحث في GitHub عن أكواد ومستودعات مسربة باستخدام `github-subdomains`.
*   **Historical Recon & 404 Archaeology:** سحب مسارات قديمة وإحياء ملفات الـ 404 المنسية عبر `gau` و `waybackurls`.

### ب. الاستطلاع النشط (Active Recon)
*التفاعل المباشر مع الأصول لتحديد النشط منها واكتشاف البنى المخفية:*
*   **DNS Resolution & Trusted Resolvers:** تصفية النطاقات الفعالة باستخدام سيرفرات DNS موثوقة لتجنب الحظر:
    ```bash
    cat recon/subs/passive_subs.txt | dnsx -r recon/resolvers.txt -silent -a -cname -resp | anew recon/subs/resolved_subs.txt
    ```
*   **Active DNS Brute-Forcing:** تخمين النطاقات الفرعية غير المفهرسة باستخدام Wordlist و `puredns`:
    ```bash
    puredns bruteforce /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt target.com -r recon/resolvers.txt --write recon/subs/brute_subs.txt
    ```
*   **Smart Permutations & Fuzzing:** تخمين طفرات التسمية بالشرطة (`dev-api`, `pr-12`) والأرقام (`app1`, `dev01`):
    ```bash
    ffuf -u "https://FUZZ-api.target.com" -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -mc 200,301,302,401,403 -silent
    ```
*   **Virtual Host (VHost) Fuzzing:** فحص النطاقات الافتراضية على الـ Origin IP مع فلترة حجم الاستجابة (`-fs`):
    ```bash
    ffuf -u 'https://TARGET_IP' -H 'Host: FUZZ.target.com' -w wordlist.txt -fs DEFAULT_SIZE -mc 200,301,302,401,403
    ```
*   **Port Scanning & Tech Detection:** فحص المنافذ والتقنيات وتوليد الـ Signals:
    ```bash
    cat recon/subs/resolved_subs.txt | httpx -ports 80,443,8080,8443,3000,9000,5000,50051 -sc -title -tech-detect -follow-redirects -json -o recon/signals.jsonl
    ```

### ج. تحليل الجافاسكريبت والأسرار (JavaScript Intelligence)
*معاملة ملفات الـ JS كمصدر أولي للأسرار والمعمارية:*
*   **JS Extraction & JS Miner:** استخدام إضافة **`JS Miner`** في Burp Suite لسحب الـ Subdomains والأسرار تلقائياً، والـ CLI عبر:
    ```bash
    cat recon/subs/alive_hosts.txt | katana -jc -d 3 | grep -iE '\.js(\?|$)' | anew recon/urls/js_files.txt
    ```
*   **Source Maps:** البحث عن ملفات الـ `.js.map` لاستعادة الكود الأصلي وتحديد مسارات الـ Admin والـ Hidden Endpoints.
*   **Secrets Triage Matrix:** تصنيف أي مفتاح يتم العثور عليه قبل اعتباره ثغرة:
    - *Public Identifiers:* (Firebase API key, Mapbox, Sentry DSN) $\rightarrow$ ليست ثغرات.
    - *Client Configs:* (Public OAuth Client IDs, Algolia search keys) $\rightarrow$ حركة مقصودة.
    - *High-Privilege Secrets:* (AWS Keys, Private JWT Secrets, Database Strings, Webhook Secrets) $\rightarrow$ أسرار حرجة يتم التحقق من أثرها الآمن فوراً.

*المستندات التشغيلية المرتبطة:*
*   **[Workflow 01 — Target Selection](../Workflow/01_target_selection.md)**
*   **[Workflow 02 — Passive Recon](../Workflow/02_passive_recon.md)**
*   **[Workflow 03 — Active Mapping](../Workflow/03_active_mapping.md)**
*   **[skills/_INDEX.md](../skills/_INDEX.md)** (فهرس المهارات لتحديد نوع الثغرة المناسب).

---

## 2. فهم التطبيق ورسم الخريطة (Mapping & Application Logic)
*الهدف: فهم كيفية عمل التطبيق من منظور منطق الأعمال وصلاحيات المستخدمين، ورسم حدود الثقة (Trust Boundaries).*

### أ. إعداد البيئة والحسابات
*   **Setup the Proxy (Burp Suite):** تمرير كل حركة مرور الشبكة عبر البروكسي للتسجيل.
    > [!IMPORTANT]
    > **الترويسة الإلزامية:** يجب تضمين ترويسة HTTP لـ HackerOne في كافة ريكويستات الفحص:
    > `X-HackerOne-Researcher: qalbaz_0x`
*   **Account Matrix Creation:** إنشاء مصفوفة حسابات بصلاحيات وبيئات مختلفة:
    - `ADMIN` (مدير / Org A)
    - `MEMBER` (مستخدم عادي / Org A)
    - `TENANT_B` (مستخدم من شركة أخرى / Org B)
    - `ANONYMOUS` (بدون تسجيل دخول)

### ب. مصفوفة فحص الصلاحيات الـ 8 (Authorization Comparison Matrix)
عند اختبار أي Endpoint حساس، يجب تنفيذ المقارنات الـ 8 التالية بشكل منهجي:
1. **Same Object, Different User:** محاولة قراءة/تعديل نفس الـ ID بمستخدم آخر (BOLA / IDOR).
2. **Different Tenant, Same Role:** محاولة الوصول لكائنات شركة أخرى (Org B) بنفس رتبة المستخدم (Tenant Isolation).
3. **Low vs High Privilege:** تنفيذ طلبات الـ Admin بحساب Member عادي (Vertical Privilege Escalation).
4. **Read vs Write:** إذا كان الـ Endpoint يسمح بـ GET مقيد، هل يسمح بـ PUT/PATCH/DELETE بدون تحقق؟
5. **Single vs Bulk Endpoint:** هل نقاط النهاية المجمعة (`/api/v1/users/bulk_delete` أو `/export`) تتجاهل التحقق المطبق على الطلب الفردي؟
6. **Current vs Legacy API:** هل الإصدار القديم (`/api/v1/` مقابل `/api/v2/`) يفتقر للـ Authorization middleware؟
7. **UI Restrictions vs API Reality:** هل الأزرار المخفية أو المعطلة في الـ Frontend مسموح بتنفيذها برمجياً عبر الـ API؟
8. **Object-Property & Hidden Data Flow Tampering:** فحص الحقول غير المعلنة في واجهة المستخدم ولكنها مدعومة في معمارية السيرفر (Mass Assignment / Parameter Binding). جرّب حقن معاملات سرية مثل:
   `{"role": "admin", "is_admin": true, "discount": 100, "price": 0.01, "internal_note": "debug", "debug": true, "verified": true, "tier_id": 999}`.

### ج. استنتاج المعمارية والتصنيف التكيفي (Adaptive Classification)
تصنيف التارجت حسب طبيعته لتركيز الفحص:
* **API/Object-Heavy:** التركيز على IDOR، Mass Assignment، و BOLA.
* **Workflow/Transaction-Heavy:** التركيز على Race Conditions، تلاعب الأسعار، و Idempotency.
* **Identity-Heavy (OAuth/SAML/SSO):** التركيز على Redirect URI، Token Audience Confusion، و MFA Bypasses.
* **JS/SPA-Heavy:** التركيز على Client-side auth enforcement، postMessage، و DOM XSS.
* **Integration/Webhook-Heavy:** التركيز على Webhook signature bypass و SSRF.

*المستندات التشغيلية المرتبطة:*
*   **[Workflow 04 — Fingerprint to Architecture](../Workflow/04_fingerprint_to_architecture.md)**
*   **[Workflow 05 — Attack Surface Expansion](../Workflow/05_attack_surface_expansion.md)**
*   **[Methodology/Architectural_Trust_Boundary_Analysis](Architectural_Trust_Boundary_Analysis.md)**

---

## 3. البحث عن الثغرات واختبارها (Vulnerability Analysis)
*الهدف: مهاجمة الـ Endpoints والبارامترات المكتشفة بناءً على خريطة التطبيق.*

### أ. الفحص الآلي واستنتاج المعمارية
*   **تشغيل الـ Reasoning Runtime:**
    ```bash
    cd Runtime && go run cmd/runtime/main.go -input recon/alive.jsonl -format markdown
    ```
*   **WAF Detection:** تحديد نوع الجدار الناري لتحديد طرق التخطي باستخدام `wafw00f`.

### ب. الفحص اليدوي الميكانيكي (Manual Core Hunting)
وهنا يبدأ الفحص الدقيق للمكونات المعمارية باستخدام ملفات الـ **Skills** المخصصة:

*   **Access Control & ATO:**
    *   *IDOR & 40 Tamper Mutations:* تلاعب بالمعرفات وحقن مصفوفة الـ 40 تحويراً لتخطي فلاتر الـ Authz السطحية وحقول الترقية (`is_pro: true`).
        *   *Skill Pivot:* **[skills/auth_logic/logic_idor_auth.md](../skills/auth_logic/logic_idor_auth.md)**
    *   *SAML XSW & Enterprise SSO:* استغلال التفاف التوقيع الرقمي وحقن التعليقات في أنظمة تسجيل الدخول الموحد.
        *   *Skill Pivot:* **[skills/auth_logic/saml_xsw_sso.md](../skills/auth_logic/saml_xsw_sso.md)**
    *   *Pre-Account Takeover & MFA Logic Bypasses:* فحص ربط حسابات الـ OAuth والتسجيل المسبق وتخطي التحقق الثنائي (MFA/2FA) عبر التلاعب باستجابة السيرفر ومسارات الـ Mobile القديمة.
        *   *Skill Pivot:* **[skills/auth_logic/mfa_logic_bypasses.md](../skills/auth_logic/mfa_logic_bypasses.md)** & **[skills/auth_logic/pre_account_takeover.md](../skills/auth_logic/pre_account_takeover.md)** & **[skills/auth_logic/auth_bypass_ato.md](../skills/auth_logic/auth_bypass_ato.md)** & **[skills/auth_logic/oauth_sso_integrity.md](../skills/auth_logic/oauth_sso_integrity.md)**
*   **Protocols, Structured APIs & Injections:**
    *   *gRPC, SOAP & RPC Attacks:* استغلال Server Reflection و Protobuf manipulation وتزوير SOAPaction headers في واجهات الميكروسيرفيسز.
        *   *Skill Pivot:* **[skills/infrastructure/grpc_soap_rpc_attacks.md](../skills/infrastructure/grpc_soap_rpc_attacks.md)** & **[skills/infrastructure/graphql_attacks.md](../skills/infrastructure/graphql_attacks.md)**
    *   *NoSQL & LDAP Injection:* حقن معاملات MongoDB (`$ne`, `$gt`, `$regex`) في تطبيقات Node.js وتجاوز مصادقة خوادم الدليل عبر LDAP wildcards.
        *   *Skill Pivot:* **[skills/infrastructure/nosql_ldap_injection.md](../skills/infrastructure/nosql_ldap_injection.md)** & **[skills/infrastructure/sql_injection.md](../skills/infrastructure/sql_injection.md)**
*   **Perimeter & Server-Side Vulnerabilities:**
    *   *Origin IP & WAF Bypass:* كشف السيرفر الحقيقي وتخطي حماية Cloudflare عبر Favicon Hash و TLS logs.
        *   *Skill Pivot:* **[skills/infrastructure/origin_ip_discovery_waf_bypass.md](../skills/infrastructure/origin_ip_discovery_waf_bypass.md)**
    *   *NGINX & Edge Routing:* استغلال الـ Off-by-slash alias traversal (`/static../`) وتضارب الـ Proxy paths.
        *   *Skill Pivot:* **[skills/infrastructure/nginx_server_edge_misconfigs.md](../skills/infrastructure/nginx_server_edge_misconfigs.md)**
    *   *Webhooks & Integration Trust:* تزوير أحداث الـ Webhooks، هجمات الـ Replay، والـ Outbound SSRF.
        *   *Skill Pivot:* **[skills/infrastructure/webhook_integration_trust.md](../skills/infrastructure/webhook_integration_trust.md)**
    *   *SSRF & Cloud Metadata:* اختبار الـ Outbound URLs وسحب مفاتيح السحابة.
        *   *Skill Pivot:* **[skills/infrastructure/backend_ssrf_rce.md](../skills/infrastructure/backend_ssrf_rce.md)** & **[skills/infrastructure/workload_identity_federation.md](../skills/infrastructure/workload_identity_federation.md)**
    *   *RCE & Parser Diff:* فحص ثغرات الرفع والأوامر وتضارب الـ Proxies (Request Smuggling).
        *   *Skill Pivot:* **[skills/infrastructure/parser_differential_abuse.md](../skills/infrastructure/parser_differential_abuse.md)** & **[skills/infrastructure/parser_implementation_integrity.md](../skills/infrastructure/parser_implementation_integrity.md)** & **[skills/infrastructure/advanced_injection_rce.md](../skills/infrastructure/advanced_injection_rce.md)**
*   **Business Logic & Financial State:**
    *   *Financial & Inventory Abuse:* فحص التلاعب بالأسعار، العملات، حجز المخزون (Cart DoS)، وتكرار الكوبونات.
        *   *Skill Pivot:* **[skills/state_management/business_logic_financial.md](../skills/state_management/business_logic_financial.md)** & **[skills/state_management/race_conditions.md](../skills/state_management/race_conditions.md)**
    *   *Rate Limit Evasion:* تدوير الترويسات الـ 8 وتلاعب مسارات الـ URI وتخمين الـ OTP والـ Passwords.
        *   *Skill Pivot:* **[skills/state_management/rate_limiting_evasion.md](../skills/state_management/rate_limiting_evasion.md)**
    *   *Async & Consistency Drift:* تأخير المزامنة، حالات التسابق، وتضارب قواعد البيانات.
        *   *Skill Pivot:* **[skills/state_management/async_workflow_integrity.md](../skills/state_management/async_workflow_integrity.md)** & **[skills/state_management/consistency_failures.md](../skills/state_management/consistency_failures.md)**
*   **Client-Side Vulnerabilities:**
    *   *Clickjacking & UI Redressing:* استغلال العمليات الحساسة بضغطة واحدة (1-Click Actions).
        *   *Skill Pivot:* **[skills/infrastructure/clickjacking_ui_redressing.md](../skills/infrastructure/clickjacking_ui_redressing.md)**
    *   *Client-Side Path Traversal (CSPT):* مسارات الـ fetch الديناميكية في تطبيقات الـ SPA.
        *   *Skill Pivot:* **[skills/infrastructure/cspt_client_side_path_traversal.md](../skills/infrastructure/cspt_client_side_path_traversal.md)**
    *   *XSS, CORS, CSRF:*
        *   *Skill Pivot:* **[skills/infrastructure/xss_variations.md](../skills/infrastructure/xss_variations.md)** & **[skills/state_management/cors_regex_bypass.md](../skills/state_management/cors_regex_bypass.md)** & **[skills/state_management/cross_subdomain_csrf.md](../skills/state_management/cross_subdomain_csrf.md)**
*   **Emerging Surface & AI Chatbots:** فحص محركات الذكاء الاصطناعي (LLM/RAG) وتخطي حدود الاستهلاك.
    *   *Skill Pivot:* **[skills/emerging/llm_rag_privesc.md](../skills/emerging/llm_rag_privesc.md)**

*المستندات التشغيلية المرتبطة:*
*   **[Workflow 06 — Manual Validation](../Workflow/06_manual_validation.md)**
*   **[Methodology/PRACTICAL_BURP_HUNTING_GUIDE.md](PRACTICAL_BURP_HUNTING_GUIDE.md)** (انضباط التحقق من الخادم وليس الواجهة)

---

## 4. إثبات الاستغلال وتصعيد الخطورة (Exploitation & Impact)
*الهدف: إثبات الأثر الأقصى للثغرة (بشكل آمن ودون تخريب للتطبيق).*

*   **Proof of Concept (PoC) Creation:** تجهيز ريكويست نظيف أو سكريبت يثبت الثغرة بشكل قاطع.
*   **Vulnerability Chaining:** ربط عدة ثغرات معاً لزيادة الأثر:
    *   تحويل ثغرة **IDOR** بسيطة إلى **Account Takeover (ATO)** كامل.
    *   استغلال **SSRF** لسحب بيانات اعتماد السحابة (AWS Metadata) والوصول لـ **RCE**.
    *   استغلال **XSS** لسرقة جلسات الدخول (Session Hijacking).
*   **Safe Extraction:** قراءة سطر واحد فقط لإثبات الضرر (مثل `/etc/passwd` أو تنفيذ `whoami`).
*   **10-Point Validation Gate & Ruthless Triager:** قبل كتابة التقرير، إخضاع النتيجة لبوابة التحقق الـ 10 وأداة التقييم القاسية في **[claude.md](../claude.md) (القسم 4)** لضمان قبول التقرير وصرف المكافأة.

*المستندات التشغيلية المرتبطة:*
*   **[Workflow 07 — Chain Building](../Workflow/07_chain_building.md)**
*   **[Workflow 08 — Impact Modeling](../Workflow/08_impact_modeling.md)**
*   **[Workflow 09 — Reporting](../Workflow/09_reporting.md)**
