import type { ReactNode } from 'react';

import type { VerificationStatus } from '../types';

export function Spinner() {
  return <div className="spinner" aria-label="Loading" />;
}

export function StatCard({
  label,
  value,
  sub,
  accent,
}: {
  label: string;
  value: string;
  sub?: string;
  accent?: boolean;
}) {
  return (
    <div className={`stat-card${accent ? ' stat-card--accent' : ''}`}>
      <span className="stat-card__label">{label}</span>
      <span className="stat-card__value">{value}</span>
      {sub ? <span className="stat-card__sub">{sub}</span> : null}
    </div>
  );
}

const STATUS_CLASS: Record<string, string> = {
  approved: 'badge--green',
  pending: 'badge--amber',
  rejected: 'badge--red',
  unsubmitted: 'badge--grey',
  active: 'badge--green',
  suspended: 'badge--red',
  deactivated: 'badge--grey',
  settled: 'badge--green',
  paid: 'badge--green',
  requested: 'badge--amber',
  processing: 'badge--blue',
  reversed: 'badge--grey',
  failed: 'badge--red',
};

export function StatusBadge({ status }: { status: VerificationStatus | string }) {
  const cls = STATUS_CLASS[status] ?? 'badge--grey';
  return <span className={`badge ${cls}`}>{status.replace(/_/g, ' ')}</span>;
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="empty-state">
      <p>{message}</p>
      {onRetry ? (
        <button type="button" className="btn btn--ghost" onClick={onRetry}>
          Retry
        </button>
      ) : null}
    </div>
  );
}

export function Panel({ title, action, children }: { title: string; action?: ReactNode; children: ReactNode }) {
  return (
    <section className="panel">
      <header className="panel__head">
        <h2>{title}</h2>
        {action}
      </header>
      <div className="panel__body">{children}</div>
    </section>
  );
}

export function DistributionList({
  data,
  render,
}: {
  data: Record<string, number>;
  render?: (key: string, value: number) => ReactNode;
}) {
  const entries = Object.entries(data);
  if (entries.length === 0) {
    return <p className="muted">No data yet.</p>;
  }
  return (
    <ul className="dist-list">
      {entries.map(([key, value]) => (
        <li key={key}>
          <span className="dist-list__key">{key.replace(/_/g, ' ')}</span>
          <span className="dist-list__value">{render ? render(key, value) : value}</span>
        </li>
      ))}
    </ul>
  );
}
