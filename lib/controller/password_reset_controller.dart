import 'dart:convert';
import 'dart:math';

import 'package:aqueduct/aqueduct.dart';
import 'package:genie_api/genie_api.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class PasswordResetController extends ResourceController {
  PasswordResetController(this.context, this.authServer, this.configuration);
  final ManagedContext context;
  final AuthServer authServer;
  final GenieApiConfiguration configuration;

  @Operation.post()
  Future<Response> requestToken(@Bind.query('email') String email) async {
    // Get the user from the database
    final _user = await (Query<User>(context)
      ..where((u) => u.email).equalTo(email.toLowerCase())
    ).fetchOne();

    // Return an error if the user was not found for some reason
    if (_user == null) {
      return Response.notFound();
    }

    final _resetToken = await (Query<PasswordResetToken>(context)
      ..values.associatedUser = _user
      ..values.token = base64Url.encode(List<int>.generate(10, (i) => Random.secure().nextInt(256)))
      ..values.expiresOn = DateTime.now().add(const Duration(minutes: 30))
    ).insert();

    // TODO: Create a HTML email template for reset tokens
    try {
      await send(
          Message()
            ..from = Address(configuration.smtpUsername, 'Makerspace Genie')
            ..recipients.add(_user.email)
            ..subject = 'Password Reset Token'
            ..text = 'Here is your password reset token. It will expire on ${_resetToken.expiresOn.toUtc().toString()}\n\n${_resetToken.token}',
          SmtpServer(configuration.smtpHost,
              username: configuration.smtpUsername,
              password: configuration.smtpPassword,
              port: configuration.smtpPort,
              ignoreBadCertificate: true,
              ssl: true
          )
      );
      return Response.ok(null);
    } catch (e) {
      return Response.serverError(body: 'Unable to send reset token email.');
    }
  }

  @Operation.post("token")
  Future<Response> changePassword(@Bind.path('token') String token, @Bind.query('newPassword') String newPassword) async {
    final _token = await (Query<PasswordResetToken>(context)
      ..where((t) => t.token).equalTo(token)
      ..join(object: (u) => u.associatedUser)
    ).fetchOne();

    if (_token == null) {
      return Response.notFound();
    }

    if (DateTime.now().isBefore(_token.expiresOn)) {
      final _salt = AuthUtility.generateRandomSalt();

      await (Query<User>(context)
        ..values.password = newPassword
        ..values.salt = _salt
        ..values.hashedPassword = authServer.hashPassword(newPassword, _salt)
        ..where((u) => u.id).equalTo(_token.associatedUser.id)
      ).updateOne();

      await (Query<PasswordResetToken>(context)
        ..where((t) => t.token).equalTo(token)
      ).delete();

      return Response.ok(null);
    } else {
      return Response.forbidden();
    }
  }
}