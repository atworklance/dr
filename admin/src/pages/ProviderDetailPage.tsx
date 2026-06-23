import { useCallback, useEffect, useState, type ReactNode } from 'react';
import { Link, useParams } from 'react-router-dom';

import {
  fetchProvider,
  setProviderCommission,
  setProviderVerification,
} from '../api/admin';
import { ApiError } from '../api/client';
import { ErrorState, Panel, Spinner, StatusBadge } from '../components/ui';
import type { AdminProvider, AdminUserRef } from '../types';
import { formatDate, money, percent, titleCase } from '../util/format';

export function ProviderDetailPage() {
  const { id = '' } = useParams();
  const [provider, setProvider] = useState<AdminProvider | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    fetchProvider(id)
      .then(setProvider)
      .catch((err) =>
        setError(err instanceof ApiError ? err.message : 'Could not load provider.'),
      )
      .finally(() => setLoading(false));
  }, [id]);

  useEffect(load, [load]);

  if (loading) {
    return (
      <div className="screen-center">
        <Spinner />
      </div>
    );
  }
  if (!provider) {
    return <ErrorState message={error ?? 'Provider not found.'} onRetry={load} />;
  }

  const user: AdminUserRef | null =
    typeof provider.user === 'object' ? provider.user : null;

  return (
    <div className="page">
      <Link to="/providers" className="back-link">
        ← Back to verification
      </Link>

      <div className="detail-head">
        <div>
          <h1 className="page__title">{provider.displayName}</h1>
          <p className="muted">{titleCase(provider.primarySpecialty)}</p>
        </div>
        <StatusBadge status={provider.verificationStatus} />
      </div>

      <div className="panel-grid">
        <Panel title="Account">
          <dl className="kv">
            <Row label="Name" value={user ? `${user.firstName} ${user.lastName}` : '—'} />
            <Row label="Email" value={user?.email ?? '—'} />
            <Row label="Phone" value={user?.phone ?? '—'} />
            <Row label="Account status" value={user ? <StatusBadge status={user.status} /> : '—'} />
            <Row label="Email verified" value={user?.isEmailVerified ? 'Yes' : 'No'} />
            <Row label="Joined" value={formatDate(user?.createdAt ?? provider.createdAt)} />
          </dl>
        </Panel>

        <Panel title="Professional profile">
          <dl className="kv">
            <Row label="Specialties" value={provider.specialties.map(titleCase).join(', ')} />
            <Row label="Experience" value={`${provider.yearsOfExperience ?? 0} years`} />
            <Row
              label="Online fee"
              value={money(provider.pricing.onlineFee, provider.pricing.currency)}
            />
            <Row
              label="Clinic fee"
              value={money(provider.pricing.clinicFee, provider.pricing.currency)}
            />
            <Row
              label="Rating"
              value={`${provider.rating.average.toFixed(1)} (${provider.rating.count})`}
            />
          </dl>
        </Panel>
      </div>

      <DocumentsPanel provider={provider} />

      <VerificationPanel provider={provider} onChanged={load} />

      <CommissionPanel provider={provider} onChanged={load} />
    </div>
  );
}

function Row({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="kv__row">
      <dt>{label}</dt>
      <dd>{value}</dd>
    </div>
  );
}

function DocumentsPanel({ provider }: { provider: AdminProvider }) {
  return (
    <Panel title={`Documents (${provider.verificationDocuments.length})`}>
      {provider.verificationDocuments.length === 0 ? (
        <p className="muted">No documents submitted.</p>
      ) : (
        <ul className="doc-list">
          {provider.verificationDocuments.map((doc, index) => (
            <li key={`${doc.docType}-${index}`} className="doc-list__item">
              <div>
                <div className="cell-strong">{titleCase(doc.docType)}</div>
                <div className="cell-sub">Uploaded {formatDate(doc.uploadedAt)}</div>
              </div>
              <div className="doc-list__actions">
                {doc.reviewedAt ? (
                  <StatusBadge status={doc.isApproved ? 'approved' : 'rejected'} />
                ) : (
                  <StatusBadge status="pending" />
                )}
                <a className="btn btn--ghost" href={doc.fileUrl} target="_blank" rel="noreferrer">
                  View
                </a>
              </div>
            </li>
          ))}
        </ul>
      )}
    </Panel>
  );
}

function VerificationPanel({
  provider,
  onChanged,
}: {
  provider: AdminProvider;
  onChanged: () => void;
}) {
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState<'approved' | 'rejected' | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function act(status: 'approved' | 'rejected') {
    setBusy(status);
    setError(null);
    try {
      await setProviderVerification(provider.id ?? provider._id ?? '', status, note.trim() || undefined);
      onChanged();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Action failed.');
    } finally {
      setBusy(null);
    }
  }

  return (
    <Panel title="Verification review">
      <textarea
        className="textarea"
        placeholder="Optional review note…"
        value={note}
        onChange={(e) => setNote(e.target.value)}
        rows={2}
      />
      {error ? <div className="form-error">{error}</div> : null}
      <div className="action-row">
        <button
          type="button"
          className="btn btn--danger"
          disabled={busy !== null || provider.verificationStatus === 'rejected'}
          onClick={() => act('rejected')}
        >
          {busy === 'rejected' ? 'Rejecting…' : 'Reject'}
        </button>
        <button
          type="button"
          className="btn btn--primary"
          disabled={busy !== null || provider.verificationStatus === 'approved'}
          onClick={() => act('approved')}
        >
          {busy === 'approved' ? 'Approving…' : 'Approve provider'}
        </button>
      </div>
    </Panel>
  );
}

function CommissionPanel({
  provider,
  onChanged,
}: {
  provider: AdminProvider;
  onChanged: () => void;
}) {
  const initial =
    provider.commissionRateOverride != null
      ? (provider.commissionRateOverride * 100).toString()
      : '';
  const [value, setValue] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function save(rate: number | null) {
    setBusy(true);
    setError(null);
    try {
      await setProviderCommission(provider.id ?? provider._id ?? '', rate);
      onChanged();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not update commission.');
    } finally {
      setBusy(false);
    }
  }

  function handleSave() {
    const parsed = Number.parseFloat(value);
    if (Number.isNaN(parsed) || parsed < 0 || parsed > 100) {
      setError('Enter a percentage between 0 and 100.');
      return;
    }
    void save(parsed / 100);
  }

  return (
    <Panel title="Commission override">
      <p className="muted">
        {provider.commissionRateOverride != null
          ? `This provider uses a ${percent(provider.commissionRateOverride)} override.`
          : 'This provider uses the platform default commission.'}
      </p>
      {error ? <div className="form-error">{error}</div> : null}
      <div className="action-row action-row--start">
        <div className="input-suffix">
          <input
            type="number"
            min={0}
            max={100}
            step="0.5"
            value={value}
            onChange={(e) => setValue(e.target.value)}
            placeholder="e.g. 12.5"
          />
          <span>%</span>
        </div>
        <button type="button" className="btn btn--primary" disabled={busy} onClick={handleSave}>
          {busy ? 'Saving…' : 'Set override'}
        </button>
        <button
          type="button"
          className="btn btn--ghost"
          disabled={busy || provider.commissionRateOverride == null}
          onClick={() => {
            setValue('');
            void save(null);
          }}
        >
          Use platform default
        </button>
      </div>
    </Panel>
  );
}
