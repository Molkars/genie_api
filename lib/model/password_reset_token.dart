import 'package:genie_api/genie_api.dart';

class PasswordResetToken extends ManagedObject<_PasswordResetToken> implements _PasswordResetToken {}

class _PasswordResetToken {
  @primaryKey
  int id;

  @Column(unique: true)
  String token;

  @Column()
  DateTime expiresOn;

  @Relate(#passwordResetTokens)
  User associatedUser;
}