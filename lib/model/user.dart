import 'package:genie_api/genie_api.dart';

class User extends ManagedObject<_User> implements _User, ManagedAuthResourceOwner<_User> {
  @Serialize(input: true, output: false)
  String password;
}

class _User extends ResourceOwnerTableDefinition {
  @Column()
  String firstName;
  
  @Column()
  String lastName;

  @Column()
  String email;

  @Column(nullable: true)
  String profilePictureUrl;

  ManagedSet<Makerspace> makerspacesOwned;
}