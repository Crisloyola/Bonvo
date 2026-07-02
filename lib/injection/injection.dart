import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bonvo/core/services/storage_service.dart';
import 'package:bonvo/config/routes/app_router.dart';
import 'package:bonvo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bonvo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bonvo/features/auth/domain/repositories/auth_repository.dart';
import 'package:bonvo/features/auth/domain/usecases/login_with_email.dart';
import 'package:bonvo/features/auth/domain/usecases/login_with_google.dart';
import 'package:bonvo/features/auth/domain/usecases/logout.dart';
import 'package:bonvo/features/auth/domain/usecases/register_with_email.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/business/data/datasources/business_remote_datasource.dart';
import 'package:bonvo/features/business/data/repositories/business_repository_impl.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/business/domain/usecases/create_business.dart';
import 'package:bonvo/features/business/domain/usecases/get_business_stats.dart';
import 'package:bonvo/core/services/fcm_service.dart';
import 'package:bonvo/core/services/notification_service.dart';
import 'package:bonvo/core/services/proximity_service.dart';
import 'package:bonvo/features/points/data/datasources/points_remote_datasource.dart';
import 'package:bonvo/features/points/data/repositories/points_repository_impl.dart';
import 'package:bonvo/features/points/domain/repositories/points_repository.dart';
import 'package:bonvo/features/points/domain/usecases/earn_points.dart';
import 'package:bonvo/features/points/domain/usecases/enroll_in_business.dart';
import 'package:bonvo/features/points/domain/usecases/get_user_transactions.dart';
import 'package:bonvo/features/promotions/data/datasources/promotions_datasource.dart';
import 'package:bonvo/features/promotions/data/repositories/promotions_repository_impl.dart';
import 'package:bonvo/features/promotions/domain/repositories/promotions_repository.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // --- Firebase ---
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // --- Storage service ---
  getIt.registerLazySingleton<StorageService>(() => StorageService());

  // --- Auth datasource ---
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
      googleSignIn: getIt<GoogleSignIn>(),
    ),
  );

  // --- Auth repository ---
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );

  // --- Auth use cases ---
  getIt.registerLazySingleton(() => LoginWithEmail(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LoginWithGoogle(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterWithEmail(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => Logout(getIt<AuthRepository>()));

  // --- Auth BLoC (singleton para que el router pueda accederlo) ---
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      repository: getIt<AuthRepository>(),
      loginWithEmail: getIt<LoginWithEmail>(),
      loginWithGoogle: getIt<LoginWithGoogle>(),
      registerWithEmail: getIt<RegisterWithEmail>(),
      logout: getIt<Logout>(),
    ),
  );

  // --- Points datasource ---
  getIt.registerLazySingleton<PointsRemoteDataSource>(
    () => PointsRemoteDataSourceImpl(getIt<FirebaseFirestore>()),
  );

  // --- Points repository ---
  getIt.registerLazySingleton<PointsRepository>(
    () => PointsRepositoryImpl(getIt<PointsRemoteDataSource>()),
  );

  // --- Points use cases ---
  getIt.registerLazySingleton(() => EarnPoints(getIt<PointsRepository>()));
  getIt.registerLazySingleton(() => GetUserTransactions(getIt<PointsRepository>()));

  // --- Business datasource ---
  getIt.registerLazySingleton<BusinessRemoteDataSource>(
    () => BusinessRemoteDataSourceImpl(getIt<FirebaseFirestore>()),
  );

  // --- Business repository ---
  getIt.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(getIt<BusinessRemoteDataSource>()),
  );

  // --- Business use cases ---
  getIt.registerLazySingleton(() => CreateBusiness(getIt<BusinessRepository>()));
  getIt.registerLazySingleton(() => GetBusinessStats(getIt<BusinessRepository>()));

  // --- Proximity & notifications ---
  getIt.registerLazySingleton<ProximityService>(() => ProximityService());
  getIt.registerLazySingleton<FcmService>(() => FcmService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  // --- Enroll use case (usa Firestore directamente) ---
  getIt.registerLazySingleton(
    () => EnrollInBusiness(getIt<FirebaseFirestore>()),
  );

  // --- Promotions ---
  getIt.registerLazySingleton<PromotionsDataSource>(
    () => PromotionsDataSourceImpl(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<PromotionsRepository>(
    () => PromotionsRepositoryImpl(getIt<PromotionsDataSource>()),
  );

  // --- Router ---
  getIt.registerLazySingleton<AppRouter>(
    () => AppRouter(authBloc: getIt<AuthBloc>()),
  );
}
