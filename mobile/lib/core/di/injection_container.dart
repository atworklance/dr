import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/auth/domain/usecases/logout_user.dart';
import '../../features/auth/domain/usecases/register_client.dart';
import '../../features/auth/domain/usecases/register_provider.dart';
import '../../features/auth/domain/usecases/restore_session.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubit/role_selection_cubit.dart';
import '../../features/booking/data/datasources/booking_remote_data_source.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/domain/usecases/book_appointment.dart';
import '../../features/booking/domain/usecases/get_specialist_details.dart';
import '../../features/booking/domain/usecases/pay_for_appointment.dart';
import '../../features/booking/domain/usecases/search_specialists.dart';
import '../../features/availability/data/datasources/availability_remote_data_source.dart';
import '../../features/availability/data/repositories/availability_repository_impl.dart';
import '../../features/availability/domain/repositories/availability_repository.dart';
import '../../features/availability/domain/usecases/get_availability.dart';
import '../../features/availability/domain/usecases/set_holiday_mode.dart';
import '../../features/availability/domain/usecases/update_weekly_availability.dart';
import '../../features/availability/domain/usecases/upsert_availability_exception.dart';
import '../../features/availability/presentation/cubit/availability_cubit.dart';
import '../../features/booking/presentation/bloc/booking/booking_bloc.dart';
import '../../features/booking/presentation/bloc/search/specialist_search_bloc.dart';
import '../../features/calls/data/repositories/call_signaling_repository_impl.dart';
import '../../features/calls/domain/repositories/call_signaling_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/video/data/datasources/video_remote_data_source.dart';
import '../../features/video/data/repositories/video_repository_impl.dart';
import '../../features/video/data/services/agora_video_service.dart';
import '../../features/video/domain/repositories/video_repository.dart';
import '../../features/video/domain/usecases/end_video_session.dart';
import '../../features/video/domain/usecases/get_video_token.dart';
import '../../features/video/domain/usecases/start_video_session.dart';
import '../../features/video/presentation/cubit/video_call_cubit.dart';
import '../../features/wallet/data/datasources/wallet_remote_data_source.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/get_wallet_summary.dart';
import '../../features/wallet/domain/usecases/request_withdrawal.dart';
import '../../features/wallet/presentation/cubit/wallet_cubit.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/auth_interceptor.dart';
import '../network/network_info.dart';
import '../services/media_permission_service.dart';
import '../storage/auth_token_store.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Registers every dependency. Call once during app startup before `runApp`.
Future<void> initDependencies() async {
  _registerCore();
  _registerAuthFeature();
  _registerBookingFeature();
  _registerVideoFeature();
  _registerChatFeature();
  _registerAvailabilityFeature();
  _registerWalletFeature();
  _registerCallsFeature();
}

void _registerCore() {
  // External singletons
  sl
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    )
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    ..registerLazySingleton<AuthTokenStore>(() => AuthTokenStore(sl()))
    ..registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Dio configured with the base URL and the auth interceptor.
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.add(AuthInterceptor(sl<AuthTokenStore>()));
    return dio;
  });

  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));
}

void _registerAuthFeature() {
  // Data sources
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(tokenStore: sl(), storage: sl()),
    );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), local: sl(), networkInfo: sl()),
  );

  // Use cases
  sl
    ..registerLazySingleton(() => RestoreSession(sl()))
    ..registerLazySingleton(() => LoginUser(sl()))
    ..registerLazySingleton(() => RegisterClient(sl()))
    ..registerLazySingleton(() => RegisterProvider(sl()))
    ..registerLazySingleton(() => LogoutUser(sl()));

  // Presentation
  sl
    ..registerFactory(
      () => AuthBloc(
        restoreSession: sl(),
        loginUser: sl(),
        registerClient: sl(),
        registerProvider: sl(),
        logoutUser: sl(),
      ),
    )
    ..registerFactory(RoleSelectionCubit.new);
}

void _registerBookingFeature() {
  // Data source
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remote: sl(), networkInfo: sl()),
  );

  // Use cases
  sl
    ..registerLazySingleton(() => SearchSpecialists(sl()))
    ..registerLazySingleton(() => GetSpecialistDetails(sl()))
    ..registerLazySingleton(() => BookAppointment(sl()))
    ..registerLazySingleton(() => PayForAppointment(sl()));

  // Presentation
  sl
    ..registerFactory(() => SpecialistSearchBloc(sl()))
    ..registerFactory(
      () => BookingBloc(bookAppointment: sl(), payForAppointment: sl()),
    );
}

void _registerVideoFeature() {
  // Infrastructure
  sl
    ..registerLazySingleton<MediaPermissionService>(
      () => const MediaPermissionServiceImpl(),
    )
    ..registerLazySingleton<AgoraVideoService>(AgoraVideoServiceImpl.new);

  // Data source + repository
  sl
    ..registerLazySingleton<VideoRemoteDataSource>(
      () => VideoRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<VideoRepository>(
      () => VideoRepositoryImpl(remote: sl(), networkInfo: sl()),
    );

  // Use cases
  sl
    ..registerLazySingleton(() => GetVideoToken(sl()))
    ..registerLazySingleton(() => StartVideoSession(sl()))
    ..registerLazySingleton(() => EndVideoSession(sl()));

  // Presentation
  sl.registerFactory(
    () => VideoCallCubit(
      getVideoToken: sl(),
      startVideoSession: sl(),
      endVideoSession: sl(),
      agoraService: sl(),
      permissionService: sl(),
    ),
  );
}

void _registerChatFeature() {
  // The repository owns the realtime socket lifecycle (singleton), reused
  // across conversations. ChatCubit is created per-screen with runtime params.
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
}

void _registerAvailabilityFeature() {
  sl
    ..registerLazySingleton<AvailabilityRemoteDataSource>(
      () => AvailabilityRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AvailabilityRepository>(
      () => AvailabilityRepositoryImpl(remote: sl(), networkInfo: sl()),
    )
    ..registerLazySingleton(() => GetAvailability(sl()))
    ..registerLazySingleton(() => UpdateWeeklyAvailability(sl()))
    ..registerLazySingleton(() => UpsertAvailabilityException(sl()))
    ..registerLazySingleton(() => SetHolidayMode(sl()))
    ..registerFactory(
      () => AvailabilityCubit(
        getAvailability: sl(),
        updateWeekly: sl(),
        upsertException: sl(),
        setHolidayMode: sl(),
      ),
    );
}

void _registerWalletFeature() {
  sl
    ..registerLazySingleton<WalletRemoteDataSource>(
      () => WalletRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(remote: sl(), networkInfo: sl()),
    )
    ..registerLazySingleton(() => GetWalletSummary(sl()))
    ..registerLazySingleton(() => RequestWithdrawal(sl()))
    ..registerFactory(
      () => WalletCubit(getWalletSummary: sl(), requestWithdrawal: sl()),
    );
}

void _registerCallsFeature() {
  // Signalling repository owns its own socket; IncomingCallCubit is created in
  // the provider shell with the current user id.
  sl.registerLazySingleton<CallSignalingRepository>(
    () => CallSignalingRepositoryImpl(client: sl(), tokenStore: sl()),
  );
}
