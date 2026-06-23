const SYMBOLS: Record<string, string> = {
  USD: '$',
  EUR: '€',
  GBP: '£',
  NGN: '₦',
  EGP: 'E£',
  AED: 'AED ',
  SAR: 'SAR ',
};

/** Formats integer minor units (cents) as a currency string. */
export function money(minorUnits: number, currency = 'USD'): string {
  const symbol = SYMBOLS[currency] ?? `${currency} `;
  return `${symbol}${(minorUnits / 100).toFixed(2)}`;
}

/** Formats a 0–1 fraction as a percentage. */
export function percent(fraction: number): string {
  return `${(fraction * 100).toFixed(1)}%`;
}

/** Resolves a Mongo ref id from either `id` or `_id`. */
export function refId(value: { id?: string; _id?: string }): string {
  return value.id ?? value._id ?? '';
}

/** Snake/space-separated string to Title Case. */
export function titleCase(value: string): string {
  return value
    .split(/[\s_]+/)
    .map((w) => (w ? w[0].toUpperCase() + w.slice(1) : w))
    .join(' ');
}

export function formatDate(value?: string): string {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}
