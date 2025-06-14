import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:user_repository/user_repository.dart';

class FirebaseUserRepo implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  FirebaseUserRepo({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Stream trạng thái user, kết hợp auth + Firestore
  @override
  Stream<MyUser> get user {
    return _firebaseAuth.authStateChanges().switchMap((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(MyUser.empty);
      } else {
        // Theo dõi thông tin user trong Firestore
        return usersCollection.doc(firebaseUser.uid).snapshots().map(
          (doc) {
            if (!doc.exists || doc.data() == null) {
              return MyUser.empty;
            }
            return MyUser.fromEntity(
              MyUserEntity.fromDocument(doc.data()! as Map<String, dynamic>),
            );
          },
        );
      }
    });
  }

  @override
  Future<void> logOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      log('Logout error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      log('SignIn error: $e');
      rethrow;
    }
  }

  @override
  Future<MyUser> signUp(MyUser myUser, String password) async {
    try {
      UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
              email: myUser.email, password: password);

      myUser.userId = credential.user!.uid;

      // Lưu thông tin user vào Firestore
      await setUserData(myUser);

      return myUser;
    } catch (e) {
      log('SignUp error: $e');
      rethrow;
    }
  }

  @override
  Future<void> setUserData(MyUser myUser) async {
    try {
      await usersCollection
          .doc(myUser.userId)
          .set(myUser.toEntity().toDocument());
    } catch (e) {
      log('SetUserData error: $e');
      rethrow;
    }
  }
}
