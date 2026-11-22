// E3: how a Pass payment is shared between the three pool ledger balances.
// Shares follow the poolLedger field order: reward 35, operations 45, reserve 20.
export const REWARD_SHARE = 0.35;
export const OPERATIONS_SHARE = 0.45;
export const PASS_DAYS = 30;

// Price of one Pass in RWF, paid to MoMo Pay merchant 2358998. Must match
// AppConstants.passPriceRwf in the app and the amount the rules accept.
export const PASS_PRICE_RWF = 2000;

export type PoolSplit = {
  rewardBalance: number;
  operationsBalance: number;
  reserveBalance: number;
};

// Whole francs only; the reserve takes the rounding remainder so the three
// parts always add up to the amount paid.
export function splitPayment(amount: number): PoolSplit {
  if (!Number.isInteger(amount) || amount < 0) {
    throw new Error(`invalid payment amount: ${amount}`);
  }
  const rewardBalance = Math.floor(amount * REWARD_SHARE);
  const operationsBalance = Math.floor(amount * OPERATIONS_SHARE);
  return {
    rewardBalance,
    operationsBalance,
    reserveBalance: amount - rewardBalance - operationsBalance,
  };
}

export function passEnd(startsAt: Date): Date {
  return new Date(startsAt.getTime() + PASS_DAYS * 24 * 60 * 60 * 1000);
}
