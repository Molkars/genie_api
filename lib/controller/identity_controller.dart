import 'package:genie_api/genie_api.dart';

/// This [ResourceController] handles the endpoint to get information about the
/// currently logged in user. It is only accessible after logging in with OAuth2.0
class IdentityController extends ResourceController {
  IdentityController(this.context);
  final ManagedContext context;

  /// Returns a [User] containing the information about the user that
  /// is currently logged in and sent the request.
  @Operation.get()
  Future<Response> getIdentity() async {
    // Get the user from the database
    final _user = await (Query<User>(context)
      ..where((o) => o.id).equalTo(request.authorization.ownerID)
      ..join(set: (user) => user.makerspacesOwned)
    ).fetchOne();

    // Return an error if the user was not found for some reason
    if (_user == null) {
      return Response.notFound();
    }

    // Return the user from the database
    return Response.ok(_user);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    var _userSchema = context.schema.getObjectWithType(User);

    context.defer(() {
      _userSchema = context.document.components.resolve(_userSchema);
      _userSchema.properties.remove("tokens");
    });

    return {
      "200": APIResponse.schema("Identity Fetched Successfully.", _userSchema),
    };
  }
}