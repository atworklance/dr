import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

import { login as apiLogin, me as apiMe } from '../api/auth';
import { getToken, setToken } from '../api/token';
import type { AuthUser } from '../types';

interface AuthContextValue {
  token: string | null;
  user: AuthUser | null;
  initializing: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setTokenState] = useState<string | null>(() => getToken());
  const [user, setUser] = useState<AuthUser | null>(null);
  const [initializing, setInitializing] = useState<boolean>(() => getToken() !== null);

  // On boot with a persisted token, resolve the profile (and validate the token).
  useEffect(() => {
    let cancelled = false;
    if (!token) {
      setInitializing(false);
      return;
    }
    apiMe()
      .then((profile) => {
        if (cancelled) return;
        if (profile.role === 'admin') {
          setUser(profile);
        } else {
          setToken(null);
          setTokenState(null);
        }
      })
      .catch(() => {
        if (cancelled) return;
        setToken(null);
        setTokenState(null);
        setUser(null);
      })
      .finally(() => {
        if (!cancelled) setInitializing(false);
      });
    return () => {
      cancelled = true;
    };
    // Run once on mount for the persisted token.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function signIn(email: string, password: string): Promise<void> {
    const session = await apiLogin(email, password);
    if (session.user.role !== 'admin') {
      throw new Error('Admin access is required to use this dashboard.');
    }
    setToken(session.token);
    setTokenState(session.token);
    setUser(session.user);
  }

  function signOut(): void {
    setToken(null);
    setTokenState(null);
    setUser(null);
  }

  const value = useMemo<AuthContextValue>(
    () => ({ token, user, initializing, signIn, signOut }),
    [token, user, initializing],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider.');
  return ctx;
}
