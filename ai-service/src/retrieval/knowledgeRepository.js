const articles = [
  {
    id: 'ka0-demo-001',
    title: 'Credit card payment hold and available credit timing',
    summary: 'Payments may post to the ledger before available credit updates when fraud, bank-return, or late-cycle hold checks are pending.',
    product: 'Credit Card',
    category: 'Payments',
    resolutionHint: 'Verify payment status, hold code, posting batch, and account-level risk indicators before promising immediate credit availability.'
  },
  {
    id: 'ka0-demo-002',
    title: 'Manual available credit refresh escalation',
    summary: 'Operations can refresh available credit after payment validation when the automated posting job is delayed.',
    product: 'Credit Card',
    category: 'Account Servicing',
    resolutionHint: 'Escalate to card operations with payment amount, payment date, external confirmation, and customer urgency.'
  },
  {
    id: 'ka0-demo-003',
    title: 'Customer messaging for payment processing delays',
    summary: 'Use clear language explaining that cleared bank funds and card available credit can update on different processing timelines.',
    product: 'Credit Card',
    category: 'Customer Communication',
    resolutionHint: 'Avoid guaranteeing an exact time unless verified in servicing systems.'
  }
];

export function retrieveKnowledge(caseRecord) {
  const text = `${caseRecord.subject || ''} ${caseRecord.description || ''}`.toLowerCase();

  return articles
    .map((article) => {
      let score = 0;
      if (text.includes('payment')) score += 3;
      if (text.includes('available credit')) score += 3;
      if (text.includes('credit card')) score += 2;
      if (article.product === caseRecord.product) score += 2;
      if (text.includes('delay') || text.includes('updated')) score += 1;
      return { ...article, score };
    })
    .filter((article) => article.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 3);
}
