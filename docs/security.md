# Security

## Salesforce Controls

- Use `WITH USER_MODE` for user-context reads where supported.
- Use `Security.stripInaccessible` before create and update operations.
- Store AI output in `AI_Interaction__c` rather than directly updating customer-facing Case fields.
- Require agent accept, edit, or reject decisions. The project never automatically closes a Case.
- Use the `AI_Case_Copilot_User` permission set for scoped object and field access.
- Use Named Credentials for endpoints and authentication configuration.

## Secrets

No API keys or credentials belong in source control. Configure production providers through environment variables, secure runtime secret stores, or Salesforce Named Credentials.

## Prompt Injection

Case subject, description, comments, Knowledge content, and similar Case notes are treated as untrusted input. The AI service wraps customer content in a security envelope and detects obvious injection attempts such as requests to ignore instructions or reveal hidden prompts.

## Sensitive Data

The sample data is synthetic. In production, add:

- PII redaction before prompt construction.
- Field allowlists for Case context.
- Data retention policies for AI request and response logs.
- Model/provider contractual review.
- Event monitoring for unusual request volume.

## Output Validation

The AI service validates required fields, types, arrays, and confidence bounds. Salesforce stores the structured response as JSON for auditability and renders it only for the reviewing agent.

## Human Approval

The LWC supports Accept, Edit, and Reject. Agent feedback is captured in `AI_Interaction__c.Agent_Feedback__c`. No automated Case closure or customer send action is implemented.
