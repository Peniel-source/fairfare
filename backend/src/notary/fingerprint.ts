//this script builds the daily fingerprint of the corridor prices
//same prices in, same fingerprint out, every time
import { createHash } from 'node:crypto';

export type PriceRow = {
  corridorId: string;
  median: number;
  low: number;
  high: number;
  sampleSize: number;
};

//write one route as a fixed line of text
function rowText(row: PriceRow): string {
  return [
    row.corridorId,
    Math.round(row.median),
    Math.round(row.low),
    Math.round(row.high),
    Math.round(row.sampleSize),
  ].join('|');
}

export function canonicalText(date: string, rows: PriceRow[]): string {
  //sort a copy by id
  const sorted = [...rows].sort((a, b) =>
    a.corridorId < b.corridorId ? -1 : a.corridorId > b.corridorId ? 1 : 0,
  );
  const lines = ['fairfare|' + date];
  for (const row of sorted) {
    lines.push(rowText(row));
  }
  return lines.join('\n');
}

//the fingerprint, 64 letters and digits
export function fingerprint(date: string, rows: PriceRow[]): string {
  return createHash('sha256').update(canonicalText(date, rows)).digest('hex');
}