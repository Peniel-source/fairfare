export const REPORT_VERIFIED = 'report.verified';
export const REPORT_REJECTED = 'report.rejected';

export type ReportVerifiedEvent = {
  reportId: string;
  passengerId: string;
  corridorId: string;
  price: number;
  isFirstOnCorridor: boolean;
  verifiedAt: Date;
};

export type ReportRejectedEvent = {
  reportId: string;
  passengerId: string;
  reason: string;
};