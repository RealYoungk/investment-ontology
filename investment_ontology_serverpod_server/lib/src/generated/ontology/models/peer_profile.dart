/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart'
    as _i4yshtjp;
import 'package:serverpod/serverpod.dart' as _is;
import '../../ontology/models/peer_signal.dart' as _i9d9glwe;

abstract class PeerProfile
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PeerProfile._({
    this.id,
    required this.documentId,
    required this.ruleVersion,
    required this.signals,
    required this.computedAt,
  });

  factory PeerProfile({
    int? id,
    required int documentId,
    required int ruleVersion,
    required List<_i9d9glwe.PeerSignal> signals,
    required DateTime computedAt,
  }) = _PeerProfileImpl;

  factory PeerProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return PeerProfile(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      ruleVersion: jsonSerialization['ruleVersion'] as int,
      signals: _i4yshtjp.Protocol().deserialize<List<_i9d9glwe.PeerSignal>>(
        jsonSerialization['signals'],
      ),
      computedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['computedAt'],
      ),
    );
  }

  static final t = PeerProfileTable();

  static const db = PeerProfileRepository._();

  @override
  int? id;

  int documentId;

  int ruleVersion;

  List<_i9d9glwe.PeerSignal> signals;

  DateTime computedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PeerProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PeerProfile copyWith({
    int? id,
    int? documentId,
    int? ruleVersion,
    List<_i9d9glwe.PeerSignal>? signals,
    DateTime? computedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PeerProfile',
      if (id != null) 'id': id,
      'documentId': documentId,
      'ruleVersion': ruleVersion,
      'signals': signals.toJson(valueToJson: (v) => v.toJson()),
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PeerProfile',
      if (id != null) 'id': id,
      'documentId': documentId,
      'ruleVersion': ruleVersion,
      'signals': signals.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'computedAt': computedAt.toJson(),
    };
  }

  static PeerProfileInclude include() {
    return PeerProfileInclude._();
  }

  static PeerProfileIncludeList includeList({
    _is.WhereExpressionBuilder<PeerProfileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PeerProfileTable>? orderBy,
    _is.OrderByListBuilder<PeerProfileTable>? orderByList,
    PeerProfileInclude? include,
  }) {
    return PeerProfileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PeerProfile.t),
      orderByList: orderByList?.call(PeerProfile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PeerProfileImpl extends PeerProfile {
  _PeerProfileImpl({
    int? id,
    required int documentId,
    required int ruleVersion,
    required List<_i9d9glwe.PeerSignal> signals,
    required DateTime computedAt,
  }) : super._(
         id: id,
         documentId: documentId,
         ruleVersion: ruleVersion,
         signals: signals,
         computedAt: computedAt,
       );

  /// Returns a shallow copy of this [PeerProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PeerProfile copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? ruleVersion,
    List<_i9d9glwe.PeerSignal>? signals,
    DateTime? computedAt,
  }) {
    return PeerProfile(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      signals: signals ?? this.signals.map((e0) => e0.copyWith()).toList(),
      computedAt: computedAt ?? this.computedAt,
    );
  }
}

class PeerProfileUpdateTable extends _is.UpdateTable<PeerProfileTable> {
  PeerProfileUpdateTable(super.table);

  _is.ColumnValue<int, int> documentId(int value) => _is.ColumnValue(
    table.documentId,
    value,
  );

  _is.ColumnValue<int, int> ruleVersion(int value) => _is.ColumnValue(
    table.ruleVersion,
    value,
  );

  _is.ColumnValue<List<_i9d9glwe.PeerSignal>, List<_i9d9glwe.PeerSignal>>
  signals(List<_i9d9glwe.PeerSignal> value) => _is.ColumnValue(
    table.signals,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> computedAt(DateTime value) =>
      _is.ColumnValue(
        table.computedAt,
        value,
      );
}

class PeerProfileTable extends _is.Table<int?> {
  PeerProfileTable({super.tableRelation}) : super(tableName: 'peer_profile') {
    updateTable = PeerProfileUpdateTable(this);
    documentId = _is.ColumnInt(
      'documentId',
      this,
    );
    ruleVersion = _is.ColumnInt(
      'ruleVersion',
      this,
    );
    signals = _is.ColumnSerializable<List<_i9d9glwe.PeerSignal>>(
      'signals',
      this,
    );
    computedAt = _is.ColumnDateTime(
      'computedAt',
      this,
    );
  }

  late final PeerProfileUpdateTable updateTable;

  late final _is.ColumnInt documentId;

  late final _is.ColumnInt ruleVersion;

  late final _is.ColumnSerializable<List<_i9d9glwe.PeerSignal>> signals;

  late final _is.ColumnDateTime computedAt;

