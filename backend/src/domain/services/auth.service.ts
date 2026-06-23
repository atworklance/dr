/**
 * Authentication & registration domain service.
 *
 * Encapsulates the multi-document creation flows (User + Wallet, and for
 * providers also the Provider profile) inside MongoDB transactions so a partial
 * failure can never leave an orphaned user without a wallet/profile. Requires a
 * replica set / Atlas cluster (transactions are unsupported on standalone mongo).
 */

import mongoose from 'mongoose';
import { User, Provider, Wallet, type IUser } from '../../data/models';
import { AccountStatus, UserRole, VerificationStatus } from '../../shared/enums';
import { hashPassword, verifyPassword } from '../../shared/password';
import { signAccessToken } from '../../shared/jwt';
import { ApiError } from '../../shared/apiError';
import type { RegisterClientInput, RegisterProviderInput } from '../../api/validators/auth.validators';

export interface AuthResult {
  token: string;
  user: Record<string, unknown>;
}

function publicUser(user: IUser): Record<string, unknown> {
  const obj = user.toJSON() as Record<string, unknown>;
  delete obj.passwordHash;
  return obj;
}

async function assertEmailFree(email: string, session: mongoose.ClientSession): Promise<void> {
  const existing = await User.findOne({ email }).session(session).lean();
  if (existing) {
    throw ApiError.conflict('An account with this email already exists.');
  }
}

export async function registerClient(input: RegisterClientInput): Promise<AuthResult> {
  const session = await mongoose.startSession();
  try {
    let created: IUser | null = null;
    await session.withTransaction(async () => {
      await assertEmailFree(input.email, session);
      const passwordHash = await hashPassword(input.password);

      const [user] = await User.create(
        [
          {
            firstName: input.firstName,
            lastName: input.lastName,
            email: input.email,
            phone: input.phone,
            passwordHash,
            role: UserRole.CLIENT,
            status: AccountStatus.ACTIVE,
            gender: input.gender,
            dateOfBirth: input.dateOfBirth,
            location: input.location,
            preferredLocale: input.preferredLocale,
          },
        ],
        { session },
      );

      const [wallet] = await Wallet.create(
        [{ owner: user._id, ownerModel: 'User', currency: 'USD' }],
        { session },
      );

      user.wallet = wallet._id;
      await user.save({ session });
      created = user;
    });

    const user = created as unknown as IUser;
    return {
      token: signAccessToken({ sub: user._id.toString(), role: user.role }),
      user: publicUser(user),
    };
  } finally {
    await session.endSession();
  }
}

export async function registerProvider(input: RegisterProviderInput): Promise<AuthResult> {
  const session = await mongoose.startSession();
  try {
    let created: IUser | null = null;
    await session.withTransaction(async () => {
      await assertEmailFree(input.email, session);
      const passwordHash = await hashPassword(input.password);

      // Providers start PENDING until an admin approves their documentation.
      const [user] = await User.create(
        [
          {
            firstName: input.firstName,
            lastName: input.lastName,
            email: input.email,
            phone: input.phone,
            passwordHash,
            role: UserRole.PROVIDER,
            status: AccountStatus.PENDING,
            gender: input.gender,
            dateOfBirth: input.dateOfBirth,
            location: input.location,
            preferredLocale: input.preferredLocale,
          },
        ],
        { session },
      );

      const [profile] = await Provider.create(
        [
          {
            user: user._id,
            displayName: input.displayName,
            headline: input.headline,
            bio: input.bio,
            primarySpecialty: input.primarySpecialty,
            specialties: input.specialties,
            yearsOfExperience: input.yearsOfExperience ?? 0,
            languages: input.languages ?? ['en'],
            consultationModes: input.consultationModes,
            pricing: input.pricing,
            clinicLocation: input.clinicLocation,
            clinicAddress: input.clinicAddress,
            verificationStatus: VerificationStatus.PENDING,
          },
        ],
        { session },
      );

      const [wallet] = await Wallet.create(
        [{ owner: user._id, ownerModel: 'User', currency: input.pricing.currency }],
        { session },
      );

      user.providerProfile = profile._id;
      user.wallet = wallet._id;
      await user.save({ session });
      created = user;
    });

    const user = created as unknown as IUser;
    return {
      token: signAccessToken({ sub: user._id.toString(), role: user.role }),
      user: publicUser(user),
    };
  } finally {
    await session.endSession();
  }
}

export async function login(email: string, password: string): Promise<AuthResult> {
  // passwordHash is select:false — explicitly request it for verification.
  const user = await User.findOne({ email }).select('+passwordHash');
  if (!user) {
    throw ApiError.unauthorized('Invalid email or password.');
  }
  const ok = await verifyPassword(password, user.passwordHash);
  if (!ok) {
    throw ApiError.unauthorized('Invalid email or password.');
  }
  if (user.status === AccountStatus.SUSPENDED || user.status === AccountStatus.DEACTIVATED) {
    throw ApiError.forbidden(`Account is ${user.status}.`);
  }

  user.lastLoginAt = new Date();
  await user.save();

  return {
    token: signAccessToken({ sub: user._id.toString(), role: user.role }),
    user: publicUser(user),
  };
}
