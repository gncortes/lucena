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

class $GamesTable extends Games with TableInfo<$GamesTable, GameRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startFenMeta = const VerificationMeta(
    'startFen',
  );
  @override
  late final GeneratedColumn<String> startFen = GeneratedColumn<String>(
    'start_fen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movesMeta = const VerificationMeta('moves');
  @override
  late final GeneratedColumn<String> moves = GeneratedColumn<String>(
    'moves',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _endReasonMeta = const VerificationMeta(
    'endReason',
  );
  @override
  late final GeneratedColumn<String> endReason = GeneratedColumn<String>(
    'end_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moveTimesMsMeta = const VerificationMeta(
    'moveTimesMs',
  );
  @override
  late final GeneratedColumn<String> moveTimesMs = GeneratedColumn<String>(
    'move_times_ms',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _userSideMeta = const VerificationMeta(
    'userSide',
  );
  @override
  late final GeneratedColumn<String> userSide = GeneratedColumn<String>(
    'user_side',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userTimeMeta = const VerificationMeta(
    'userTime',
  );
  @override
  late final GeneratedColumn<String> userTime = GeneratedColumn<String>(
    'user_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opponentTimeMeta = const VerificationMeta(
    'opponentTime',
  );
  @override
  late final GeneratedColumn<String> opponentTime = GeneratedColumn<String>(
    'opponent_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userClockMsMeta = const VerificationMeta(
    'userClockMs',
  );
  @override
  late final GeneratedColumn<int> userClockMs = GeneratedColumn<int>(
    'user_clock_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _challengeIdMeta = const VerificationMeta(
    'challengeId',
  );
  @override
  late final GeneratedColumn<String> challengeId = GeneratedColumn<String>(
    'challenge_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedrunAttemptIdMeta = const VerificationMeta(
    'speedrunAttemptId',
  );
  @override
  late final GeneratedColumn<int> speedrunAttemptId = GeneratedColumn<int>(
    'speedrun_attempt_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedrunStageMeta = const VerificationMeta(
    'speedrunStage',
  );
  @override
  late final GeneratedColumn<int> speedrunStage = GeneratedColumn<int>(
    'speedrun_stage',
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
    startedAt,
    startFen,
    moves,
    endReason,
    moveTimesMs,
    userSide,
    userTime,
    opponentTime,
    userClockMs,
    challengeId,
    speedrunAttemptId,
    speedrunStage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameRow> instance, {
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
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('start_fen')) {
      context.handle(
        _startFenMeta,
        startFen.isAcceptableOrUnknown(data['start_fen']!, _startFenMeta),
      );
    }
    if (data.containsKey('moves')) {
      context.handle(
        _movesMeta,
        moves.isAcceptableOrUnknown(data['moves']!, _movesMeta),
      );
    }
    if (data.containsKey('end_reason')) {
      context.handle(
        _endReasonMeta,
        endReason.isAcceptableOrUnknown(data['end_reason']!, _endReasonMeta),
      );
    }
    if (data.containsKey('move_times_ms')) {
      context.handle(
        _moveTimesMsMeta,
        moveTimesMs.isAcceptableOrUnknown(
          data['move_times_ms']!,
          _moveTimesMsMeta,
        ),
      );
    }
    if (data.containsKey('user_side')) {
      context.handle(
        _userSideMeta,
        userSide.isAcceptableOrUnknown(data['user_side']!, _userSideMeta),
      );
    }
    if (data.containsKey('user_time')) {
      context.handle(
        _userTimeMeta,
        userTime.isAcceptableOrUnknown(data['user_time']!, _userTimeMeta),
      );
    }
    if (data.containsKey('opponent_time')) {
      context.handle(
        _opponentTimeMeta,
        opponentTime.isAcceptableOrUnknown(
          data['opponent_time']!,
          _opponentTimeMeta,
        ),
      );
    }
    if (data.containsKey('user_clock_ms')) {
      context.handle(
        _userClockMsMeta,
        userClockMs.isAcceptableOrUnknown(
          data['user_clock_ms']!,
          _userClockMsMeta,
        ),
      );
    }
    if (data.containsKey('challenge_id')) {
      context.handle(
        _challengeIdMeta,
        challengeId.isAcceptableOrUnknown(
          data['challenge_id']!,
          _challengeIdMeta,
        ),
      );
    }
    if (data.containsKey('speedrun_attempt_id')) {
      context.handle(
        _speedrunAttemptIdMeta,
        speedrunAttemptId.isAcceptableOrUnknown(
          data['speedrun_attempt_id']!,
          _speedrunAttemptIdMeta,
        ),
      );
    }
    if (data.containsKey('speedrun_stage')) {
      context.handle(
        _speedrunStageMeta,
        speedrunStage.isAcceptableOrUnknown(
          data['speedrun_stage']!,
          _speedrunStageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameRow(
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
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      startFen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_fen'],
      ),
      moves: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moves'],
      )!,
      endReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_reason'],
      ),
      moveTimesMs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}move_times_ms'],
      )!,
      userSide: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_side'],
      ),
      userTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_time'],
      ),
      opponentTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opponent_time'],
      ),
      userClockMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_clock_ms'],
      ),
      challengeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}challenge_id'],
      ),
      speedrunAttemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}speedrun_attempt_id'],
      ),
      speedrunStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}speedrun_stage'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class GameRow extends DataClass implements Insertable<GameRow> {
  final int id;
  final String positionId;

  /// Quando a partida terminou.
  final DateTime playedAt;

  /// `win`, `draw` ou `loss`, do ponto de vista do jogador.
  final String outcome;
  final bool fulfilled;
  final String opponent;

  /// O nível do Maia, quando ele foi o adversário.
  final int? opponentLevel;
  final DateTime? startedAt;
  final String? startFen;

  /// Os lances em UCI, separados por espaço.
  final String moves;
  final String? endReason;

  /// Quanto cada lance levou, em milissegundos, separados por espaço. Vazio
  /// nas partidas de antes da versão 6.
  final String moveTimesMs;

  /// O lado do jogador (`white` ou `black`). Nulo antes da versão 6.
  final String? userSide;

  /// O tempo de cada lado (`segundos+incremento`).
  final String? userTime;
  final String? opponentTime;

  /// Quanto o relógio do jogador gastou, em milissegundos.
  final int? userClockMs;
  final String? challengeId;
  final int? speedrunAttemptId;
  final int? speedrunStage;
  const GameRow({
    required this.id,
    required this.positionId,
    required this.playedAt,
    required this.outcome,
    required this.fulfilled,
    required this.opponent,
    this.opponentLevel,
    this.startedAt,
    this.startFen,
    required this.moves,
    this.endReason,
    required this.moveTimesMs,
    this.userSide,
    this.userTime,
    this.opponentTime,
    this.userClockMs,
    this.challengeId,
    this.speedrunAttemptId,
    this.speedrunStage,
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
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || startFen != null) {
      map['start_fen'] = Variable<String>(startFen);
    }
    map['moves'] = Variable<String>(moves);
    if (!nullToAbsent || endReason != null) {
      map['end_reason'] = Variable<String>(endReason);
    }
    map['move_times_ms'] = Variable<String>(moveTimesMs);
    if (!nullToAbsent || userSide != null) {
      map['user_side'] = Variable<String>(userSide);
    }
    if (!nullToAbsent || userTime != null) {
      map['user_time'] = Variable<String>(userTime);
    }
    if (!nullToAbsent || opponentTime != null) {
      map['opponent_time'] = Variable<String>(opponentTime);
    }
    if (!nullToAbsent || userClockMs != null) {
      map['user_clock_ms'] = Variable<int>(userClockMs);
    }
    if (!nullToAbsent || challengeId != null) {
      map['challenge_id'] = Variable<String>(challengeId);
    }
    if (!nullToAbsent || speedrunAttemptId != null) {
      map['speedrun_attempt_id'] = Variable<int>(speedrunAttemptId);
    }
    if (!nullToAbsent || speedrunStage != null) {
      map['speedrun_stage'] = Variable<int>(speedrunStage);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      positionId: Value(positionId),
      playedAt: Value(playedAt),
      outcome: Value(outcome),
      fulfilled: Value(fulfilled),
      opponent: Value(opponent),
      opponentLevel: opponentLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(opponentLevel),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      startFen: startFen == null && nullToAbsent
          ? const Value.absent()
          : Value(startFen),
      moves: Value(moves),
      endReason: endReason == null && nullToAbsent
          ? const Value.absent()
          : Value(endReason),
      moveTimesMs: Value(moveTimesMs),
      userSide: userSide == null && nullToAbsent
          ? const Value.absent()
          : Value(userSide),
      userTime: userTime == null && nullToAbsent
          ? const Value.absent()
          : Value(userTime),
      opponentTime: opponentTime == null && nullToAbsent
          ? const Value.absent()
          : Value(opponentTime),
      userClockMs: userClockMs == null && nullToAbsent
          ? const Value.absent()
          : Value(userClockMs),
      challengeId: challengeId == null && nullToAbsent
          ? const Value.absent()
          : Value(challengeId),
      speedrunAttemptId: speedrunAttemptId == null && nullToAbsent
          ? const Value.absent()
          : Value(speedrunAttemptId),
      speedrunStage: speedrunStage == null && nullToAbsent
          ? const Value.absent()
          : Value(speedrunStage),
    );
  }

  factory GameRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameRow(
      id: serializer.fromJson<int>(json['id']),
      positionId: serializer.fromJson<String>(json['positionId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      outcome: serializer.fromJson<String>(json['outcome']),
      fulfilled: serializer.fromJson<bool>(json['fulfilled']),
      opponent: serializer.fromJson<String>(json['opponent']),
      opponentLevel: serializer.fromJson<int?>(json['opponentLevel']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      startFen: serializer.fromJson<String?>(json['startFen']),
      moves: serializer.fromJson<String>(json['moves']),
      endReason: serializer.fromJson<String?>(json['endReason']),
      moveTimesMs: serializer.fromJson<String>(json['moveTimesMs']),
      userSide: serializer.fromJson<String?>(json['userSide']),
      userTime: serializer.fromJson<String?>(json['userTime']),
      opponentTime: serializer.fromJson<String?>(json['opponentTime']),
      userClockMs: serializer.fromJson<int?>(json['userClockMs']),
      challengeId: serializer.fromJson<String?>(json['challengeId']),
      speedrunAttemptId: serializer.fromJson<int?>(json['speedrunAttemptId']),
      speedrunStage: serializer.fromJson<int?>(json['speedrunStage']),
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
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'startFen': serializer.toJson<String?>(startFen),
      'moves': serializer.toJson<String>(moves),
      'endReason': serializer.toJson<String?>(endReason),
      'moveTimesMs': serializer.toJson<String>(moveTimesMs),
      'userSide': serializer.toJson<String?>(userSide),
      'userTime': serializer.toJson<String?>(userTime),
      'opponentTime': serializer.toJson<String?>(opponentTime),
      'userClockMs': serializer.toJson<int?>(userClockMs),
      'challengeId': serializer.toJson<String?>(challengeId),
      'speedrunAttemptId': serializer.toJson<int?>(speedrunAttemptId),
      'speedrunStage': serializer.toJson<int?>(speedrunStage),
    };
  }

  GameRow copyWith({
    int? id,
    String? positionId,
    DateTime? playedAt,
    String? outcome,
    bool? fulfilled,
    String? opponent,
    Value<int?> opponentLevel = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<String?> startFen = const Value.absent(),
    String? moves,
    Value<String?> endReason = const Value.absent(),
    String? moveTimesMs,
    Value<String?> userSide = const Value.absent(),
    Value<String?> userTime = const Value.absent(),
    Value<String?> opponentTime = const Value.absent(),
    Value<int?> userClockMs = const Value.absent(),
    Value<String?> challengeId = const Value.absent(),
    Value<int?> speedrunAttemptId = const Value.absent(),
    Value<int?> speedrunStage = const Value.absent(),
  }) => GameRow(
    id: id ?? this.id,
    positionId: positionId ?? this.positionId,
    playedAt: playedAt ?? this.playedAt,
    outcome: outcome ?? this.outcome,
    fulfilled: fulfilled ?? this.fulfilled,
    opponent: opponent ?? this.opponent,
    opponentLevel: opponentLevel.present
        ? opponentLevel.value
        : this.opponentLevel,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    startFen: startFen.present ? startFen.value : this.startFen,
    moves: moves ?? this.moves,
    endReason: endReason.present ? endReason.value : this.endReason,
    moveTimesMs: moveTimesMs ?? this.moveTimesMs,
    userSide: userSide.present ? userSide.value : this.userSide,
    userTime: userTime.present ? userTime.value : this.userTime,
    opponentTime: opponentTime.present ? opponentTime.value : this.opponentTime,
    userClockMs: userClockMs.present ? userClockMs.value : this.userClockMs,
    challengeId: challengeId.present ? challengeId.value : this.challengeId,
    speedrunAttemptId: speedrunAttemptId.present
        ? speedrunAttemptId.value
        : this.speedrunAttemptId,
    speedrunStage: speedrunStage.present
        ? speedrunStage.value
        : this.speedrunStage,
  );
  GameRow copyWithCompanion(GamesCompanion data) {
    return GameRow(
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
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      startFen: data.startFen.present ? data.startFen.value : this.startFen,
      moves: data.moves.present ? data.moves.value : this.moves,
      endReason: data.endReason.present ? data.endReason.value : this.endReason,
      moveTimesMs: data.moveTimesMs.present
          ? data.moveTimesMs.value
          : this.moveTimesMs,
      userSide: data.userSide.present ? data.userSide.value : this.userSide,
      userTime: data.userTime.present ? data.userTime.value : this.userTime,
      opponentTime: data.opponentTime.present
          ? data.opponentTime.value
          : this.opponentTime,
      userClockMs: data.userClockMs.present
          ? data.userClockMs.value
          : this.userClockMs,
      challengeId: data.challengeId.present
          ? data.challengeId.value
          : this.challengeId,
      speedrunAttemptId: data.speedrunAttemptId.present
          ? data.speedrunAttemptId.value
          : this.speedrunAttemptId,
      speedrunStage: data.speedrunStage.present
          ? data.speedrunStage.value
          : this.speedrunStage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameRow(')
          ..write('id: $id, ')
          ..write('positionId: $positionId, ')
          ..write('playedAt: $playedAt, ')
          ..write('outcome: $outcome, ')
          ..write('fulfilled: $fulfilled, ')
          ..write('opponent: $opponent, ')
          ..write('opponentLevel: $opponentLevel, ')
          ..write('startedAt: $startedAt, ')
          ..write('startFen: $startFen, ')
          ..write('moves: $moves, ')
          ..write('endReason: $endReason, ')
          ..write('moveTimesMs: $moveTimesMs, ')
          ..write('userSide: $userSide, ')
          ..write('userTime: $userTime, ')
          ..write('opponentTime: $opponentTime, ')
          ..write('userClockMs: $userClockMs, ')
          ..write('challengeId: $challengeId, ')
          ..write('speedrunAttemptId: $speedrunAttemptId, ')
          ..write('speedrunStage: $speedrunStage')
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
    startedAt,
    startFen,
    moves,
    endReason,
    moveTimesMs,
    userSide,
    userTime,
    opponentTime,
    userClockMs,
    challengeId,
    speedrunAttemptId,
    speedrunStage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameRow &&
          other.id == this.id &&
          other.positionId == this.positionId &&
          other.playedAt == this.playedAt &&
          other.outcome == this.outcome &&
          other.fulfilled == this.fulfilled &&
          other.opponent == this.opponent &&
          other.opponentLevel == this.opponentLevel &&
          other.startedAt == this.startedAt &&
          other.startFen == this.startFen &&
          other.moves == this.moves &&
          other.endReason == this.endReason &&
          other.moveTimesMs == this.moveTimesMs &&
          other.userSide == this.userSide &&
          other.userTime == this.userTime &&
          other.opponentTime == this.opponentTime &&
          other.userClockMs == this.userClockMs &&
          other.challengeId == this.challengeId &&
          other.speedrunAttemptId == this.speedrunAttemptId &&
          other.speedrunStage == this.speedrunStage);
}

class GamesCompanion extends UpdateCompanion<GameRow> {
  final Value<int> id;
  final Value<String> positionId;
  final Value<DateTime> playedAt;
  final Value<String> outcome;
  final Value<bool> fulfilled;
  final Value<String> opponent;
  final Value<int?> opponentLevel;
  final Value<DateTime?> startedAt;
  final Value<String?> startFen;
  final Value<String> moves;
  final Value<String?> endReason;
  final Value<String> moveTimesMs;
  final Value<String?> userSide;
  final Value<String?> userTime;
  final Value<String?> opponentTime;
  final Value<int?> userClockMs;
  final Value<String?> challengeId;
  final Value<int?> speedrunAttemptId;
  final Value<int?> speedrunStage;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.positionId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.fulfilled = const Value.absent(),
    this.opponent = const Value.absent(),
    this.opponentLevel = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.startFen = const Value.absent(),
    this.moves = const Value.absent(),
    this.endReason = const Value.absent(),
    this.moveTimesMs = const Value.absent(),
    this.userSide = const Value.absent(),
    this.userTime = const Value.absent(),
    this.opponentTime = const Value.absent(),
    this.userClockMs = const Value.absent(),
    this.challengeId = const Value.absent(),
    this.speedrunAttemptId = const Value.absent(),
    this.speedrunStage = const Value.absent(),
  });
  GamesCompanion.insert({
    this.id = const Value.absent(),
    required String positionId,
    required DateTime playedAt,
    required String outcome,
    required bool fulfilled,
    required String opponent,
    this.opponentLevel = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.startFen = const Value.absent(),
    this.moves = const Value.absent(),
    this.endReason = const Value.absent(),
    this.moveTimesMs = const Value.absent(),
    this.userSide = const Value.absent(),
    this.userTime = const Value.absent(),
    this.opponentTime = const Value.absent(),
    this.userClockMs = const Value.absent(),
    this.challengeId = const Value.absent(),
    this.speedrunAttemptId = const Value.absent(),
    this.speedrunStage = const Value.absent(),
  }) : positionId = Value(positionId),
       playedAt = Value(playedAt),
       outcome = Value(outcome),
       fulfilled = Value(fulfilled),
       opponent = Value(opponent);
  static Insertable<GameRow> custom({
    Expression<int>? id,
    Expression<String>? positionId,
    Expression<DateTime>? playedAt,
    Expression<String>? outcome,
    Expression<bool>? fulfilled,
    Expression<String>? opponent,
    Expression<int>? opponentLevel,
    Expression<DateTime>? startedAt,
    Expression<String>? startFen,
    Expression<String>? moves,
    Expression<String>? endReason,
    Expression<String>? moveTimesMs,
    Expression<String>? userSide,
    Expression<String>? userTime,
    Expression<String>? opponentTime,
    Expression<int>? userClockMs,
    Expression<String>? challengeId,
    Expression<int>? speedrunAttemptId,
    Expression<int>? speedrunStage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (positionId != null) 'position_id': positionId,
      if (playedAt != null) 'played_at': playedAt,
      if (outcome != null) 'outcome': outcome,
      if (fulfilled != null) 'fulfilled': fulfilled,
      if (opponent != null) 'opponent': opponent,
      if (opponentLevel != null) 'opponent_level': opponentLevel,
      if (startedAt != null) 'started_at': startedAt,
      if (startFen != null) 'start_fen': startFen,
      if (moves != null) 'moves': moves,
      if (endReason != null) 'end_reason': endReason,
      if (moveTimesMs != null) 'move_times_ms': moveTimesMs,
      if (userSide != null) 'user_side': userSide,
      if (userTime != null) 'user_time': userTime,
      if (opponentTime != null) 'opponent_time': opponentTime,
      if (userClockMs != null) 'user_clock_ms': userClockMs,
      if (challengeId != null) 'challenge_id': challengeId,
      if (speedrunAttemptId != null) 'speedrun_attempt_id': speedrunAttemptId,
      if (speedrunStage != null) 'speedrun_stage': speedrunStage,
    });
  }

  GamesCompanion copyWith({
    Value<int>? id,
    Value<String>? positionId,
    Value<DateTime>? playedAt,
    Value<String>? outcome,
    Value<bool>? fulfilled,
    Value<String>? opponent,
    Value<int?>? opponentLevel,
    Value<DateTime?>? startedAt,
    Value<String?>? startFen,
    Value<String>? moves,
    Value<String?>? endReason,
    Value<String>? moveTimesMs,
    Value<String?>? userSide,
    Value<String?>? userTime,
    Value<String?>? opponentTime,
    Value<int?>? userClockMs,
    Value<String?>? challengeId,
    Value<int?>? speedrunAttemptId,
    Value<int?>? speedrunStage,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      positionId: positionId ?? this.positionId,
      playedAt: playedAt ?? this.playedAt,
      outcome: outcome ?? this.outcome,
      fulfilled: fulfilled ?? this.fulfilled,
      opponent: opponent ?? this.opponent,
      opponentLevel: opponentLevel ?? this.opponentLevel,
      startedAt: startedAt ?? this.startedAt,
      startFen: startFen ?? this.startFen,
      moves: moves ?? this.moves,
      endReason: endReason ?? this.endReason,
      moveTimesMs: moveTimesMs ?? this.moveTimesMs,
      userSide: userSide ?? this.userSide,
      userTime: userTime ?? this.userTime,
      opponentTime: opponentTime ?? this.opponentTime,
      userClockMs: userClockMs ?? this.userClockMs,
      challengeId: challengeId ?? this.challengeId,
      speedrunAttemptId: speedrunAttemptId ?? this.speedrunAttemptId,
      speedrunStage: speedrunStage ?? this.speedrunStage,
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (startFen.present) {
      map['start_fen'] = Variable<String>(startFen.value);
    }
    if (moves.present) {
      map['moves'] = Variable<String>(moves.value);
    }
    if (endReason.present) {
      map['end_reason'] = Variable<String>(endReason.value);
    }
    if (moveTimesMs.present) {
      map['move_times_ms'] = Variable<String>(moveTimesMs.value);
    }
    if (userSide.present) {
      map['user_side'] = Variable<String>(userSide.value);
    }
    if (userTime.present) {
      map['user_time'] = Variable<String>(userTime.value);
    }
    if (opponentTime.present) {
      map['opponent_time'] = Variable<String>(opponentTime.value);
    }
    if (userClockMs.present) {
      map['user_clock_ms'] = Variable<int>(userClockMs.value);
    }
    if (challengeId.present) {
      map['challenge_id'] = Variable<String>(challengeId.value);
    }
    if (speedrunAttemptId.present) {
      map['speedrun_attempt_id'] = Variable<int>(speedrunAttemptId.value);
    }
    if (speedrunStage.present) {
      map['speedrun_stage'] = Variable<int>(speedrunStage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('positionId: $positionId, ')
          ..write('playedAt: $playedAt, ')
          ..write('outcome: $outcome, ')
          ..write('fulfilled: $fulfilled, ')
          ..write('opponent: $opponent, ')
          ..write('opponentLevel: $opponentLevel, ')
          ..write('startedAt: $startedAt, ')
          ..write('startFen: $startFen, ')
          ..write('moves: $moves, ')
          ..write('endReason: $endReason, ')
          ..write('moveTimesMs: $moveTimesMs, ')
          ..write('userSide: $userSide, ')
          ..write('userTime: $userTime, ')
          ..write('opponentTime: $opponentTime, ')
          ..write('userClockMs: $userClockMs, ')
          ..write('challengeId: $challengeId, ')
          ..write('speedrunAttemptId: $speedrunAttemptId, ')
          ..write('speedrunStage: $speedrunStage')
          ..write(')'))
        .toString();
  }
}

class $SpeedrunAttemptsTable extends SpeedrunAttempts
    with TableInfo<$SpeedrunAttemptsTable, SpeedrunAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeedrunAttemptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _speedrunIdMeta = const VerificationMeta(
    'speedrunId',
  );
  @override
  late final GeneratedColumn<String> speedrunId = GeneratedColumn<String>(
    'speedrun_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _abandonedAtMeta = const VerificationMeta(
    'abandonedAt',
  );
  @override
  late final GeneratedColumn<DateTime> abandonedAt = GeneratedColumn<DateTime>(
    'abandoned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    speedrunId,
    startedAt,
    abandonedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'speedrun_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpeedrunAttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('speedrun_id')) {
      context.handle(
        _speedrunIdMeta,
        speedrunId.isAcceptableOrUnknown(data['speedrun_id']!, _speedrunIdMeta),
      );
    } else if (isInserting) {
      context.missing(_speedrunIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('abandoned_at')) {
      context.handle(
        _abandonedAtMeta,
        abandonedAt.isAcceptableOrUnknown(
          data['abandoned_at']!,
          _abandonedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpeedrunAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpeedrunAttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      speedrunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}speedrun_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      abandonedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}abandoned_at'],
      ),
    );
  }

  @override
  $SpeedrunAttemptsTable createAlias(String alias) {
    return $SpeedrunAttemptsTable(attachedDatabase, alias);
  }
}

