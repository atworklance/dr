import type { AuthSession, AuthUser } from '../types';
import { apiRequest } from './client';

export async function login(email: string, password: string): Promise<AuthSession> {
  const result = await apiRequest<AuthSession>('/auth/login', {
    method: 'POST',
    body: { email, password },
    auth: false,
  });
  return result.data;
}

export async function me(): Promise<AuthUser> {
  const result = await apiRequest<AuthUser>('/auth/me');
  return result.data;
}
