/**
 * Zod validators for payment and wallet/withdrawal endpoints.
 */

import { z } from 'zod';
import { currency } from './common.validators';

export const capturePaymentSchema = z
  .object({
    paymentReference: z
      .string()
      .trim()
      .min(3, 'A gateway payment reference is required.')
      .max(160),
  })
  .strict();
export type CapturePaymentRequest = z.infer<typeof capturePaymentSchema>;

export const requestWithdrawalSchema = z
  .object({
    amount: z
      .number()
      .int('Amount must be an integer number of minor units (cents).')
      .positive('Amount must be positive.'),
    payoutMethod: z.string().trim().min(2).max(80),
    currency: currency.optional(),
  })
  .strict();
export type RequestWithdrawalRequest = z.infer<typeof requestWithdrawalSchema>;

export const processWithdrawalSchema = z
  .object({
    action: z.enum(['approve', 'mark_paid', 'reject']),
    payoutReference: z.string().trim().max(160).optional(),
    rejectionReason: z.string().trim().max(500).optional(),
  })
  .strict()
  .superRefine((data, ctx) => {
    if (data.action === 'reject' && !data.rejectionReason) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['rejectionReason'],
        message: 'A rejectionReason is required when rejecting a withdrawal.',
      });
    }
  });
export type ProcessWithdrawalRequest = z.infer<typeof processWithdrawalSchema>;

export const withdrawalParamsSchema = z
  .object({
    walletId: z.string().regex(/^[0-9a-fA-F]{24}$/),
    requestId: z.string().regex(/^[0-9a-fA-F]{24}$/),
  })
  .strict();
