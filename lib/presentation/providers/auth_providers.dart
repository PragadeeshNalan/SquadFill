import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squadfill/data/models/user_model.dart';
import 'package:squadfill/data/services/firebase_auth_service.dart';
import 'package:squadfill/data/repositories/auth_repository_impl.dart';
import 'package:squadfill/domain/repositories/auth_repository.dart';

/// Provider exposing the low-level [FirebaseAuthService] instance.
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Provider exposing the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthRepositoryImpl(authService);
});

/// StreamProvider listening to user session authorization changes.
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Provider exposing the active user's [UserModel] details.
final currentSquadUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

/// StateNotifier to manage authentication procedures (login, signup, logout)
/// and track loading or error states for UI components.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  /// Constructor initializing with standard empty state and injected repository.
  AuthController(this._authRepository) : super(const AsyncData(null));

  /// Perform sign-in, managing loading state and exceptions.
  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  /// Perform sign-up registration, managing loading state and exceptions.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String favoriteSport,
    required String skillLevel,
    required String photoUrl,
  }) async {
    state = const AsyncLoading();
    try {
      await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        favoriteSport: favoriteSport,
        skillLevel: skillLevel,
        photoUrl: photoUrl,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  /// Perform sign-out session termination.
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _authRepository.signOut();
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// Send password reset verification links.
  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

/// Provider exposing the [AuthController] state and actions.
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthController(authRepo);
});
