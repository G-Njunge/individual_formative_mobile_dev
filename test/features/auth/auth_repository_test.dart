import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/errors/user_facing_exception.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';
import 'package:individual_formative/features/auth/data/auth_repository.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('signUp', () {
    test(
      'creates an unapproved staff profile with a server timestamp',
      () async {
        final auth = MockFirebaseAuth(verifyEmailAutomatically: false);
        final repo = AuthRepository(auth, db);

        await repo.signUp(
          name: '  Jean Habimana ',
          email: 'J.Habimana@alueducation.com',
          password: 'campus2026',
          role: UserRole.staff,
          staffId: 'fac-0231',
        );

        final uid = auth.currentUser!.uid;
        final doc = await db.doc('users/$uid').get();
        expect(doc.data()!['name'], 'Jean Habimana');
        expect(doc.data()!['email'], 'j.habimana@alueducation.com');
        expect(doc.data()!['role'], 'staff');
        expect(doc.data()!['staffId'], 'FAC-0231');
        expect(doc.data()!['approved'], isFalse);
        expect(doc.data()!['createdAt'], isNotNull);
        expect(auth.currentUser!.emailVerified, isFalse);
      },
    );

    test('a student profile has no staff fields', () async {
      final auth = MockFirebaseAuth(verifyEmailAutomatically: false);
      await AuthRepository(auth, db).signUp(
        name: 'Amani Mugisha',
        email: 'a.mugisha@alustudent.com',
        password: 'campus2026',
        role: UserRole.student,
        staffId: 'ignored',
      );
      final doc = await db.doc('users/${auth.currentUser!.uid}').get();
      expect(doc.data()!.containsKey('staffId'), isFalse);
      expect(doc.data()!.containsKey('approved'), isFalse);
    });
  });

  group('signIn', () {
    Future<MockFirebaseAuth> seeded(String role, {MockUser? user}) async {
      final mockUser = user ?? MockUser(uid: 'u1', email: 'a@alustudent.com');
      await db.doc('users/${mockUser.uid}').set({
        'name': 'Amani',
        'email': mockUser.email,
        'role': role,
      });
      return MockFirebaseAuth(mockUser: mockUser);
    }

    test('succeeds when the role matches', () async {
      final auth = await seeded('student');
      await AuthRepository(auth, db).signIn(
        email: 'a@alustudent.com',
        password: 'x',
        expectedRole: UserRole.student,
      );
      expect(auth.currentUser, isNotNull);
    });

    test('rejects and signs out when the role does not match', () async {
      final auth = await seeded('staff');
      final repo = AuthRepository(auth, db);
      await expectLater(
        repo.signIn(
          email: 'a@alustudent.com',
          password: 'x',
          expectedRole: UserRole.student,
        ),
        throwsA(
          isA<UserFacingException>().having(
            (e) => e.message,
            'message',
            contains('Choose Campus staff'),
          ),
        ),
      );
      expect(auth.currentUser, isNull);
    });

    test('removes an account left unverified for over 24 hours', () async {
      final created = DateTime.now().subtract(const Duration(hours: 25));
      final user = MockUser(
        uid: 'old',
        email: 'late@alustudent.com',
        isEmailVerified: false,
        metadata: UserMetadata(
          created.millisecondsSinceEpoch,
          created.millisecondsSinceEpoch,
        ),
      );
      final auth = await seeded('student', user: user);

      await expectLater(
        AuthRepository(auth, db).signIn(
          email: 'late@alustudent.com',
          password: 'x',
          expectedRole: UserRole.student,
        ),
        throwsA(isA<UserFacingException>()),
      );
      expect((await db.doc('users/old').get()).exists, isFalse);
    });
  });

  group('verification window', () {
    MockUser userCreated(Duration ago, {bool verified = false}) {
      final created = DateTime(2026, 11, 6, 12).subtract(ago);
      return MockUser(
        isEmailVerified: verified,
        metadata: UserMetadata(created.millisecondsSinceEpoch, null),
      );
    }

    final now = DateTime(2026, 11, 6, 12);

    test('is open for 24 hours', () {
      expect(
        AuthRepository.isVerificationExpired(
          userCreated(const Duration(hours: 23)),
          now: now,
        ),
        isFalse,
      );
      expect(
        AuthRepository.isVerificationExpired(
          userCreated(const Duration(hours: 24, minutes: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('never expires a verified account', () {
      expect(
        AuthRepository.isVerificationExpired(
          userCreated(const Duration(days: 30), verified: true),
          now: now,
        ),
        isFalse,
      );
    });
  });

  test('auth error codes become plain messages', () {
    expect(
      AuthRepository.messageForAuthError('invalid-credential'),
      'That email and password do not match.',
    );
    expect(
      AuthRepository.messageForAuthError('email-already-in-use'),
      contains('already exists'),
    );
    expect(
      AuthRepository.messageForAuthError('something-new'),
      'Something went wrong. Please try again.',
    );
  });
}