  @override
  List<_is.Column> get columns => [
    id,
    documentId,
    ruleVersion,
    signals,
    computedAt,
  ];
}

class PeerProfileInclude extends _is.IncludeObject {
  PeerProfileInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PeerProfile.t;
}

class PeerProfileIncludeList extends _is.IncludeList {
  PeerProfileIncludeList._({
    _is.WhereExpressionBuilder<PeerProfileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PeerProfile.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PeerProfile.t;
}

class PeerProfileRepository {
  const PeerProfileRepository._();

  /// Returns a list of [PeerProfile]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<PeerProfile>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PeerProfileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PeerProfileTable>? orderBy,
    _is.OrderByListBuilder<PeerProfileTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PeerProfile>(
      where: where?.call(PeerProfile.t),
      orderBy: orderBy?.call(PeerProfile.t),
      orderByList: orderByList?.call(PeerProfile.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PeerProfile] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<PeerProfile?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PeerProfileTable>? where,
    int? offset,
    _is.OrderByBuilder<PeerProfileTable>? orderBy,
    _is.OrderByListBuilder<PeerProfileTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PeerProfile>(
      where: where?.call(PeerProfile.t),
      orderBy: orderBy?.call(PeerProfile.t),
      orderByList: orderByList?.call(PeerProfile.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PeerProfile] by its [id] or null if no such row exists.
  Future<PeerProfile?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PeerProfile>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PeerProfile]s in the list and returns the inserted rows.
  ///
  /// The returned [PeerProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PeerProfile>> insert(
    _is.DatabaseSession session,
    List<PeerProfile> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PeerProfile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PeerProfile] and returns the inserted row.
  ///
  /// The returned [PeerProfile] will have its `id` field set.
  Future<PeerProfile> insertRow(
    _is.DatabaseSession session,
    PeerProfile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PeerProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PeerProfile]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [PeerProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PeerProfile>> upsert(
    _is.DatabaseSession session,
    List<PeerProfile> rows, {
    required _is.ColumnSelections<PeerProfileTable> conflictColumns,
    _is.ColumnSelections<PeerProfileTable>? updateColumns,
    _is.WhereExpressionBuilder<PeerProfileTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PeerProfile>(
      rows,
      conflictColumns: conflictColumns(PeerProfile.t),
      updateColumns: updateColumns?.call(PeerProfile.t),
      updateWhere: updateWhere?.call(PeerProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PeerProfile] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [PeerProfile] will have its `id` field set.
  Future<PeerProfile?> upsertRow(
    _is.DatabaseSession session,
    PeerProfile row, {
    required _is.ColumnSelections<PeerProfileTable> conflictColumns,
    _is.ColumnSelections<PeerProfileTable>? updateColumns,
    _is.WhereExpressionBuilder<PeerProfileTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PeerProfile>(
      row,
      conflictColumns: conflictColumns(PeerProfile.t),
      updateColumns: updateColumns?.call(PeerProfile.t),
      updateWhere: updateWhere?.call(PeerProfile.t),
      transaction: transaction,
    );
  }

  /// Updates all [PeerProfile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PeerProfile>> update(
    _is.DatabaseSession session,
    List<PeerProfile> rows, {
    _is.ColumnSelections<PeerProfileTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PeerProfile>(
      rows,
      columns: columns?.call(PeerProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PeerProfile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PeerProfile> updateRow(
    _is.DatabaseSession session,
    PeerProfile row, {
    _is.ColumnSelections<PeerProfileTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PeerProfile>(
      row,
      columns: columns?.call(PeerProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PeerProfile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PeerProfile?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PeerProfileUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PeerProfile>(
      id,
      columnValues: columnValues(PeerProfile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PeerProfile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PeerProfile>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PeerProfileUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PeerProfileTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PeerProfileTable>? orderBy,
    _is.OrderByListBuilder<PeerProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PeerProfile>(
      columnValues: columnValues(PeerProfile.t.updateTable),
      where: where(PeerProfile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PeerProfile.t),
      orderByList: orderByList?.call(PeerProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PeerProfile]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PeerProfile>> delete(
    _is.DatabaseSession session,
    List<PeerProfile> rows, {
    _is.OrderByBuilder<PeerProfileTable>? orderBy,
    _is.OrderByListBuilder<PeerProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PeerProfile>(
      rows,
      orderBy: orderBy?.call(PeerProfile.t),
      orderByList: orderByList?.call(PeerProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PeerProfile].
  Future<PeerProfile> deleteRow(
    _is.DatabaseSession session,
    PeerProfile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PeerProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PeerProfile>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PeerProfileTable> where,
    _is.OrderByBuilder<PeerProfileTable>? orderBy,
    _is.OrderByListBuilder<PeerProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PeerProfile>(
      where: where(PeerProfile.t),
      orderBy: orderBy?.call(PeerProfile.t),
      orderByList: orderByList?.call(PeerProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PeerProfileTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PeerProfile>(
      where: where?.call(PeerProfile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PeerProfile] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PeerProfileTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PeerProfile>(
      where: where(PeerProfile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
