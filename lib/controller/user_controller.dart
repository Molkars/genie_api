import 'package:genie_api/genie_api.dart';

/// This [ResourceController] handles the endpoint to preform CRUD operations
/// on [User]s. It is only accessible after logging in with OAuth2.0
class UserController extends ResourceController {
  UserController(this.context, this.authServer);
  final ManagedContext context;
  final AuthServer authServer;

  /// Returns a JSON formatted list of all [User]s in the database.
  @Operation.get()
  Future<Response> getAllUsers() async {
    return Response.ok(await Query<User>(context).fetch());
  }

  /// Returns the [User] from the database specified by the [id].
  @Operation.get('id')
  Future<Response> getUser(@Bind.path('id') int id) async {
    // Get the user specified from the database
    final _user = await (Query<User>(context)
      ..where((user) => user.id).equalTo(id)
      ..join(set: (user) => user.makerspacesOwned)
    ).fetchOne();

    // Return an error if the user was not located in the database
    if (_user == null) {
      return Response.notFound();
    }

    // Return the user specified
    return Response.ok(_user);
  }

  /// Update the [User] with the specified [id]. All values from the [User] object are
  /// valid except the password and id fields.
  @Operation.put('id')
  Future<Response> updateUser(@Bind.path('id') int id, @Bind.body() User user) async {
    /* Uncomment this to allow user accounts to only be updated by their own user.
    if (request.authorization.ownerID != id) {
      Response.unauthorized();
    }
     */

    // Update the user in the DB using the values provided
    final _user = await (Query<User>(context)
        ..values = user
        ..where((user) => user.id).equalTo(id)
    ).updateOne();

    // Return an error if the user being updated was not located in the database
    if (_user == null) {
      return Response.notFound();
    }

    // Return the updated user
    return Response.ok(_user);
  }

  /// Deletes the [User] with the specified [id] from the database.
  @Operation.delete('id')
  Future<Response> deleteUser(@Bind.path('id') int id) async {
    /* Uncomment this to allow user accounts to be deleted only by their own user.
    if (request.authorization.ownerID != id) {
      return Response.unauthorized();
    }
     */

    // Delete and de-authorize all login tokens for this user
    await authServer.revokeAllGrantsForResourceOwner(id);

    // Delete the user from the DB, this will delete any resources created by them
    await (Query<User>(context)
        ..where((user) => user.id).equalTo(id)
    ).delete();

    // Return an empty success code showing the user was deleted
    return Response.ok(null);
  }
}