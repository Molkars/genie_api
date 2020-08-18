import 'dart:convert';
import 'dart:math';

import 'package:aqueduct/aqueduct.dart';
import 'package:genie_api/genie_api.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// This [PasswordResetController] handles the endpoint to request password
/// reset tokens and to change a password when a user has a valid reset token.
class PasswordResetController extends ResourceController {
  PasswordResetController(this.context, this.authServer, this.configuration);
  final ManagedContext context;
  final AuthServer authServer;
  final GenieApiConfiguration configuration;

  /// Handles requesting a password reset token be sent to a user. A valid email
  /// address associated with a current user must be passed to this method. It will
  /// return a 200 result if the token was successfully sent, a 404 error if the email
  /// provided is not associated with any account, and a 503 error if there was any
  /// other error with the request.
  @Operation.post()
  Future<Response> requestToken(@Bind.query('email') String email) async {
    // Get the user from the database by their email
    final _user = await (Query<User>(context)
      ..where((u) => u.email).equalTo(email.toLowerCase())
    ).fetchOne();

    // Return an error if there is not an account for the provided email
    if (_user == null) {
      return Response.notFound();
    }

    // Create a reset token for the user
    final _resetToken = await (Query<PasswordResetToken>(context)
      ..values.associatedUser = _user
      ..values.token = base64Url.encode(List<int>.generate(10, (i) => Random.secure().nextInt(256)))
      ..values.expiresOn = DateTime.now().add(const Duration(minutes: 30))
    ).insert();

    // Attempt to send an email to the user
    try {
      await send(
          // Form the message to be sent
          Message()
            ..from = Address(configuration.smtpUsername, 'Makerspace Genie')
            ..recipients.add(_user.email)
            ..subject = 'Password Reset Token'
            ..html = '<!DOCTYPE html><html><head> <meta charset="utf-8"> '
                '<meta http-equiv="x-ua-compatible" content="ie=edge"> '
                '<title>Makerspace Genie Password Reset</title> '
                '<meta name="viewport" content="width=device-width, initial-scale=1"> '
                '<style type="text/css"> @media screen{@font-face{font-family: \'Source Sans Pro\'; '
                'font-style: normal; font-weight: 400; src: local(\'Source Sans Pro Regular\'), '
                'local(\'SourceSansPro-Regular\'), url(https://fonts.gstatic.com/s/sourcesanspro/v10/ODelI1aHBYDBqgeIAH2zlBM0YzuT7MdOe03otPbuUS0.woff) '
                'format(\'woff\');}@font-face{font-family: \'Source Sans Pro\'; font-style: normal; font-weight: 700; src: local(\'Source Sans Pro Bold\'), '
                'local(\'SourceSansPro-Bold\'), url(https://fonts.gstatic.com/s/sourcesanspro/v10/toadOcfmlt9b38dHJxOBGFkQc6VGVFSmCnC_l7QZG60.woff) '
                'format(\'woff\');}}body, table, td, a{-ms-text-size-adjust: 100%; /* 1 */ -webkit-text-size-adjust: 100%; /* 2 */}table, '
                'td{mso-table-rspace: 0pt; mso-table-lspace: 0pt;}img{-ms-interpolation-mode: bicubic;}a[x-apple-data-detectors]{font-family: inherit !important; '
                'font-size: inherit !important; font-weight: inherit !important; line-height: inherit !important; color: inherit !important; text-decoration: none '
                '!important;}div[style*="margin: 16px 0;"]{margin: 0 !important;}body{width: 100% !important; height: 100% !important; padding: 0 !important; '
                'margin: 0 !important;}table{border-collapse: collapse !important;}a{color: #1a82e2;}img{height: auto; line-height: 100%; text-decoration: none; '
                'border: 0; outline: none;}</style></head><body style="background-color: #e9ecef;"> <div class="preheader" style="display: none; max-width: 0; '
                'max-height: 0; overflow: hidden; font-size: 1px; line-height: 1px; color: #fff; opacity: 0;"> A password reset request has been receieved for '
                'your account. If this was not you please disreguard this email. </div><table border="0" cellpadding="0" cellspacing="0" width="100%"> <tr> '
                '<td align="center" bgcolor="#e9ecef"> <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px;"> <tr> '
                '<td align="center" valign="top" style="padding: 36px 24px;"> </td></tr></table> </td></tr><tr> <td align="center" bgcolor="#e9ecef"> '
                '<table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px;"> <tr> <td align="left" bgcolor="#ffffff" '
                'style="padding: 36px 24px 0; font-family: \'Source Sans Pro\', Helvetica, Arial, sans-serif; border-top: 3px solid #d4dadf;"> '
                '<h1 style="margin: 0; font-size: 32px; font-weight: 700; letter-spacing: -1px; line-height: 48px;">Dear ${_user.firstName},</h1> '
                '</td></tr></table> </td></tr><tr> <td align="center" bgcolor="#e9ecef"> <table border="0" cellpadding="0" cellspacing="0" width="100%" '
                'style="max-width: 600px;"> <tr> <td align="left" bgcolor="#ffffff" style="padding: 24px; font-family: \'Source Sans Pro\', Helvetica, '
                'Arial, sans-serif; font-size: 16px; line-height: 24px;"> <p style="margin: 0;">You recently requested to reset your password for your '
                'Makerspace Genie account. Use the reset token below to reset it.</p></td></tr><tr> <td align="left" bgcolor="#ffffff"> <table border="0" '
                'cellpadding="0" cellspacing="0" width="100%"> <tr> <td align="center" bgcolor="#ffffff" style="padding: 12px;"> <table border="0" '
                'cellpadding="0" cellspacing="0"> <tr> <td align="center" bgcolor="#ffffff" style="font-size: x-large;"> <p>${_resetToken.token}</p></td></tr>'
                '</table> </td></tr></table> </td></tr><tr> <td align="left" bgcolor="#ffffff" style="padding: 24px; font-family: \'Source Sans Pro\', '
                'Helvetica, Arial, sans-serif; font-size: 16px; line-height: 24px;"> <p style="margin: 0;">If you did not request a password reset, '
                'please ignore this email. This password reset token is only valid for the next 30 minutes.</p></td></tr><tr> <td align="left" '
                'bgcolor="#ffffff" style="padding: 24px; font-family: \'Source Sans Pro\', Helvetica, Arial, sans-serif; font-size: 16px; line-height: 24px; '
                'border-bottom: 3px solid #d4dadf"> <p style="margin: 0;">Thanks,<br>The Makerspace Genie Team</p></td></tr></table> </td></tr><tr> '
                '<td align="center" bgcolor="#e9ecef" style="padding: 24px;"> <table border="0" cellpadding="0" cellspacing="0" width="100%" '
                'style="max-width: 600px;"> <tr> <td align="center" bgcolor="#e9ecef" style="padding: 12px 24px; font-family: \'Source Sans Pro\', '
                'Helvetica, Arial, sans-serif; font-size: 14px; line-height: 20px; color: #666;"> <p style="margin: 0;">You received this email because '
                'we received a request for a password reset for your account. If you didn\'t request a password reset you can safely delete this email.</p>'
                '</td></tr></table> </td></tr></table></body></html>',

          // Configure the SMTP server to send the email from
          SmtpServer(configuration.smtpHost,
              username: configuration.smtpUsername,
              password: configuration.smtpPassword,
              port: configuration.smtpPort,
              ignoreBadCertificate: true,
              ssl: true
          )
      );

      // Return a success message if there was no error
      return Response.ok(null);
    } catch (e) {
      // Return an error if there was an error while sending the email
      return Response.serverError(body: 'Unable to send reset token email.');
    }
  }

