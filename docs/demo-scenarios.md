# Demo Scenarios

## Banking Scenario: Payment Posted, Available Credit Delayed

### Case

- Product: Credit Card
- Priority: High
- Subject: Credit card payment posted but available credit not updated
- Description: Customer made a $750 payment yesterday. Their bank shows the payment cleared, but the card available credit has not changed. Customer needs to book travel today.

### Expected Assistant Output

- Summary: Customer reports a cleared payment with delayed available credit update.
- Category: Payment Posting Delay.
- Knowledge: Payment hold timing, manual refresh escalation, customer messaging.
- Similar Cases: Prior resolved Cases involving cleared payments and delayed available credit refreshes.
- Recommended Steps:
  - Verify payment amount, date, and source.
  - Check hold, return-risk, fraud-review, and batch status.
  - Escalate to card operations if payment is settled and customer urgency qualifies.
  - Document evidence and schedule follow-up.
- Proposed Resolution: Escalate for available-credit refresh when validation passes; otherwise provide a verified processing timeline.
- Draft Response: Empathetic explanation that funds clearing and available credit updates can follow different processing timelines.

### Agent Approval

The agent reviews the recommendation, edits the draft response if needed, then accepts, edits, or rejects the AI recommendation. No Case status automation occurs.
