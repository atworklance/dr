import { getToken } from './token';

const BASE_URL =
  (import.meta.env.VITE_API_BASE_URL as string | undefined) ??
  'http://localhost:4000/api/v1';

export class ApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly details?: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

interface Envelope<T> {
  success: boolean;
  data?: T;
  meta?: { total: number; page: number; limit: number };
  error?: { message: string; details?: unknown };
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';
  body?: unknown;
  auth?: boolean;
}

export interface ApiResult<T> {
  data: T;
  meta?: { total: number; page: number; limit: number };
}

/** Typed fetch over the Dr.Plus API, unwrapping the `{ success, data }` envelope. */
export async function apiRequest<T>(
  path: string,
  options: RequestOptions = {},
): Promise<ApiResult<T>> {
  const { method = 'GET', body, auth = true } = options;

  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (auth) {
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  let response: Response;
  try {
    response = await fetch(`${BASE_URL}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError(0, 'Could not reach the server. Check your connection.');
  }

  let json: Envelope<T>;
  try {
    json = (await response.json()) as Envelope<T>;
  } catch {
    throw new ApiError(response.status, 'The server returned an invalid response.');
  }

  if (!response.ok || json.success === false) {
    throw new ApiError(
      response.status,
      json.error?.message ?? 'The request could not be completed.',
      json.error?.details,
    );
  }

  return { data: json.data as T, meta: json.meta };
}
