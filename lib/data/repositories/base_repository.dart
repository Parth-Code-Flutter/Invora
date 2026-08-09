import '../services/app_database.dart';

abstract class BaseRepository {
  const BaseRepository(this.database);

  final AppDatabase database;
}
