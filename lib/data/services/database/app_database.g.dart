// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nickname, rating];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String nickname;
  final int rating;
  const Profile({
    required this.id,
    required this.nickname,
    required this.rating,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nickname'] = Variable<String>(nickname);
    map['rating'] = Variable<int>(rating);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      nickname: Value(nickname),
      rating: Value(rating),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      nickname: serializer.fromJson<String>(json['nickname']),
      rating: serializer.fromJson<int>(json['rating']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nickname': serializer.toJson<String>(nickname),
      'rating': serializer.toJson<int>(rating),
    };
  }

  Profile copyWith({int? id, String? nickname, int? rating}) => Profile(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    rating: rating ?? this.rating,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      rating: data.rating.present ? data.rating.value : this.rating,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nickname, rating);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.rating == this.rating);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> nickname;
  final Value<int> rating;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.rating = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String nickname,
    required int rating,
  }) : nickname = Value(nickname),
       rating = Value(rating);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? nickname,
    Expression<int>? rating,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (rating != null) 'rating': rating,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? nickname,
    Value<int>? rating,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      rating: rating ?? this.rating,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts
    with TableInfo<$AttemptsTable, AttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _positionIdMeta = const VerificationMeta(
    'positionId',
  );
  @override
  late final GeneratedColumn<String> positionId = GeneratedColumn<String>(
    'position_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fulfilledMeta = const VerificationMeta(
    'fulfilled',
  );
  @override
  late final GeneratedColumn<bool> fulfilled = GeneratedColumn<bool>(
    'fulfilled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fulfilled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _opponentMeta = const VerificationMeta(
    'opponent',
  );
  @override
  late final GeneratedColumn<String> opponent = GeneratedColumn<String>(
    'opponent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opponentLevelMeta = const VerificationMeta(
    'opponentLevel',
  );
  @override
  late final GeneratedColumn<int> opponentLevel = GeneratedColumn<int>(
    'opponent_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    positionId,
    playedAt,
    outcome,
    fulfilled,
    opponent,
    opponentLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('position_id')) {
      context.handle(
        _positionIdMeta,
        positionId.isAcceptableOrUnknown(data['position_id']!, _positionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_positionIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('fulfilled')) {
      context.handle(
        _fulfilledMeta,
        fulfilled.isAcceptableOrUnknown(data['fulfilled']!, _fulfilledMeta),
      );
    } else if (isInserting) {
      context.missing(_fulfilledMeta);
    }
    if (data.containsKey('opponent')) {
      context.handle(
        _opponentMeta,
        opponent.isAcceptableOrUnknown(data['opponent']!, _opponentMeta),
      );
    } else if (isInserting) {
      context.missing(_opponentMeta);
    }
    if (data.containsKey('opponent_level')) {
      context.handle(
        _opponentLevelMeta,
        opponentLevel.isAcceptableOrUnknown(
          data['opponent_level']!,
          _opponentLevelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      positionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position_id'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      fulfilled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fulfilled'],
      )!,
      opponent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opponent'],
      )!,
      opponentLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opponent_level'],
      ),
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class AttemptRow extends DataClass implements Insertable<AttemptRow> {
  final int id;
  final String positionId;
  final DateTime playedAt;

  /// `win`, `draw` ou `loss`, do ponto de vista do jogador.
  final String outcome;
  final bool fulfilled;
  final String opponent;

  /// O nível do Maia, quando ele foi o adversário.
  final int? opponentLevel;
  const AttemptRow({
    required this.id,
    required this.positionId,
    required this.playedAt,
    required this.outcome,
    required this.fulfilled,
    required this.opponent,
    this.opponentLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['position_id'] = Variable<String>(positionId);
    map['played_at'] = Variable<DateTime>(playedAt);
    map['outcome'] = Variable<String>(outcome);
    map['fulfilled'] = Variable<bool>(fulfilled);
    map['opponent'] = Variable<String>(opponent);
    if (!nullToAbsent || opponentLevel != null) {
      map['opponent_level'] = Variable<int>(opponentLevel);
    }
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      positionId: Value(positionId),
      playedAt: Value(playedAt),
      outcome: Value(outcome),
      fulfilled: Value(fulfilled),
      opponent: Value(opponent),
      opponentLevel: opponentLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(opponentLevel),
    );
  }

  factory AttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRow(
      id: serializer.fromJson<int>(json['id']),
      positionId: serializer.fromJson<String>(json['positionId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      outcome: serializer.fromJson<String>(json['outcome']),
      fulfilled: serializer.fromJson<bool>(json['fulfilled']),
      opponent: serializer.fromJson<String>(json['opponent']),
      opponentLevel: serializer.fromJson<int?>(json['opponentLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'positionId': serializer.toJson<String>(positionId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'outcome': serializer.toJson<String>(outcome),
      'fulfilled': serializer.toJson<bool>(fulfilled),
      'opponent': serializer.toJson<String>(opponent),
      'opponentLevel': serializer.toJson<int?>(opponentLevel),
    };
  }

  AttemptRow copyWith({
    int? id,
    String? positionId,
    DateTime? playedAt,
    String? outcome,
    bool? fulfilled,
    String? opponent,
    Value<int?> opponentLevel = const Value.absent(),
  }) => AttemptRow(
    id: id ?? this.id,
    positionId: positionId ?? this.positionId,
    playedAt: playedAt ?? this.playedAt,
    outcome: outcome ?? this.outcome,
    fulfilled: fulfilled ?? this.fulfilled,
    opponent: opponent ?? this.opponent,
    opponentLevel: opponentLevel.present
        ? opponentLevel.value
        : this.opponentLevel,
  );
  AttemptRow copyWithCompanion(AttemptsCompanion data) {
    return AttemptRow(
      id: data.id.present ? data.id.value : this.id,
      positionId: data.positionId.present
          ? data.positionId.value
          : this.positionId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      fulfilled: data.fulfilled.present ? data.fulfilled.value : this.fulfilled,
      opponent: data.opponent.present ? data.opponent.value : this.opponent,
      opponentLevel: data.opponentLevel.present
          ? data.opponentLevel.value
          : this.opponentLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRow(')
          ..write('id: $id, ')
          ..write('positionId: $positionId, ')
          ..write('playedAt: $playedAt, ')
          ..write('outcome: $outcome, ')
          ..write('fulfilled: $fulfilled, ')
          ..write('opponent: $opponent, ')
          ..write('opponentLevel: $opponentLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    positionId,
    playedAt,
    outcome,
    fulfilled,
    opponent,
    opponentLevel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRow &&
          other.id == this.id &&
          other.positionId == this.positionId &&
          other.playedAt == this.playedAt &&
          other.outcome == this.outcome &&
          other.fulfilled == this.fulfilled &&
          other.opponent == this.opponent &&
          other.opponentLevel == this.opponentLevel);
}

class AttemptsCompanion extends UpdateCompanion<AttemptRow> {
  final Value<int> id;
  final Value<String> positionId;
  final Value<DateTime> playedAt;
  final Value<String> outcome;
  final Value<bool> fulfilled;
  final Value<String> opponent;
  final Value<int?> opponentLevel;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.positionId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.fulfilled = const Value.absent(),
    this.opponent = const Value.absent(),
    this.opponentLevel = const Value.absent(),
  });
  AttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String positionId,
    required DateTime playedAt,
    required String outcome,
    required bool fulfilled,
    required String opponent,
    this.opponentLevel = const Value.absent(),
  }) : positionId = Value(positionId),
       playedAt = Value(playedAt),
       outcome = Value(outcome),
       fulfilled = Value(fulfilled),
       opponent = Value(opponent);
  static Insertable<AttemptRow> custom({
    Expression<int>? id,
    Expression<String>? positionId,
    Expression<DateTime>? playedAt,
    Expression<String>? outcome,
    Expression<bool>? fulfilled,
    Expression<String>? opponent,
    Expression<int>? opponentLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (positionId != null) 'position_id': positionId,
      if (playedAt != null) 'played_at': playedAt,
      if (outcome != null) 'outcome': outcome,
      if (fulfilled != null) 'fulfilled': fulfilled,
      if (opponent != null) 'opponent': opponent,
      if (opponentLevel != null) 'opponent_level': opponentLevel,
    });
  }

  AttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? positionId,
    Value<DateTime>? playedAt,
    Value<String>? outcome,
    Value<bool>? fulfilled,
    Value<String>? opponent,
    Value<int?>? opponentLevel,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      positionId: positionId ?? this.positionId,
      playedAt: playedAt ?? this.playedAt,
      outcome: outcome ?? this.outcome,
      fulfilled: fulfilled ?? this.fulfilled,
      opponent: opponent ?? this.opponent,
      opponentLevel: opponentLevel ?? this.opponentLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (positionId.present) {
      map['position_id'] = Variable<String>(positionId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (fulfilled.present) {
      map['fulfilled'] = Variable<bool>(fulfilled.value);
    }
    if (opponent.present) {
      map['opponent'] = Variable<String>(opponent.value);
    }
    if (opponentLevel.present) {
      map['opponent_level'] = Variable<int>(opponentLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('positionId: $positionId, ')
          ..write('playedAt: $playedAt, ')
          ..write('outcome: $outcome, ')
          ..write('fulfilled: $fulfilled, ')
          ..write('opponent: $opponent, ')
          ..write('opponentLevel: $opponentLevel')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [profiles, attempts];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required String nickname,
  required int rating,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> nickname,
  Value<int> rating,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nickname = const Value.absent(),
            Value<int> rating = const Value.absent(),
          }) => ProfilesCompanion(id: id, nickname: nickname, rating: rating),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nickname,
                required int rating,
              }) => ProfilesCompanion.insert(
                id: id,
                nickname: nickname,
                rating: rating,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, Profile>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, Profile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  required String positionId,
  required DateTime playedAt,
  required String outcome,
  required bool fulfilled,
  required String opponent,
  Value<int?> opponentLevel,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  Value<String> positionId,
  Value<DateTime> playedAt,
  Value<String> outcome,
  Value<bool> fulfilled,
  Value<String> opponent,
  Value<int?> opponentLevel,
});

class $$AttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get positionId => $composableBuilder(
    column: $table.positionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fulfilled => $composableBuilder(
    column: $table.fulfilled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opponent => $composableBuilder(
    column: $table.opponent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get opponentLevel => $composableBuilder(
    column: $table.opponentLevel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get positionId => $composableBuilder(
    column: $table.positionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fulfilled => $composableBuilder(
    column: $table.fulfilled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opponent => $composableBuilder(
    column: $table.opponent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get opponentLevel => $composableBuilder(
    column: $table.opponentLevel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get positionId => $composableBuilder(
    column: $table.positionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<bool> get fulfilled =>
      $composableBuilder(column: $table.fulfilled, builder: (column) => column);

  GeneratedColumn<String> get opponent =>
      $composableBuilder(column: $table.opponent, builder: (column) => column);

  GeneratedColumn<int> get opponentLevel => $composableBuilder(
    column: $table.opponentLevel,
    builder: (column) => column,
  );
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttemptsTable,
          AttemptRow,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (
            AttemptRow,
            BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow>,
          ),
          AttemptRow,
          PrefetchHooks Function()
        > {
  $$AttemptsTableTableManager(_$AppDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> positionId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<bool> fulfilled = const Value.absent(),
                Value<String> opponent = const Value.absent(),
                Value<int?> opponentLevel = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                positionId: positionId,
                playedAt: playedAt,
                outcome: outcome,
                fulfilled: fulfilled,
                opponent: opponent,
                opponentLevel: opponentLevel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String positionId,
                required DateTime playedAt,
                required String outcome,
                required bool fulfilled,
                required String opponent,
                Value<int?> opponentLevel = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                positionId: positionId,
                playedAt: playedAt,
                outcome: outcome,
                fulfilled: fulfilled,
                opponent: opponent,
                opponentLevel: opponentLevel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptsTable, AttemptRow>(table),
                  BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttemptsTable,
      AttemptRow,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (AttemptRow, BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow>),
      AttemptRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
}