class SpeedrunAttemptRow extends DataClass
    implements Insertable<SpeedrunAttemptRow> {
  final int id;
  final String speedrunId;
  final DateTime startedAt;
  final DateTime? abandonedAt;
  const SpeedrunAttemptRow({
    required this.id,
    required this.speedrunId,
    required this.startedAt,
    this.abandonedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['speedrun_id'] = Variable<String>(speedrunId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || abandonedAt != null) {
      map['abandoned_at'] = Variable<DateTime>(abandonedAt);
    }
    return map;
  }

  SpeedrunAttemptsCompanion toCompanion(bool nullToAbsent) {
    return SpeedrunAttemptsCompanion(
      id: Value(id),
      speedrunId: Value(speedrunId),
      startedAt: Value(startedAt),
      abandonedAt: abandonedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(abandonedAt),
    );
  }

  factory SpeedrunAttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpeedrunAttemptRow(
      id: serializer.fromJson<int>(json['id']),
      speedrunId: serializer.fromJson<String>(json['speedrunId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      abandonedAt: serializer.fromJson<DateTime?>(json['abandonedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'speedrunId': serializer.toJson<String>(speedrunId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'abandonedAt': serializer.toJson<DateTime?>(abandonedAt),
    };
  }

  SpeedrunAttemptRow copyWith({
    int? id,
    String? speedrunId,
    DateTime? startedAt,
    Value<DateTime?> abandonedAt = const Value.absent(),
  }) => SpeedrunAttemptRow(
    id: id ?? this.id,
    speedrunId: speedrunId ?? this.speedrunId,
    startedAt: startedAt ?? this.startedAt,
    abandonedAt: abandonedAt.present ? abandonedAt.value : this.abandonedAt,
  );
  SpeedrunAttemptRow copyWithCompanion(SpeedrunAttemptsCompanion data) {
    return SpeedrunAttemptRow(
      id: data.id.present ? data.id.value : this.id,
      speedrunId: data.speedrunId.present
          ? data.speedrunId.value
          : this.speedrunId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      abandonedAt: data.abandonedAt.present
          ? data.abandonedAt.value
          : this.abandonedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpeedrunAttemptRow(')
          ..write('id: $id, ')
          ..write('speedrunId: $speedrunId, ')
          ..write('startedAt: $startedAt, ')
          ..write('abandonedAt: $abandonedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, speedrunId, startedAt, abandonedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeedrunAttemptRow &&
          other.id == this.id &&
          other.speedrunId == this.speedrunId &&
          other.startedAt == this.startedAt &&
          other.abandonedAt == this.abandonedAt);
}

class SpeedrunAttemptsCompanion extends UpdateCompanion<SpeedrunAttemptRow> {
  final Value<int> id;
  final Value<String> speedrunId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> abandonedAt;
  const SpeedrunAttemptsCompanion({
    this.id = const Value.absent(),
    this.speedrunId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.abandonedAt = const Value.absent(),
  });
  SpeedrunAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String speedrunId,
    required DateTime startedAt,
    this.abandonedAt = const Value.absent(),
  }) : speedrunId = Value(speedrunId),
       startedAt = Value(startedAt);
  static Insertable<SpeedrunAttemptRow> custom({
    Expression<int>? id,
    Expression<String>? speedrunId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? abandonedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (speedrunId != null) 'speedrun_id': speedrunId,
      if (startedAt != null) 'started_at': startedAt,
      if (abandonedAt != null) 'abandoned_at': abandonedAt,
    });
  }

  SpeedrunAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? speedrunId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? abandonedAt,
  }) {
    return SpeedrunAttemptsCompanion(
      id: id ?? this.id,
      speedrunId: speedrunId ?? this.speedrunId,
      startedAt: startedAt ?? this.startedAt,
      abandonedAt: abandonedAt ?? this.abandonedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (speedrunId.present) {
      map['speedrun_id'] = Variable<String>(speedrunId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (abandonedAt.present) {
      map['abandoned_at'] = Variable<DateTime>(abandonedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeedrunAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('speedrunId: $speedrunId, ')
          ..write('startedAt: $startedAt, ')
          ..write('abandonedAt: $abandonedAt')
          ..write(')'))
        .toString();
  }
}

class $RatingHistoryTable extends RatingHistory
    with TableInfo<$RatingHistoryTable, RatingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviationMeta = const VerificationMeta(
    'deviation',
  );
  @override
  late final GeneratedColumn<double> deviation = GeneratedColumn<double>(
    'deviation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volatilityMeta = const VerificationMeta(
    'volatility',
  );
  @override
  late final GeneratedColumn<double> volatility = GeneratedColumn<double>(
    'volatility',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    at,
    rating,
    deviation,
    volatility,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rating_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<RatingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('deviation')) {
      context.handle(
        _deviationMeta,
        deviation.isAcceptableOrUnknown(data['deviation']!, _deviationMeta),
      );
    } else if (isInserting) {
      context.missing(_deviationMeta);
    }
    if (data.containsKey('volatility')) {
      context.handle(
        _volatilityMeta,
        volatility.isAcceptableOrUnknown(data['volatility']!, _volatilityMeta),
      );
    } else if (isInserting) {
      context.missing(_volatilityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RatingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      deviation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deviation'],
      )!,
      volatility: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volatility'],
      )!,
    );
  }

  @override
  $RatingHistoryTable createAlias(String alias) {
    return $RatingHistoryTable(attachedDatabase, alias);
  }
}

class RatingRow extends DataClass implements Insertable<RatingRow> {
  final int id;

  /// A partida que mudou o rating.
  final int? gameId;
  final DateTime at;
  final double rating;
  final double deviation;
  final double volatility;
  const RatingRow({
    required this.id,
    this.gameId,
    required this.at,
    required this.rating,
    required this.deviation,
    required this.volatility,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || gameId != null) {
      map['game_id'] = Variable<int>(gameId);
    }
    map['at'] = Variable<DateTime>(at);
    map['rating'] = Variable<double>(rating);
    map['deviation'] = Variable<double>(deviation);
    map['volatility'] = Variable<double>(volatility);
    return map;
  }

  RatingHistoryCompanion toCompanion(bool nullToAbsent) {
    return RatingHistoryCompanion(
      id: Value(id),
      gameId: gameId == null && nullToAbsent
          ? const Value.absent()
          : Value(gameId),
      at: Value(at),
      rating: Value(rating),
      deviation: Value(deviation),
      volatility: Value(volatility),
    );
  }

  factory RatingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatingRow(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int?>(json['gameId']),
      at: serializer.fromJson<DateTime>(json['at']),
      rating: serializer.fromJson<double>(json['rating']),
      deviation: serializer.fromJson<double>(json['deviation']),
      volatility: serializer.fromJson<double>(json['volatility']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int?>(gameId),
      'at': serializer.toJson<DateTime>(at),
      'rating': serializer.toJson<double>(rating),
      'deviation': serializer.toJson<double>(deviation),
      'volatility': serializer.toJson<double>(volatility),
    };
  }

  RatingRow copyWith({
    int? id,
    Value<int?> gameId = const Value.absent(),
    DateTime? at,
    double? rating,
    double? deviation,
    double? volatility,
  }) => RatingRow(
    id: id ?? this.id,
    gameId: gameId.present ? gameId.value : this.gameId,
    at: at ?? this.at,
    rating: rating ?? this.rating,
    deviation: deviation ?? this.deviation,
    volatility: volatility ?? this.volatility,
  );
  RatingRow copyWithCompanion(RatingHistoryCompanion data) {
    return RatingRow(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      at: data.at.present ? data.at.value : this.at,
      rating: data.rating.present ? data.rating.value : this.rating,
      deviation: data.deviation.present ? data.deviation.value : this.deviation,
      volatility: data.volatility.present
          ? data.volatility.value
          : this.volatility,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatingRow(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('at: $at, ')
          ..write('rating: $rating, ')
          ..write('deviation: $deviation, ')
          ..write('volatility: $volatility')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameId, at, rating, deviation, volatility);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingRow &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.at == this.at &&
          other.rating == this.rating &&
          other.deviation == this.deviation &&
          other.volatility == this.volatility);
}

class RatingHistoryCompanion extends UpdateCompanion<RatingRow> {
  final Value<int> id;
  final Value<int?> gameId;
  final Value<DateTime> at;
  final Value<double> rating;
  final Value<double> deviation;
  final Value<double> volatility;
  const RatingHistoryCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.at = const Value.absent(),
    this.rating = const Value.absent(),
    this.deviation = const Value.absent(),
    this.volatility = const Value.absent(),
  });
  RatingHistoryCompanion.insert({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    required DateTime at,
    required double rating,
    required double deviation,
    required double volatility,
  }) : at = Value(at),
       rating = Value(rating),
       deviation = Value(deviation),
       volatility = Value(volatility);
  static Insertable<RatingRow> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<DateTime>? at,
    Expression<double>? rating,
    Expression<double>? deviation,
    Expression<double>? volatility,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (at != null) 'at': at,
      if (rating != null) 'rating': rating,
      if (deviation != null) 'deviation': deviation,
      if (volatility != null) 'volatility': volatility,
    });
  }

  RatingHistoryCompanion copyWith({
    Value<int>? id,
    Value<int?>? gameId,
    Value<DateTime>? at,
    Value<double>? rating,
    Value<double>? deviation,
    Value<double>? volatility,
  }) {
    return RatingHistoryCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      at: at ?? this.at,
      rating: rating ?? this.rating,
      deviation: deviation ?? this.deviation,
      volatility: volatility ?? this.volatility,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (deviation.present) {
      map['deviation'] = Variable<double>(deviation.value);
    }
    if (volatility.present) {
      map['volatility'] = Variable<double>(volatility.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatingHistoryCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('at: $at, ')
          ..write('rating: $rating, ')
          ..write('deviation: $deviation, ')
          ..write('volatility: $volatility')
          ..write(')'))
        .toString();
  }
}