  /// Changes a users password if they provide a valid password reset token. This requires
  /// a valid reset token that is not expired and the new password for the user account.
  @Operation.post("token")
  Future<Response> changePassword(@Bind.path('token') String token, @Bind.query('newPassword') String newPassword) async {
    // Fetch the token and its associated user from the database
    final _token = await (Query<PasswordResetToken>(context)
      ..where((t) => t.token).equalTo(token)
      ..join(object: (u) => u.associatedUser)
    ).fetchOne();

    // Return a 404 error if the token was not a valid token
    if (_token == null) {
      return Response.notFound();
    }

    // Reset the user password if the token is not expired
    if (DateTime.now().isBefore(_token.expiresOn)) {
      // Generate the salt to use for the new password
      final _salt = AuthUtility.generateRandomSalt();

      // Update the users password in the database
      await (Query<User>(context)
        ..values.password = newPassword
        ..values.salt = _salt
        ..values.hashedPassword = authServer.hashPassword(newPassword, _salt)
        ..where((u) => u.id).equalTo(_token.associatedUser.id)
      ).updateOne();

      // Delete the reset token from the database
      await (Query<PasswordResetToken>(context)
        ..where((t) => t.token).equalTo(token)
      ).delete();

      // Return that the password reset was successful
      return Response.ok(null);
    } else {
      // Return an forbidden message if there was an issue or the token was expired
      return Response.forbidden();
    }
  }
}