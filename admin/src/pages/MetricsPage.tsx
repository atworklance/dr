import { useCallback, useEffect, useState } from 'react';

import { fetchMetrics } from '../api/admin';
import { ApiError } from '../api/client';
import {
  DistributionList,
  ErrorState,
  Panel,
  Spinner,
  StatCard,
} from '../components/ui';
import type { SystemMetrics } from '../types';
import { money, titleCase } from '../util/format';

export function MetricsPage() {
  const [metrics, setMetrics] = useState<SystemMetrics | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    fetchMetrics()
      .then(setMetrics)
      .catch((err) =>
        setError(err instanceof ApiError ? err.message : 'Could not load metrics.'),
      )
      .finally(() => setLoading(false));
  }, []);

  useEffect(load, [load]);

  if (loading) {
    return (
      <div className="screen-center">
        <Spinner />
      </div>
    );
  }
  if (!metrics) {
    return <ErrorState message={error ?? 'No metrics available.'} onRetry={load} />;
  }

  const { payments, platformBalances } = metrics;

  return (
    <div className="page">
      <h1 className="page__title">System overview</h1>

      <div className="stat-grid">
        <StatCard
          label="Gross volume"
          value={money(payments.grossVolume)}
          sub="Escrowed + released"
          accent
        />
        <StatCard
          label="Commission earned"
          value={money(payments.commissionEarned)}
          sub={`${money(payments.releasedRevenue)} released`}
        />
        <StatCard label="Held in escrow" value={money(platformBalances.escrow)} />
        <StatCard label="Provider available" value={money(platformBalances.available)} />
      </div>

      <div className="stat-grid stat-grid--secondary">
        <StatCard label="Pending balance" value={money(platformBalances.pending)} />
        <StatCard
          label="Lifetime earnings"
          value={money(platformBalances.lifetimeEarnings)}
        />
        <StatCard
          label="Lifetime withdrawn"
          value={money(platformBalances.lifetimeWithdrawn)}
        />
      </div>

      <div className="panel-grid">
        <Panel title="Providers by verification">
          <DistributionList data={metrics.providersByVerification} />
        </Panel>
        <Panel title="Users by role">
          <DistributionList data={metrics.users} />
        </Panel>
        <Panel title="Appointments by status">
          <DistributionList data={metrics.appointmentsByStatus} />
        </Panel>
        <Panel title="Settlement distribution">
          {Object.keys(metrics.withdrawalsByStatus).length === 0 ? (
            <p className="muted">No withdrawals yet.</p>
          ) : (
            <ul className="dist-list">
              {Object.entries(metrics.withdrawalsByStatus).map(([status, info]) => (
                <li key={status}>
                  <span className="dist-list__key">{titleCase(status)}</span>
                  <span className="dist-list__value">
                    {info.count} · {money(info.amount)}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>

      <Panel title="Payments by status">
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Status</th>
                <th className="num">Count</th>
                <th className="num">Gross</th>
                <th className="num">Commission</th>
              </tr>
            </thead>
            <tbody>
              {Object.entries(payments.byStatus).map(([status, info]) => (
                <tr key={status}>
                  <td>{titleCase(status)}</td>
                  <td className="num">{info.count}</td>
                  <td className="num">{money(info.gross)}</td>
                  <td className="num">{money(info.commission)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Panel>
    </div>
  );
}
