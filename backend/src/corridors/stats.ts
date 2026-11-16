//old reports have to drop out so tht we're not using the same reports always

export const windowDays = 14;
const newBelow = 5;
//a corridor is well covered when there's 20 plus reports
const wellCoveredFrom = 20;

//get confidence level with numbver of reports
export function getConfidence(count: number) {
  if (count < newBelow) return 'new';
  if (count < wellCoveredFrom) return 'limited';
  return 'wellCovered';
}

//generate the stats with list of prices for the corridor
export function computeStats(prices: number[]) {
  const cleaned = prices.filter((p) => Number.isFinite(p) && p > 0);
  cleaned.sort((a, b) => a - b);

  //if no prices, return null
  const count = cleaned.length;
  if (count === 0) return null;

  //median price
  const middle = Math.floor(count / 2);
  let median: number;
  if (count % 2 === 1) {
    median = cleaned[middle];
  } else {
    median = Math.round((cleaned[middle - 1] + cleaned[middle]) / 2);
  }

  //first price is lowest and last is the highest
  return {
    median,
    low: cleaned[0],
    high: cleaned[count - 1],
    sampleSize: count,
    confidence: getConfidence(count),
  };
}