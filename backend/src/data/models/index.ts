/**
 * Barrel export for the Dr.Plus data-layer models.
 *
 * Importing from this single entry point guarantees every Mongoose model is
 * registered before the application issues any query, avoiding
 * `MissingSchemaError` on populate() across circular references.
 */

export { User, type IUser, type IUserModel, type IGeoPoint } from './user.model';
export {
  Provider,
  type IProvider,
  type IProviderModel,
  type IAvailabilityWindow,
  type IAvailabilityException,
  type IVerificationDocument,
} from './provider.model';
export {
  Appointment,
  type IAppointment,
  type IAppointmentModel,
} from './appointment.model';
export {
  Wallet,
  type IWallet,
  type IWalletModel,
  type IWalletTransaction,
  type IWithdrawalRequest,
} from './wallet.model';
export { Message, type IMessage, type IMessageModel } from './message.model';
