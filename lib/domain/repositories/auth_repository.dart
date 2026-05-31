import 'package:squadfill/data/models/user_model.dart';

/// Domain interface defining authentication contracts for SquadFill.
/// 
/// Decouples UI controllers from underlying Firebase Authentication services.
abstract class AuthRepository {
  /// Stream that emits [UserModel] changes when a user logs in or out.
  Stream<UserModel?> get authStateChanges;

  /// Signs in a user using an email and password.
  /// 
  /// Throws standard custom exceptions on failure.
  Future<UserModel> signInWithEmailAndPassword(String email, String password);

  /// Registers a new user account with profiles details stored in Firestore.
  /// 
  /// Throws standard custom exceptions on failure.
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String favoriteSport,
    required String skillLevel,
    required String photoUrl,
  });

  /// Signs out the currently authenticated user session.
  Future<void> signOut();

  /// Sends a password reset verification link to the user's email.
  Future<void> sendPasswordResetEmail(String email);

  /// Retrieves the currently authenticated user's model directly, if logged in.
  Future<UserModel?> get currentUser;
}
