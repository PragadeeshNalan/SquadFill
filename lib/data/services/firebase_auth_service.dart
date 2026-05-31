import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:squadfill/data/models/user_model.dart';
import 'package:squadfill/core/constants/app_constants.dart';

/// Low-level service wrapper interacting directly with Firebase SDKs.
/// 
/// Handles Firebase Auth email/password credentials and synchronizes 
/// user profiles inside the Firestore 'users' collection.
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Map Firebase User changes to our custom [UserModel] stream.
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      return await getUserProfile(user.uid);
    });
  }

  /// Retrieve the current user's profile document from Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
          
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Return null or rethrow based on error policy
      return null;
    }
  }

  /// Sign in using Firebase Authentication email and password.

  /// Register a user in Firebase Auth and create their Firestore profile.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String favoriteSport,
    required String skillLevel,
    required String photoUrl,
  }) async {
    try {
      // 1. Create authentication credentials
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw Exception('Registration credentials creation failed.');
      }

      // 2. Initialize the user profile model
      final newUser = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        photoUrl: photoUrl,
        favoriteSport: favoriteSport,
        skillLevel: skillLevel,
        reliabilityScore: 100.0,
        matchesJoined: 0,
        noShowCount: 0,
      );

      // 3. Save user profile document to Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toFirestore());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected registration error occurred: ${e.toString()}');
    }
  }
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw Exception('User authentication failed.');
      }

      final userModel = await getUserProfile(user.uid);
      if (userModel == null) {
        throw Exception('User profile not found in database.');
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Sign out the current user session from Firebase Auth.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Sends a password reset email link via Firebase Auth.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Retrieve the current logged-in user profile.
  Future<UserModel?> get currentProfile async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await getUserProfile(user.uid);
  }

  /// Helper to convert Firebase Auth exceptions into user-friendly error messages.
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account already exists for this email.');
      case 'invalid-email':
        return Exception('The email address format is invalid.');
      case 'weak-password':
        return Exception('The password is too weak. Must be at least 6 characters.');
      case 'network-request-failed':
        return Exception('Network error. Check your internet connection.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      default:
        return Exception(e.message ?? 'Authentication error occurred.');
    }
  }
}
