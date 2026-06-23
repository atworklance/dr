import type {
  AdminProvider,
  CommissionSettings,
  Paged,
  SystemMetrics,
  VerificationStatus,
} from '../types';
import { apiRequest } from './client';

export async function fetchMetrics(): Promise<SystemMetrics> {
  const result = await apiRequest<SystemMetrics>('/admin/metrics');
  return result.data;
}

export interface ProviderListParams {
  status?: VerificationStatus | 'all';
  q?: string;
  page?: number;
  limit?: number;
}

export async function fetchProviders(
  params: ProviderListParams = {},
): Promise<Paged<AdminProvider>> {
  const query = new URLSearchParams();
  if (params.status && params.status !== 'all') query.set('status', params.status);
  if (params.q) query.set('q', params.q);
  query.set('page', String(params.page ?? 1));
  query.set('limit', String(params.limit ?? 50));

  const result = await apiRequest<AdminProvider[]>(`/admin/providers?${query.toString()}`);
  return {
    items: result.data,
    total: result.meta?.total ?? result.data.length,
    page: result.meta?.page ?? 1,
    limit: result.meta?.limit ?? 50,
  };
}

export async function fetchProvider(id: string): Promise<AdminProvider> {
  const result = await apiRequest<AdminProvider>(`/admin/providers/${id}`);
  return result.data;
}

export async function setProviderVerification(
  id: string,
  status: 'approved' | 'rejected',
  note?: string,
): Promise<AdminProvider> {
  const result = await apiRequest<AdminProvider>(`/admin/providers/${id}/verification`, {
    method: 'PATCH',
    body: { status, ...(note ? { note } : {}) },
  });
  return result.data;
}

export async function setProviderCommission(
  id: string,
  rate: number | null,
): Promise<AdminProvider> {
  const result = await apiRequest<AdminProvider>(`/admin/providers/${id}/commission`, {
    method: 'PATCH',
    body: { rate },
  });
  return result.data;
}

export async function fetchCommissionSettings(): Promise<CommissionSettings> {
  const result = await apiRequest<CommissionSettings>('/admin/settings/commission');
  return result.data;
}

export async function updatePlatformCommission(rate: number): Promise<CommissionSettings> {
  const result = await apiRequest<CommissionSettings>('/admin/settings/commission', {
    method: 'PATCH',
    body: { rate },
  });
  return result.data;
}
