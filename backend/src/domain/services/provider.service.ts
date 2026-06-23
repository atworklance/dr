/**
 * Specialist (provider) directory domain service.
 *
 * Powers the client search experience: returns only APPROVED providers,
 * supports free-text, specialty, consultation-mode, rating, and proximity
 * filters, and paginates results sorted by rating. Proximity uses
 * `$geoWithin/$centerSphere` (rather than `$near`) so the same filter is valid
 * for both `find` and `countDocuments`, against the provider's 2dsphere index.
 */

import type { FilterQuery } from 'mongoose';
import { Provider, type IProvider } from '../../data/models';
import { VerificationStatus } from '../../shared/enums';
import { ApiError } from '../../shared/apiError';
import type { SearchProvidersQuery } from '../../api/validators/provider.validators';

/** Mean Earth radius in km, for converting a km radius to radians. */
const EARTH_RADIUS_KM = 6378.1;
/** Default proximity radius when a centre is given without an explicit radius. */
const DEFAULT_RADIUS_KM = 50;

function escapeRegExp(input: string): string {
  return input.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export interface ProviderSearchResult {
  items: Array<Record<string, unknown>>;
  total: number;
  page: number;
  limit: number;
}

export async function searchProviders(
  query: SearchProvidersQuery,
): Promise<ProviderSearchResult> {
  const and: Array<Record<string, unknown>> = [];

  if (query.q) {
    const rx = new RegExp(escapeRegExp(query.q), 'i');
    and.push({
      $or: [
        { displayName: rx },
        { headline: rx },
        { primarySpecialty: rx },
        { specialties: rx },
      ],
    });
  }
  if (query.specialty) {
    and.push({ specialties: query.specialty });
  }
  if (query.mode) {
    and.push({ consultationModes: query.mode });
  }
  if (query.minRating !== undefined) {
    and.push({ 'rating.average': { $gte: query.minRating } });
  }
  if (query.lat !== undefined && query.lng !== undefined) {
    const radiusKm = query.radiusKm ?? DEFAULT_RADIUS_KM;
    and.push({
      clinicLocation: {
        $geoWithin: {
          $centerSphere: [[query.lng, query.lat], radiusKm / EARTH_RADIUS_KM],
        },
      },
    });
  }

  const filter = {
    verificationStatus: VerificationStatus.APPROVED,
    ...(and.length > 0 ? { $and: and } : {}),
  } as FilterQuery<IProvider>;

  const { page, limit } = query;
  const skip = (page - 1) * limit;

  const [items, total] = await Promise.all([
    Provider.find(filter)
      .sort({ 'rating.average': -1, 'rating.count': -1, createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Provider.countDocuments(filter),
  ]);

  return { items: items as Array<Record<string, unknown>>, total, page, limit };
}

export async function getProviderById(id: string): Promise<Record<string, unknown>> {
  const provider = await Provider.findById(id).lean();
  if (!provider || provider.verificationStatus !== VerificationStatus.APPROVED) {
    throw ApiError.notFound('Specialist not found.');
  }
  return provider as Record<string, unknown>;
}
