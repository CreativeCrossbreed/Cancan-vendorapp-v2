// Pricing defaults, used when a vendor hasn't set an explicit price/commission.
export const DEFAULT_PER_BOTTLE_COMMISSION = Number.parseFloat(
  process.env.DEFAULT_PER_BOTTLE_COMMISSION || '1',
);
export const DEFAULT_BOTTLE_PRICE = Number.parseFloat(process.env.DEFAULT_BOTTLE_PRICE || '30');