class $UnlockedAchievementsTable extends UnlockedAchievements
    with TableInfo<$UnlockedAchievementsTable, UnlockedAchievementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnlockedAchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _achievementIdMeta = const VerificationMeta(
    'achievementId',
  );
  @override
  late final GeneratedColumn<String> achievementId = GeneratedColumn<String>(
    'achievement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [achievementId, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unlocked_achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnlockedAchievementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('achievement_id')) {
      context.handle(
        _achievementIdMeta,
        achievementId.isAcceptableOrUnknown(
          data['achievement_id']!,
          _achievementIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_achievementIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {achievementId};
  @override
  UnlockedAchievementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnlockedAchievementRow(
      achievementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}achievement_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $UnlockedAchievementsTable createAlias(String alias) {
    return $UnlockedAchievementsTable(attachedDatabase, alias);
  }
}

class UnlockedAchievementRow extends DataClass
    implements Insertable<UnlockedAchievementRow> {
  final String achievementId;
  final DateTime at;
  const UnlockedAchievementRow({required this.achievementId, required this.at});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['achievement_id'] = Variable<String>(achievementId);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  UnlockedAchievementsCompanion toCompanion(bool nullToAbsent) {
    return UnlockedAchievementsCompanion(
      achievementId: Value(achievementId),
      at: Value(at),
    );
  }

  factory UnlockedAchievementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnlockedAchievementRow(
      achievementId: serializer.fromJson<String>(json['achievementId']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'achievementId': serializer.toJson<String>(achievementId),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  UnlockedAchievementRow copyWith({String? achievementId, DateTime? at}) =>
      UnlockedAchievementRow(
        achievementId: achievementId ?? this.achievementId,
        at: at ?? this.at,
      );
  UnlockedAchievementRow copyWithCompanion(UnlockedAchievementsCompanion data) {
    return UnlockedAchievementRow(
      achievementId: data.achievementId.present
          ? data.achievementId.value
          : this.achievementId,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnlockedAchievementRow(')
          ..write('achievementId: $achievementId, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(achievementId, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnlockedAchievementRow &&
          other.achievementId == this.achievementId &&
          other.at == this.at);
}

class UnlockedAchievementsCompanion
    extends UpdateCompanion<UnlockedAchievementRow> {
  final Value<String> achievementId;
  final Value<DateTime> at;
  final Value<int> rowid;
  const UnlockedAchievementsCompanion({
    this.achievementId = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnlockedAchievementsCompanion.insert({
    required String achievementId,
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : achievementId = Value(achievementId),
       at = Value(at);
  static Insertable<UnlockedAchievementRow> custom({
    Expression<String>? achievementId,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (achievementId != null) 'achievement_id': achievementId,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnlockedAchievementsCompanion copyWith({
    Value<String>? achievementId,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return UnlockedAchievementsCompanion(
      achievementId: achievementId ?? this.achievementId,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (achievementId.present) {
      map['achievement_id'] = Variable<String>(achievementId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnlockedAchievementsCompanion(')
          ..write('achievementId: $achievementId, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $GamesTable games = $GamesTable(this);
  late final $SpeedrunAttemptsTable speedrunAttempts = $SpeedrunAttemptsTable(
    this,
  );
  late final $RatingHistoryTable ratingHistory = $RatingHistoryTable(this);
  late final $UnlockedAchievementsTable unlockedAchievements =
      $UnlockedAchievementsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    games,
    speedrunAttempts,
    ratingHistory,
    unlockedAchievements,
  ];
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
typedef $$GamesTableCreateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  required String positionId,
  required DateTime playedAt,
  required String outcome,
  required bool fulfilled,
  required String opponent,
  Value<int?> opponentLevel,
  Value<DateTime?> startedAt,
  Value<String?> startFen,
  Value<String> moves,
  Value<String?> endReason,
  Value<String> moveTimesMs,
  Value<String?> userSide,
  Value<String?> userTime,
  Value<String?> opponentTime,
  Value<int?> userClockMs,
  Value<String?> challengeId,
  Value<int?> speedrunAttemptId,
  Value<int?> speedrunStage,
});
typedef $$GamesTableUpdateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  Value<String> positionId,
  Value<DateTime> playedAt,
  Value<String> outcome,
  Value<bool> fulfilled,
  Value<String> opponent,
  Value<int?> opponentLevel,
  Value<DateTime?> startedAt,
  Value<String?> startFen,
  Value<String> moves,
  Value<String?> endReason,
  Value<String> moveTimesMs,
  Value<String?> userSide,
  Value<String?> userTime,
  Value<String?> opponentTime,
  Value<int?> userClockMs,
  Value<String?> challengeId,
  Value<int?> speedrunAttemptId,
  Value<int?> speedrunStage,
});

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startFen => $composableBuilder(
    column: $table.startFen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moveTimesMs => $composableBuilder(
    column: $table.moveTimesMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userSide => $composableBuilder(
    column: $table.userSide,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userTime => $composableBuilder(
    column: $table.userTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opponentTime => $composableBuilder(
    column: $table.opponentTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userClockMs => $composableBuilder(
    column: $table.userClockMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get speedrunAttemptId => $composableBuilder(
    column: $table.speedrunAttemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get speedrunStage => $composableBuilder(
    column: $table.speedrunStage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startFen => $composableBuilder(
    column: $table.startFen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moveTimesMs => $composableBuilder(
    column: $table.moveTimesMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userSide => $composableBuilder(
    column: $table.userSide,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userTime => $composableBuilder(
    column: $table.userTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opponentTime => $composableBuilder(
    column: $table.opponentTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userClockMs => $composableBuilder(
    column: $table.userClockMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get speedrunAttemptId => $composableBuilder(
    column: $table.speedrunAttemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get speedrunStage => $composableBuilder(
    column: $table.speedrunStage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get startFen =>
      $composableBuilder(column: $table.startFen, builder: (column) => column);

  GeneratedColumn<String> get moves =>
      $composableBuilder(column: $table.moves, builder: (column) => column);

  GeneratedColumn<String> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => column);

  GeneratedColumn<String> get moveTimesMs => $composableBuilder(
    column: $table.moveTimesMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userSide =>
      $composableBuilder(column: $table.userSide, builder: (column) => column);

  GeneratedColumn<String> get userTime =>
      $composableBuilder(column: $table.userTime, builder: (column) => column);

  GeneratedColumn<String> get opponentTime => $composableBuilder(
    column: $table.opponentTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userClockMs => $composableBuilder(
    column: $table.userClockMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get speedrunAttemptId => $composableBuilder(
    column: $table.speedrunAttemptId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get speedrunStage => $composableBuilder(
    column: $table.speedrunStage,
    builder: (column) => column,
  );
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          GameRow,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (GameRow, BaseReferences<_$AppDatabase, $GamesTable, GameRow>),
          GameRow,
          PrefetchHooks Function()
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> positionId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<bool> fulfilled = const Value.absent(),
                Value<String> opponent = const Value.absent(),
                Value<int?> opponentLevel = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<String?> startFen = const Value.absent(),
                Value<String> moves = const Value.absent(),
                Value<String?> endReason = const Value.absent(),
                Value<String> moveTimesMs = const Value.absent(),
                Value<String?> userSide = const Value.absent(),
                Value<String?> userTime = const Value.absent(),
                Value<String?> opponentTime = const Value.absent(),
                Value<int?> userClockMs = const Value.absent(),
                Value<String?> challengeId = const Value.absent(),
                Value<int?> speedrunAttemptId = const Value.absent(),
                Value<int?> speedrunStage = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                positionId: positionId,
                playedAt: playedAt,
                outcome: outcome,
                fulfilled: fulfilled,
                opponent: opponent,
                opponentLevel: opponentLevel,
                startedAt: startedAt,
                startFen: startFen,
                moves: moves,
                endReason: endReason,
                moveTimesMs: moveTimesMs,
                userSide: userSide,
                userTime: userTime,
                opponentTime: opponentTime,
                userClockMs: userClockMs,
                challengeId: challengeId,
                speedrunAttemptId: speedrunAttemptId,
                speedrunStage: speedrunStage,
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
                Value<DateTime?> startedAt = const Value.absent(),
                Value<String?> startFen = const Value.absent(),
                Value<String> moves = const Value.absent(),
                Value<String?> endReason = const Value.absent(),
                Value<String> moveTimesMs = const Value.absent(),
                Value<String?> userSide = const Value.absent(),
                Value<String?> userTime = const Value.absent(),
                Value<String?> opponentTime = const Value.absent(),
                Value<int?> userClockMs = const Value.absent(),
                Value<String?> challengeId = const Value.absent(),
                Value<int?> speedrunAttemptId = const Value.absent(),
                Value<int?> speedrunStage = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                positionId: positionId,
                playedAt: playedAt,
                outcome: outcome,
                fulfilled: fulfilled,
                opponent: opponent,
                opponentLevel: opponentLevel,
                startedAt: startedAt,
                startFen: startFen,
                moves: moves,
                endReason: endReason,
                moveTimesMs: moveTimesMs,
                userSide: userSide,
                userTime: userTime,
                opponentTime: opponentTime,
                userClockMs: userClockMs,
                challengeId: challengeId,
                speedrunAttemptId: speedrunAttemptId,
                speedrunStage: speedrunStage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GamesTable, GameRow>(table),
                  BaseReferences<_$AppDatabase, $GamesTable, GameRow>(
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

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      GameRow,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (GameRow, BaseReferences<_$AppDatabase, $GamesTable, GameRow>),
      GameRow,
      PrefetchHooks Function()
    >;
typedef $$SpeedrunAttemptsTableCreateCompanionBuilder =
    SpeedrunAttemptsCompanion Function({
      Value<int> id,
      required String speedrunId,
      required DateTime startedAt,
      Value<DateTime?> abandonedAt,
    });
typedef $$SpeedrunAttemptsTableUpdateCompanionBuilder =
    SpeedrunAttemptsCompanion Function({
      Value<int> id,
      Value<String> speedrunId,
      Value<DateTime> startedAt,
      Value<DateTime?> abandonedAt,
    });

class $$SpeedrunAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $SpeedrunAttemptsTable> {
  $$SpeedrunAttemptsTableFilterComposer({
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

  ColumnFilters<String> get speedrunId => $composableBuilder(
    column: $table.speedrunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get abandonedAt => $composableBuilder(
    column: $table.abandonedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SpeedrunAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $SpeedrunAttemptsTable> {
  $$SpeedrunAttemptsTableOrderingComposer({
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

  ColumnOrderings<String> get speedrunId => $composableBuilder(
    column: $table.speedrunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get abandonedAt => $composableBuilder(
    column: $table.abandonedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SpeedrunAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpeedrunAttemptsTable> {
  $$SpeedrunAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get speedrunId => $composableBuilder(
    column: $table.speedrunId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get abandonedAt => $composableBuilder(
    column: $table.abandonedAt,
    builder: (column) => column,
  );
}

class $$SpeedrunAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpeedrunAttemptsTable,
          SpeedrunAttemptRow,
          $$SpeedrunAttemptsTableFilterComposer,
          $$SpeedrunAttemptsTableOrderingComposer,
          $$SpeedrunAttemptsTableAnnotationComposer,
          $$SpeedrunAttemptsTableCreateCompanionBuilder,
          $$SpeedrunAttemptsTableUpdateCompanionBuilder,
          (
            SpeedrunAttemptRow,
            BaseReferences<
              _$AppDatabase,
              $SpeedrunAttemptsTable,
              SpeedrunAttemptRow
            >,
          ),
          SpeedrunAttemptRow,
          PrefetchHooks Function()
        > {
  $$SpeedrunAttemptsTableTableManager(
    _$AppDatabase db,
    $SpeedrunAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeedrunAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeedrunAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeedrunAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> speedrunId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> abandonedAt = const Value.absent(),
              }) => SpeedrunAttemptsCompanion(
                id: id,
                speedrunId: speedrunId,
                startedAt: startedAt,
                abandonedAt: abandonedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String speedrunId,
                required DateTime startedAt,
                Value<DateTime?> abandonedAt = const Value.absent(),
              }) => SpeedrunAttemptsCompanion.insert(
                id: id,
                speedrunId: speedrunId,
                startedAt: startedAt,
                abandonedAt: abandonedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpeedrunAttemptsTable, SpeedrunAttemptRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SpeedrunAttemptsTable,
                    SpeedrunAttemptRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SpeedrunAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpeedrunAttemptsTable,
      SpeedrunAttemptRow,
      $$SpeedrunAttemptsTableFilterComposer,
      $$SpeedrunAttemptsTableOrderingComposer,
      $$SpeedrunAttemptsTableAnnotationComposer,
      $$SpeedrunAttemptsTableCreateCompanionBuilder,
      $$SpeedrunAttemptsTableUpdateCompanionBuilder,
      (
        SpeedrunAttemptRow,
        BaseReferences<
          _$AppDatabase,
          $SpeedrunAttemptsTable,
          SpeedrunAttemptRow
        >,
      ),
      SpeedrunAttemptRow,
      PrefetchHooks Function()
    >;
typedef $$RatingHistoryTableCreateCompanionBuilder =
    RatingHistoryCompanion Function({
      Value<int> id,
      Value<int?> gameId,
      required DateTime at,
      required double rating,
      required double deviation,
      required double volatility,
    });
typedef $$RatingHistoryTableUpdateCompanionBuilder =
    RatingHistoryCompanion Function({
      Value<int> id,
      Value<int?> gameId,
      Value<DateTime> at,
      Value<double> rating,
      Value<double> deviation,
      Value<double> volatility,
    });

class $$RatingHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $RatingHistoryTable> {
  $$RatingHistoryTableFilterComposer({
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

  ColumnFilters<int> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deviation => $composableBuilder(
    column: $table.deviation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volatility => $composableBuilder(
    column: $table.volatility,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RatingHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingHistoryTable> {
  $$RatingHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deviation => $composableBuilder(
    column: $table.deviation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volatility => $composableBuilder(
    column: $table.volatility,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RatingHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingHistoryTable> {
  $$RatingHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<double> get deviation =>
      $composableBuilder(column: $table.deviation, builder: (column) => column);

  GeneratedColumn<double> get volatility => $composableBuilder(
    column: $table.volatility,
    builder: (column) => column,
  );
}

class $$RatingHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingHistoryTable,
          RatingRow,
          $$RatingHistoryTableFilterComposer,
          $$RatingHistoryTableOrderingComposer,
          $$RatingHistoryTableAnnotationComposer,
          $$RatingHistoryTableCreateCompanionBuilder,
          $$RatingHistoryTableUpdateCompanionBuilder,
          (
            RatingRow,
            BaseReferences<_$AppDatabase, $RatingHistoryTable, RatingRow>,
          ),
          RatingRow,
          PrefetchHooks Function()
        > {
  $$RatingHistoryTableTableManager(_$AppDatabase db, $RatingHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> gameId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<double> deviation = const Value.absent(),
                Value<double> volatility = const Value.absent(),
              }) => RatingHistoryCompanion(
                id: id,
                gameId: gameId,
                at: at,
                rating: rating,
                deviation: deviation,
                volatility: volatility,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> gameId = const Value.absent(),
                required DateTime at,
                required double rating,
                required double deviation,
                required double volatility,
              }) => RatingHistoryCompanion.insert(
                id: id,
                gameId: gameId,
                at: at,
                rating: rating,
                deviation: deviation,
                volatility: volatility,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RatingHistoryTable, RatingRow>(table),
                  BaseReferences<_$AppDatabase, $RatingHistoryTable, RatingRow>(
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

typedef $$RatingHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingHistoryTable,
      RatingRow,
      $$RatingHistoryTableFilterComposer,
      $$RatingHistoryTableOrderingComposer,
      $$RatingHistoryTableAnnotationComposer,
      $$RatingHistoryTableCreateCompanionBuilder,
      $$RatingHistoryTableUpdateCompanionBuilder,
      (
        RatingRow,
        BaseReferences<_$AppDatabase, $RatingHistoryTable, RatingRow>,
      ),
      RatingRow,
      PrefetchHooks Function()
    >;
typedef $$UnlockedAchievementsTableCreateCompanionBuilder =
    UnlockedAchievementsCompanion Function({
      required String achievementId,
      required DateTime at,
      Value<int> rowid,
    });
typedef $$UnlockedAchievementsTableUpdateCompanionBuilder =
    UnlockedAchievementsCompanion Function({
      Value<String> achievementId,
      Value<DateTime> at,
      Value<int> rowid,
    });

class $$UnlockedAchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnlockedAchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnlockedAchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$UnlockedAchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnlockedAchievementsTable,
          UnlockedAchievementRow,
          $$UnlockedAchievementsTableFilterComposer,
          $$UnlockedAchievementsTableOrderingComposer,
          $$UnlockedAchievementsTableAnnotationComposer,
          $$UnlockedAchievementsTableCreateCompanionBuilder,
          $$UnlockedAchievementsTableUpdateCompanionBuilder,
          (
            UnlockedAchievementRow,
            BaseReferences<
              _$AppDatabase,
              $UnlockedAchievementsTable,
              UnlockedAchievementRow
            >,
          ),
          UnlockedAchievementRow,
          PrefetchHooks Function()
        > {
  $$UnlockedAchievementsTableTableManager(
    _$AppDatabase db,
    $UnlockedAchievementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnlockedAchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnlockedAchievementsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UnlockedAchievementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> achievementId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnlockedAchievementsCompanion(
                achievementId: achievementId,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String achievementId,
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => UnlockedAchievementsCompanion.insert(
                achievementId: achievementId,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $UnlockedAchievementsTable,
                    UnlockedAchievementRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UnlockedAchievementsTable,
                    UnlockedAchievementRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnlockedAchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnlockedAchievementsTable,
      UnlockedAchievementRow,
      $$UnlockedAchievementsTableFilterComposer,
      $$UnlockedAchievementsTableOrderingComposer,
      $$UnlockedAchievementsTableAnnotationComposer,
      $$UnlockedAchievementsTableCreateCompanionBuilder,
      $$UnlockedAchievementsTableUpdateCompanionBuilder,
      (
        UnlockedAchievementRow,
        BaseReferences<
          _$AppDatabase,
          $UnlockedAchievementsTable,
          UnlockedAchievementRow
        >,
      ),
      UnlockedAchievementRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$SpeedrunAttemptsTableTableManager get speedrunAttempts =>
      $$SpeedrunAttemptsTableTableManager(_db, _db.speedrunAttempts);
  $$RatingHistoryTableTableManager get ratingHistory =>
      $$RatingHistoryTableTableManager(_db, _db.ratingHistory);
  $$UnlockedAchievementsTableTableManager get unlockedAchievements =>
      $$UnlockedAchievementsTableTableManager(_db, _db.unlockedAchievements);
}
