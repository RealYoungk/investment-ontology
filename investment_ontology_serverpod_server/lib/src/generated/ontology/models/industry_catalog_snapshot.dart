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
import '../../ontology/models/industry_discovery.dart' as _iic06ifo;

/// Stored classification, built by the server independently of page requests.
abstract class IndustryCatalogSnapshot
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  IndustryCatalogSnapshot._({
    this.id,
    required this.snapshotKey,
    required this.sourceFingerprint,
    required this.builderVersion,
    required this.catalog,
    required this.pilot,
    required this.computedAt,
  });

  factory IndustryCatalogSnapshot({
    int? id,
    required String snapshotKey,
    required String sourceFingerprint,
    required int builderVersion,
    required _iic06ifo.IndustryDiscovery catalog,
    required _iic06ifo.IndustryDiscovery pilot,
    required DateTime computedAt,
  }) = _IndustryCatalogSnapshotImpl;

  factory IndustryCatalogSnapshot.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return IndustryCatalogSnapshot(
      id: jsonSerialization['id'] as int?,
      snapshotKey: jsonSerialization['snapshotKey'] as String,
      sourceFingerprint: jsonSerialization['sourceFingerprint'] as String,
      builderVersion: jsonSerialization['builderVersion'] as int,
      catalog: _i4yshtjp.Protocol().deserialize<_iic06ifo.IndustryDiscovery>(
        jsonSerialization['catalog'],
      ),
      pilot: _i4yshtjp.Protocol().deserialize<_iic06ifo.IndustryDiscovery>(
        jsonSerialization['pilot'],
      ),
      computedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['computedAt'],
      ),
    );
  }

  static final t = IndustryCatalogSnapshotTable();

  static const db = IndustryCatalogSnapshotRepository._();

  @override
  int? id;

  String snapshotKey;

  String sourceFingerprint;

  int builderVersion;

  _iic06ifo.IndustryDiscovery catalog;

  _iic06ifo.IndustryDiscovery pilot;

  DateTime computedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [IndustryCatalogSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  IndustryCatalogSnapshot copyWith({
    int? id,
    String? snapshotKey,
    String? sourceFingerprint,
    int? builderVersion,
    _iic06ifo.IndustryDiscovery? catalog,
    _iic06ifo.IndustryDiscovery? pilot,
    DateTime? computedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndustryCatalogSnapshot',
      if (id != null) 'id': id,
      'snapshotKey': snapshotKey,
      'sourceFingerprint': sourceFingerprint,
      'builderVersion': builderVersion,
      'catalog': catalog.toJson(),
      'pilot': pilot.toJson(),
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static IndustryCatalogSnapshotInclude include() {
    return IndustryCatalogSnapshotInclude._();
  }

  static IndustryCatalogSnapshotIncludeList includeList({
    _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IndustryCatalogSnapshotTable>? orderBy,
    _is.OrderByListBuilder<IndustryCatalogSnapshotTable>? orderByList,
    IndustryCatalogSnapshotInclude? include,
  }) {
    return IndustryCatalogSnapshotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IndustryCatalogSnapshot.t),
      orderByList: orderByList?.call(IndustryCatalogSnapshot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndustryCatalogSnapshotImpl extends IndustryCatalogSnapshot {
  _IndustryCatalogSnapshotImpl({
    int? id,
    required String snapshotKey,
    required String sourceFingerprint,
    required int builderVersion,
    required _iic06ifo.IndustryDiscovery catalog,
    required _iic06ifo.IndustryDiscovery pilot,
    required DateTime computedAt,
  }) : super._(
         id: id,
         snapshotKey: snapshotKey,
         sourceFingerprint: sourceFingerprint,
         builderVersion: builderVersion,
         catalog: catalog,
         pilot: pilot,
         computedAt: computedAt,
       );

  /// Returns a shallow copy of this [IndustryCatalogSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  IndustryCatalogSnapshot copyWith({
    Object? id = _Undefined,
    String? snapshotKey,
    String? sourceFingerprint,
    int? builderVersion,
    _iic06ifo.IndustryDiscovery? catalog,
    _iic06ifo.IndustryDiscovery? pilot,
    DateTime? computedAt,
  }) {
    return IndustryCatalogSnapshot(
      id: id is int? ? id : this.id,
      snapshotKey: snapshotKey ?? this.snapshotKey,
      sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
      builderVersion: builderVersion ?? this.builderVersion,
      catalog: catalog ?? this.catalog.copyWith(),
      pilot: pilot ?? this.pilot.copyWith(),
      computedAt: computedAt ?? this.computedAt,
    );
  }
}

class IndustryCatalogSnapshotUpdateTable
    extends _is.UpdateTable<IndustryCatalogSnapshotTable> {
  IndustryCatalogSnapshotUpdateTable(super.table);

  _is.ColumnValue<String, String> snapshotKey(String value) => _is.ColumnValue(
    table.snapshotKey,
    value,
  );

  _is.ColumnValue<String, String> sourceFingerprint(String value) =>
      _is.ColumnValue(
        table.sourceFingerprint,
        value,
      );

  _is.ColumnValue<int, int> builderVersion(int value) => _is.ColumnValue(
    table.builderVersion,
    value,
  );

  _is.ColumnValue<_iic06ifo.IndustryDiscovery, _iic06ifo.IndustryDiscovery>
  catalog(_iic06ifo.IndustryDiscovery value) => _is.ColumnValue(
    table.catalog,
    value,
  );

  _is.ColumnValue<_iic06ifo.IndustryDiscovery, _iic06ifo.IndustryDiscovery>
  pilot(_iic06ifo.IndustryDiscovery value) => _is.ColumnValue(
    table.pilot,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> computedAt(DateTime value) =>
      _is.ColumnValue(
        table.computedAt,
        value,
      );
}

class IndustryCatalogSnapshotTable extends _is.Table<int?> {
  IndustryCatalogSnapshotTable({super.tableRelation})
    : super(tableName: 'industry_catalog_snapshot') {
    updateTable = IndustryCatalogSnapshotUpdateTable(this);
    snapshotKey = _is.ColumnString(
      'snapshotKey',
      this,
    );
    sourceFingerprint = _is.ColumnString(
      'sourceFingerprint',
      this,
    );
    builderVersion = _is.ColumnInt(
      'builderVersion',
      this,
    );
    catalog = _is.ColumnSerializable<_iic06ifo.IndustryDiscovery>(
      'catalog',
      this,
    );
    pilot = _is.ColumnSerializable<_iic06ifo.IndustryDiscovery>(
      'pilot',
      this,
    );
    computedAt = _is.ColumnDateTime(
      'computedAt',
      this,
    );
  }

  late final IndustryCatalogSnapshotUpdateTable updateTable;

  late final _is.ColumnString snapshotKey;

  late final _is.ColumnString sourceFingerprint;

  late final _is.ColumnInt builderVersion;

  late final _is.ColumnSerializable<_iic06ifo.IndustryDiscovery> catalog;

  late final _is.ColumnSerializable<_iic06ifo.IndustryDiscovery> pilot;

  late final _is.ColumnDateTime computedAt;

  @override
  List<_is.Column> get columns => [
    id,
    snapshotKey,
    sourceFingerprint,
    builderVersion,
    catalog,
    pilot,
    computedAt,
  ];
}

class IndustryCatalogSnapshotInclude extends _is.IncludeObject {
  IndustryCatalogSnapshotInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => IndustryCatalogSnapshot.t;
}

class IndustryCatalogSnapshotIncludeList extends _is.IncludeList {
  IndustryCatalogSnapshotIncludeList._({
    _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(IndustryCatalogSnapshot.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => IndustryCatalogSnapshot.t;
}

class IndustryCatalogSnapshotRepository {
  const IndustryCatalogSnapshotRepository._();

  /// Returns a list of [IndustryCatalogSnapshot]s matching the given query parameters.
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
  Future<List<IndustryCatalogSnapshot>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IndustryCatalogSnapshotTable>? orderBy,
    _is.OrderByListBuilder<IndustryCatalogSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<IndustryCatalogSnapshot>(
      where: where?.call(IndustryCatalogSnapshot.t),
      orderBy: orderBy?.call(IndustryCatalogSnapshot.t),
      orderByList: orderByList?.call(IndustryCatalogSnapshot.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [IndustryCatalogSnapshot] matching the given query parameters.
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
  Future<IndustryCatalogSnapshot?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable>? where,
    int? offset,
    _is.OrderByBuilder<IndustryCatalogSnapshotTable>? orderBy,
    _is.OrderByListBuilder<IndustryCatalogSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<IndustryCatalogSnapshot>(
      where: where?.call(IndustryCatalogSnapshot.t),
      orderBy: orderBy?.call(IndustryCatalogSnapshot.t),
      orderByList: orderByList?.call(IndustryCatalogSnapshot.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [IndustryCatalogSnapshot] by its [id] or null if no such row exists.
  Future<IndustryCatalogSnapshot?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<IndustryCatalogSnapshot>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [IndustryCatalogSnapshot]s in the list and returns the inserted rows.
  ///
  /// The returned [IndustryCatalogSnapshot]s will have their `id` fields set.
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
  Future<List<IndustryCatalogSnapshot>> insert(
    _is.DatabaseSession session,
    List<IndustryCatalogSnapshot> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<IndustryCatalogSnapshot>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [IndustryCatalogSnapshot] and returns the inserted row.
  ///
  /// The returned [IndustryCatalogSnapshot] will have its `id` field set.
  Future<IndustryCatalogSnapshot> insertRow(
    _is.DatabaseSession session,
    IndustryCatalogSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<IndustryCatalogSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [IndustryCatalogSnapshot]s in the list and returns the resulting rows.
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
  /// The returned [IndustryCatalogSnapshot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<IndustryCatalogSnapshot>> upsert(
    _is.DatabaseSession session,
    List<IndustryCatalogSnapshot> rows, {
    required _is.ColumnSelections<IndustryCatalogSnapshotTable> conflictColumns,
    _is.ColumnSelections<IndustryCatalogSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<IndustryCatalogSnapshot>(
      rows,
      conflictColumns: conflictColumns(IndustryCatalogSnapshot.t),
      updateColumns: updateColumns?.call(IndustryCatalogSnapshot.t),
      updateWhere: updateWhere?.call(IndustryCatalogSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [IndustryCatalogSnapshot] and returns the resulting row.
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
  /// The returned [IndustryCatalogSnapshot] will have its `id` field set.
  Future<IndustryCatalogSnapshot?> upsertRow(
    _is.DatabaseSession session,
    IndustryCatalogSnapshot row, {
    required _is.ColumnSelections<IndustryCatalogSnapshotTable> conflictColumns,
    _is.ColumnSelections<IndustryCatalogSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<IndustryCatalogSnapshot>(
      row,
      conflictColumns: conflictColumns(IndustryCatalogSnapshot.t),
      updateColumns: updateColumns?.call(IndustryCatalogSnapshot.t),
      updateWhere: updateWhere?.call(IndustryCatalogSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates all [IndustryCatalogSnapshot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<IndustryCatalogSnapshot>> update(
    _is.DatabaseSession session,
    List<IndustryCatalogSnapshot> rows, {
    _is.ColumnSelections<IndustryCatalogSnapshotTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<IndustryCatalogSnapshot>(
      rows,
      columns: columns?.call(IndustryCatalogSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [IndustryCatalogSnapshot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<IndustryCatalogSnapshot> updateRow(
    _is.DatabaseSession session,
    IndustryCatalogSnapshot row, {
    _is.ColumnSelections<IndustryCatalogSnapshotTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<IndustryCatalogSnapshot>(
      row,
      columns: columns?.call(IndustryCatalogSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IndustryCatalogSnapshot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<IndustryCatalogSnapshot?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<IndustryCatalogSnapshotUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<IndustryCatalogSnapshot>(
      id,
      columnValues: columnValues(IndustryCatalogSnapshot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [IndustryCatalogSnapshot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<IndustryCatalogSnapshot>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<IndustryCatalogSnapshotUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IndustryCatalogSnapshotTable>? orderBy,
    _is.OrderByListBuilder<IndustryCatalogSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<IndustryCatalogSnapshot>(
      columnValues: columnValues(IndustryCatalogSnapshot.t.updateTable),
      where: where(IndustryCatalogSnapshot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IndustryCatalogSnapshot.t),
      orderByList: orderByList?.call(IndustryCatalogSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [IndustryCatalogSnapshot]s in the list and returns the deleted rows.
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
  Future<List<IndustryCatalogSnapshot>> delete(
    _is.DatabaseSession session,
    List<IndustryCatalogSnapshot> rows, {
    _is.OrderByBuilder<IndustryCatalogSnapshotTable>? orderBy,
    _is.OrderByListBuilder<IndustryCatalogSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<IndustryCatalogSnapshot>(
      rows,
      orderBy: orderBy?.call(IndustryCatalogSnapshot.t),
      orderByList: orderByList?.call(IndustryCatalogSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [IndustryCatalogSnapshot].
  Future<IndustryCatalogSnapshot> deleteRow(
    _is.DatabaseSession session,
    IndustryCatalogSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<IndustryCatalogSnapshot>(
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
  Future<List<IndustryCatalogSnapshot>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable> where,
    _is.OrderByBuilder<IndustryCatalogSnapshotTable>? orderBy,
    _is.OrderByListBuilder<IndustryCatalogSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<IndustryCatalogSnapshot>(
      where: where(IndustryCatalogSnapshot.t),
      orderBy: orderBy?.call(IndustryCatalogSnapshot.t),
      orderByList: orderByList?.call(IndustryCatalogSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<IndustryCatalogSnapshot>(
      where: where?.call(IndustryCatalogSnapshot.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [IndustryCatalogSnapshot] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<IndustryCatalogSnapshotTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<IndustryCatalogSnapshot>(
      where: where(IndustryCatalogSnapshot.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
