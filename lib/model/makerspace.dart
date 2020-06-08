import 'package:genie_api/genie_api.dart';

/// This [ManagedObject] handles the information stored within the _makerspace
/// table in the database.
class Makerspace extends ManagedObject<_Makerspace> implements _Makerspace {}
class _Makerspace {
  @primaryKey
  int id;

  @Column()
  String name;

  @Relate(#makerspacesOwned)
  User owner;

  @Column(databaseType: ManagedPropertyType.bigInteger)
  int primaryColor;

  @Column(databaseType: ManagedPropertyType.bigInteger)
  int secondaryColor;

  @Column(nullable: true)
  String imageUrl;
}