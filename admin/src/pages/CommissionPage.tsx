import { useCallback, useEffect, useState } from 'react';

import { fetchCommissionSettings, updatePlatformCommission } from '../api/admin';
import { ApiError } from '../api/client';
import { ErrorState, Panel, Spinner } from '../components/ui';
import { percent } from '../util/format';

export function CommissionPage() {
  const [rate, setRate] = useState<number | null>(null);
  const [value, setValue] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    fetchCommissionSettings()
      .then((settings) => {
        setRate(settings.defaultCommissionRate);
        setValue((settings.defaultCommissionRate * 100).toString());
      })
      .catch((err) =>
        setError(err instanceof ApiError ? err.message : 'Could not load settings.'),
      )
      .finally(() => setLoading(false));
  }, []);

  useEffect(load, [load]);

  async function handleSave() {
    const parsed = Number.parseFloat(value);
    if (Number.isNaN(parsed) || parsed < 0 || parsed > 100) {
      setError('Enter a percentage between 0 and 100.');
      return;
    }
    setBusy(true);
    setError(null);
    setSavedMessage(null);
    try {
      const settings = await updatePlatformCommission(parsed / 100);
      setRate(settings.defaultCommissionRate);
      setValue((settings.defaultCommissionRate * 100).toString());
      setSavedMessage('Platform commission updated.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not update commission.');
    } finally {
      setBusy(false);
    }
  }

  if (loading) {
    return (
      <div className="screen-center">
        <Spinner />
      </div>
    );
  }
  if (rate === null) {
    return <ErrorState message={error ?? 'No settings available.'} onRetry={load} />;
  }

  return (
    <div className="page">
      <h1 className="page__title">Commission controls</h1>

      <Panel title="Platform-wide commission">
        <p className="muted">
          Applied to every appointment unless a provider has a per-provider override.
          Current rate: <strong>{percent(rate)}</strong>.
        </p>
        {error ? <div className="form-error">{error}</div> : null}
        {savedMessage ? <div className="form-success">{savedMessage}</div> : null}
        <div className="action-row action-row--start">
          <div className="input-suffix">
            <input
              type="number"
              min={0}
              max={100}
              step="0.5"
              value={value}
              onChange={(e) => setValue(e.target.value)}
            />
            <span>%</span>
          </div>
          <button type="button" className="btn btn--primary" disabled={busy} onClick={handleSave}>
            {busy ? 'Saving…' : 'Update rate'}
          </button>
        </div>
      </Panel>

      <Panel title="Per-provider overrides">
        <p className="muted">
          Individual splits are managed on each provider's profile under{' '}
          <strong>Verification → provider → Commission override</strong>. An override
          takes precedence over this platform-wide rate.
        </p>
      </Panel>
    </div>
  );
}
