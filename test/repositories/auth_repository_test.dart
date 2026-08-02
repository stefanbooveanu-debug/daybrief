import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:day_brief/repositories/auth_repository.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuth auth;
  late AuthRepository repository;

  setUp(() {
    auth = _MockFirebaseAuth();
    repository = AuthRepository(auth: auth);
  });

  group('AuthRepository', () {
    test('signInWithEmailAndPassword delegates to FirebaseAuth', () async {
      final credential = _MockUserCredential();
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      final result = await repository.signInWithEmailAndPassword(
        email: 'a@b.com',
        password: 'secret1',
      );

      expect(result, same(credential));
      verify(
        () => auth.signInWithEmailAndPassword(
          email: 'a@b.com',
          password: 'secret1',
        ),
      ).called(1);
    });

    test('signOut delegates to FirebaseAuth', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      await repository.signOut();
      verify(() => auth.signOut()).called(1);
    });

    test('currentUser reads from FirebaseAuth', () {
      final user = _MockUser();
      when(() => auth.currentUser).thenReturn(user);
      expect(repository.currentUser, same(user));
    });

    test('authStateChanges exposes Firebase stream', () {
      when(() => auth.authStateChanges())
          .thenAnswer((_) => Stream<User?>.value(null));
      expect(repository.authStateChanges, isA<Stream<User?>>());
    });
  });
}
