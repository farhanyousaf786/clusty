import 'package:flutter/material.dart';

class ClustyPrivacyPolicy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            '''
Clusty Privacy Policy

Effective Date: 08/16/2024

Welcome to Clusty! We value your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and share information when you use our mobile application ("Clusty") and its related services (collectively, the "Service").

1. Information We Collect
We collect the following types of information when you use Clusty:

- **Personal Information**: When you create an account, we may collect your name, email address, username, profile picture, and any other information you provide.
- **Content**: We collect the content you create, upload, and share, such as posts, comments, messages, and other communications.
- **Usage Data**: We collect information about how you interact with the Service, including the pages you visit, features you use, and the time, frequency, and duration of your activities.
- **Device Information**: We collect information about the device you use to access the Service, such as your device type, operating system, browser type, IP address, and device identifiers.
- **Cookies and Tracking Technologies**: We use cookies and similar technologies to collect information about your browsing activities and to personalize your experience.

2. How We Use Your Information
We use the information we collect to:

- Provide, operate, and maintain the Service.
- Personalize your experience on Clusty.
- Send you updates, notifications, and other communications.
- Improve and develop new features for the Service.
- Monitor and analyze trends, usage, and activities.
- Detect, prevent, and address technical issues, security threats, and illegal activities.

3. Sharing Your Information
We may share your information in the following circumstances:

- **With Your Consent**: We may share your information with third parties when you give us explicit consent to do so.
- **Service Providers**: We may share your information with third-party service providers who perform services on our behalf, such as hosting, data analysis, and customer support.
- **Legal Obligations**: We may disclose your information if required by law, legal process, or government request.
- **Business Transfers**: If we are involved in a merger, acquisition, or sale of all or a portion of our assets, your information may be transferred as part of that transaction.

4. Your Choices and Rights
You have the following rights regarding your personal data:

- **Access and Update**: You can access and update your personal information at any time through your account settings.
- **Delete Your Account**: You can delete your Clusty account and all associated data by contacting us at [Insert Contact Information].
- **Opt-Out of Communications**: You can opt-out of receiving promotional communications from us by following the unsubscribe instructions in those communications.

5. Data Security
We take reasonable measures to protect your information from unauthorized access, loss, misuse, and alteration. However, no method of transmission over the internet or method of electronic storage is 100% secure.

6. Changes to This Privacy Policy
We may update this Privacy Policy from time to time to reflect changes in our practices or legal obligations. We will notify you of any significant changes by posting the new policy on Clusty and updating the "Effective Date" at the top of this policy.

7. Contact Us
If you have any questions or concerns about this Privacy Policy, please contact us at [Insert Contact Information].

Thank you for using Clusty!

Clusty Team
            ''',
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      ),
    );
  }
}
