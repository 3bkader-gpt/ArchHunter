# Discovered 30 BOLA + IDOR vulnerabilities in a single subdomain (BBP).

- **Category:** JWT & Session Flaws
- **Publication Date:** 2024-12-30
- **Source Channel:** Ahmed Najeh
- **Original Source URL:** [https://im4x.medium.com/discovered-30-bola-idor-vulnerabilities-in-a-single-subdomain-bbp-a382e4554e71](https://im4x.medium.com/discovered-30-bola-idor-vulnerabilities-in-a-single-subdomain-bbp-a382e4554e71)

---

## Detailed Writeup & Technical Breakdown

## Discovered 30 BOLA + IDOR vulnerabilities in a single subdomain (BBP).


--


7


Listen


Share


In this article, I’ll walk you through how I identified over 30 BOLA (Broken Object Level Authorization) and IDOR (Insecure Direct Object Reference) vulnerabilities in a single subdomain. This process involved a series of detailed steps, which I will explain in depth.


Let’s break this down into clear steps.


## Step 1: Collecting Endpoints


The first step in identifying any vulnerability is gathering all the endpoints available on the website. There are various methods to achieve this, but I prefer using JavaScript files for this task because they often contain useful routes.


I began by accessing the website and extracting JavaScript files. These files revealed several endpoints used on the site, which was dedicated to creating meetings and live streaming.


Here are some of the endpoints I found:


```
children: [{    path: "/",    element: (0, C.jsx)(o.C5, { to: "/classrooms" })}, {    path: "/classrooms/",    element: (0, C.jsx)(te, {})}, {    path: "/classrooms/create",    element: (0, C.jsx)(ie, {})}, {    path: "/classrooms/:id",    element: (0, C.jsx)(oe, {})}, {    path: "/sessions",    element: (0, C.jsx)(J, {})}, {    path: "/sessions/create",    element: (0, C.jsx)($, {})}]
```


These endpoints were accessible and revealed sensitive data through the API, such as:


```
https://class.test.com/api/sessions/
```


This was my first indication of a potential vulnerability, as sensitive data was exposed through the API.


## Step 2: Testing for Dangerous Methods


Next, I examined the JavaScript files more closely to check what HTTP methods were supported by these endpoints. I found that some endpoints accepted the DELETE method, which posed a significant risk.


## Sending a DELETE Request


I sent a DELETE request to the following endpoint:


```
DELETE class.test.com/api/classrooms/:id
```


To my surprise, this request successfully deleted a classroom! This turned what I initially thought was just data leakage into a much more severe vulnerability — data deletion.


I escalated this finding and reported the vulnerability with a higher severity rating.


## Testing Other Endpoints


I repeated this process for other endpoints, attempting to delete other resources and escalate the severity of any discovered vulnerability.


## Step 3: Exploring Potential Data Leaks


Now, I wanted to test for more data leaks, especially information about the admin and user roles. Here’s how I approached it:


## Creating Test Accounts


I created two accounts on the site:

- Admin Account
- User Account

## Adding User to a Classroom


From the Admin Account, I created a classroom and added the User Account to it. I then enabled proxying for the User Account and disabled it for the Admin Account.


## Inspecting HTTP History


I used the User Account’s browser and began inspecting the HTTP history. I filtered for any sensitive information that could be related to the Admin Account, such as the admin’s email.


By clicking on various links and monitoring the HTTP history, I was able to identify several instances where sensitive data leaked due to the lack of proper access control.


## Escalating Privileges


Once I identified data leaks, I manipulated the HTTP methods. For example, I changed the HTTP method to DELETE and tested whether I could remove the User Account from the classroom.


This testing helped me identify a higher-risk vulnerability: the ability to escalate privileges and affect users in an unauthorized manner.


## Step 4: Gathering Additional Admin Data


To ensure I didn’t miss any important endpoints, I performed one more round of tests focused on gathering any admin-specific information that might still be exposed.


## Inspecting Admin Data


I used the Admin Account’s browser and disabled the proxy to capture any sensitive data in the HTTP history. I specifically looked for links that returned data in JSON format (like API responses). One example was:


```
https://test.test.com/api/recordings/<id>
```


I gathered all these links and tested them by opening them in the User Account’s browser. This allowed me to confirm if sensitive admin data could be accessed by a regular user.


## Additional Techniques for Escalating Privileges


In addition to the methods mentioned above, there are many more techniques I used to escalate privileges from a regular user account to an admin account. Some of these methods I haven’t detailed here for security reasons.


These techniques were key in finding vulnerabilities and taking them to a higher level of severity.


## Conclusion


In total, by following the steps outlined above, I was able to find 30 BOLA + IDOR vulnerabilities in a single subdomain. These vulnerabilities ranged from data leaks to full-blown privilege escalation, and I reported them to the respective bug bounty program.


This process demonstrates the importance of thorough testing and exploring all available endpoints, as well as the value of understanding how the application handles authentication and authorization.


Stay safe, and happy hunting!

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
