const resolvedCases = [
  {
    id: '500-demo-101',
    caseNumber: '00047112',
    subject: 'Payment cleared but card credit not restored',
    category: 'Payment Posting Delay',
    resolution: 'Confirmed ACH payment cleared but available credit refresh job was delayed. Operations refreshed account after validating no return risk.',
    similarityReason: 'Same mismatch between cleared payment and available credit.'
  },
  {
    id: '500-demo-102',
    caseNumber: '00046844',
    subject: 'Travel booking blocked after large payment',
    category: 'Credit Availability',
    resolution: 'Explained processing window, checked hold status, and escalated refresh because travel purchase was time-sensitive.',
    similarityReason: 'Customer urgency and travel context match the current case.'
  },
  {
    id: '500-demo-103',
    caseNumber: '00045987',
    subject: 'Available credit still low after online payment',
    category: 'Payment Hold',
    resolution: 'Found temporary payment hold from new external bank account. Provided compliant timeline and follow-up task.',
    similarityReason: 'Potential payment hold scenario.'
  }
];

export function retrieveSimilarCases(caseRecord) {
  const text = `${caseRecord.subject || ''} ${caseRecord.description || ''}`.toLowerCase();

  return resolvedCases
    .map((item) => {
      let score = 0;
      if (text.includes('payment')) score += 2;
      if (text.includes('available credit')) score += 3;
      if (text.includes('travel')) score += item.caseNumber === '00046844' ? 2 : 0;
      if (text.includes('cleared')) score += 1;
      return { ...item, score };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, 3);
}
