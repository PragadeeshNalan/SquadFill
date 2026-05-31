import 'package:squadfill/data/models/user_model.dart';
import 'package:squadfill/data/services/firebase_auth_service.dart';
import 'package:squadfill/domain/repositories/auth_repository.dart';

/// Repository implementation of [AuthRepository].
/// 
/// Coordinates call requests to [FirebaseAuthService] and handles mapping.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;

  /// Constructor injecting the [FirebaseAuthService].
  AuthRepositoryImpl(this._authService);

  @override
  Stream<UserModel?> get authStateChanges => _authService.authStateChanges;

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) {
    return _authService.signIn(email, password);
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String favoriteSport,
    required String skillLevel,
    required String photoUrl,
  }) {
    return _authService.signUp(
      email: email,
      password: password,
      name: name,
      favoriteSport: favoriteSport,
      skillLevel: skillLevel,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordReset(email);
  }

  @override
  Future<UserModel?> get currentUser => _authService.currentProfile;
}
