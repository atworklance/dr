import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { fetchProviders } from '../api/admin';
import { ApiError } from '../api/client';
import { ErrorState, Spinner, StatusBadge } from '../components/ui';
import type { AdminProvider, AdminUserRef, VerificationStatus } from '../types';
import { percent, refId, titleCase } from '../util/format';

type Filter = VerificationStatus | 'all';

const FILTERS: { key: Filter; label: string }[] = [
  { key: 'pending', label: 'Pending' },
  { key: 'approved', label: 'Approved' },
  { key: 'rejected', label: 'Rejected' },
  { key: 'all', label: 'All' },
];

function userOf(provider: AdminProvider): AdminUserRef | null {
  return typeof provider.user === 'object' ? provider.user : null;
}

export function ProvidersPage() {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<Filter>('pending');
  const [providers, setProviders] = useState<AdminProvider[]>([]);
  const [total, setTotal] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback((status: Filter) => {
    setLoading(true);
    setError(null);
    fetchProviders({ status })
      .then((page) => {
        setProviders(page.items);
        setTotal(page.total);
      })
      .catch((err) =>
        setError(err instanceof ApiError ? err.message : 'Could not load providers.'),
      )
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => load(filter), [filter, load]);

  return (
    <div className="page">
      <h1 className="page__title">Provider verification</h1>

      <div className="tabs">
        {FILTERS.map((tab) => (
          <button
            key={tab.key}
            type="button"
            className={`tab${filter === tab.key ? ' tab--active' : ''}`}
            onClick={() => setFilter(tab.key)}
          >
            {tab.label}
          </button>
        ))}
        <span className="tabs__count">{total} total</span>
      </div>

      {loading ? (
        <div className="screen-center">
          <Spinner />
        </div>
      ) : error ? (
        <ErrorState message={error} onRetry={() => load(filter)} />
      ) : providers.length === 0 ? (
        <p className="muted">No providers in this state.</p>
      ) : (
        <div className="table-wrap">
          <table className="table table--hover">
            <thead>
              <tr>
                <th>Provider</th>
                <th>Email</th>
                <th>Specialty</th>
                <th>Status</th>
                <th>Commission</th>
              </tr>
            </thead>
            <tbody>
              {providers.map((provider) => {
                const user = userOf(provider);
                const id = refId(provider);
                return (
                  <tr key={id} onClick={() => navigate(`/providers/${id}`)}>
                    <td>
                      <div className="cell-strong">{provider.displayName}</div>
                      <div className="cell-sub">
                        {user ? `${user.firstName} ${user.lastName}` : '—'}
                      </div>
                    </td>
                    <td>{user?.email ?? '—'}</td>
                    <td>{titleCase(provider.primarySpecialty)}</td>
                    <td>
                      <StatusBadge status={provider.verificationStatus} />
                    </td>
                    <td>
                      {provider.commissionRateOverride != null
                        ? percent(provider.commissionRateOverride)
                        : 'Platform default'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
