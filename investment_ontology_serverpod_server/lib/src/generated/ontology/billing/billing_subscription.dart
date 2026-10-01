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
import 'package:serverpod/serverpod.dart' as _is;

abstract class BillingSubscription
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BillingSubscription._({
    this.id,
    required this.ownerId,
    required this.originUtc,
    bool? cancelAtPeriodEnd,
    bool? deleted,
    this.customerKey,
    this.encryptedBillingKey,
    this.encryptedKeyPendingDeletion,
    int? nextPeriod,
  }) : cancelAtPeriodEnd = cancelAtPeriodEnd ?? false,
       deleted = deleted ?? false,
       nextPeriod = nextPeriod ?? 0;

  factory BillingSubscription({
    int? id,
    required _is.UuidValue ownerId,
    required DateTime originUtc,
    bool? cancelAtPeriodEnd,
    bool? deleted,
    String? customerKey,
    String? encryptedBillingKey,
    String? encryptedKeyPendingDeletion,
    int? nextPeriod,
  }) = _BillingSubscriptionImpl;

  factory BillingSubscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return BillingSubscription(
      id: jsonSerialization['id'] as int?,
      ownerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      originUtc: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['originUtc'],
      ),
      cancelAtPeriodEnd: jsonSerialization['cancelAtPeriodEnd'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['cancelAtPeriodEnd'],
            ),
      deleted: jsonSerialization['deleted'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['deleted']),
      customerKey: jsonSerialization['customerKey'] as String?,
      encryptedBillingKey: jsonSerialization['encryptedBillingKey'] as String?,
      encryptedKeyPendingDeletion:
          jsonSerialization['encryptedKeyPendingDeletion'] as String?,
      nextPeriod: jsonSerialization['nextPeriod'] as int?,
    );
  }

  static final t = BillingSubscriptionTable();

  static const db = BillingSubscriptionRepository._();

  @override
  int? id;

  _is.UuidValue ownerId;

  DateTime originUtc;

  bool cancelAtPeriodEnd;

  bool deleted;

  String? customerKey;

  String? encryptedBillingKey;

  String? encryptedKeyPendingDeletion;

  int nextPeriod;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BillingSubscription]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BillingSubscription copyWith({
    int? id,
    _is.UuidValue? ownerId,
    DateTime? originUtc,
    bool? cancelAtPeriodEnd,
    bool? deleted,
    String? customerKey,
    String? encryptedBillingKey,
    String? encryptedKeyPendingDeletion,
    int? nextPeriod,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BillingSubscription',
      if (id != null) 'id': id,
      'ownerId': ownerId.toJson(),
      'originUtc': originUtc.toJson(),
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'deleted': deleted,
      if (customerKey != null) 'customerKey': customerKey,
      if (encryptedBillingKey != null)
        'encryptedBillingKey': encryptedBillingKey,
      if (encryptedKeyPendingDeletion != null)
        'encryptedKeyPendingDeletion': encryptedKeyPendingDeletion,
      'nextPeriod': nextPeriod,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static BillingSubscriptionInclude include() {
    return BillingSubscriptionInclude._();
  }

  static BillingSubscriptionIncludeList includeList({
    _is.WhereExpressionBuilder<BillingSubscriptionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<BillingSubscriptionTable>? orderByList,
    BillingSubscriptionInclude? include,
  }) {
    return BillingSubscriptionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BillingSubscription.t),
      orderByList: orderByList?.call(BillingSubscription.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BillingSubscriptionImpl extends BillingSubscription {
  _BillingSubscriptionImpl({
    int? id,
    required _is.UuidValue ownerId,
    required DateTime originUtc,
    bool? cancelAtPeriodEnd,
    bool? deleted,
    String? customerKey,
    String? encryptedBillingKey,
    String? encryptedKeyPendingDeletion,
    int? nextPeriod,
  }) : super._(
         id: id,
         ownerId: ownerId,
         originUtc: originUtc,
         cancelAtPeriodEnd: cancelAtPeriodEnd,
         deleted: deleted,
         customerKey: customerKey,
         encryptedBillingKey: encryptedBillingKey,
         encryptedKeyPendingDeletion: encryptedKeyPendingDeletion,
         nextPeriod: nextPeriod,
       );

  /// Returns a shallow copy of this [BillingSubscription]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BillingSubscription copyWith({
    Object? id = _Undefined,
    _is.UuidValue? ownerId,
    DateTime? originUtc,
    bool? cancelAtPeriodEnd,
    bool? deleted,
    Object? customerKey = _Undefined,
    Object? encryptedBillingKey = _Undefined,
    Object? encryptedKeyPendingDeletion = _Undefined,
    int? nextPeriod,
  }) {
    return BillingSubscription(
      id: id is int? ? id : this.id,
      ownerId: ownerId ?? this.ownerId,
      originUtc: originUtc ?? this.originUtc,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      deleted: deleted ?? this.deleted,
      customerKey: customerKey is String? ? customerKey : this.customerKey,
      encryptedBillingKey: encryptedBillingKey is String?
          ? encryptedBillingKey
          : this.encryptedBillingKey,
      encryptedKeyPendingDeletion: encryptedKeyPendingDeletion is String?
          ? encryptedKeyPendingDeletion
          : this.encryptedKeyPendingDeletion,
      nextPeriod: nextPeriod ?? this.nextPeriod,
    );
  }
}

class BillingSubscriptionUpdateTable
    extends _is.UpdateTable<BillingSubscriptionTable> {
  BillingSubscriptionUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> ownerId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.ownerId,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> originUtc(DateTime value) =>
      _is.ColumnValue(
        table.originUtc,
        value,
      );

  _is.ColumnValue<bool, bool> cancelAtPeriodEnd(bool value) => _is.ColumnValue(
    table.cancelAtPeriodEnd,
    value,
  );

  _is.ColumnValue<bool, bool> deleted(bool value) => _is.ColumnValue(
    table.deleted,
    value,
  );

  _is.ColumnValue<String, String> customerKey(String? value) => _is.ColumnValue(
    table.customerKey,
    value,
  );

  _is.ColumnValue<String, String> encryptedBillingKey(String? value) =>
      _is.ColumnValue(
        table.encryptedBillingKey,
        value,
      );

  _is.ColumnValue<String, String> encryptedKeyPendingDeletion(String? value) =>
      _is.ColumnValue(
        table.encryptedKeyPendingDeletion,
        value,
      );

  _is.ColumnValue<int, int> nextPeriod(int value) => _is.ColumnValue(
    table.nextPeriod,
    value,
  );
}

class BillingSubscriptionTable extends _is.Table<int?> {
  BillingSubscriptionTable({super.tableRelation})
    : super(tableName: 'billing_subscription') {
    updateTable = BillingSubscriptionUpdateTable(this);
    ownerId = _is.ColumnUuid(
      'ownerId',
      this,
    );
    originUtc = _is.ColumnDateTime(
      'originUtc',
      this,
    );
    cancelAtPeriodEnd = _is.ColumnBool(
      'cancelAtPeriodEnd',
      this,
      hasDefault: true,
    );
    deleted = _is.ColumnBool(
      'deleted',
      this,
      hasDefault: true,
    );
    customerKey = _is.ColumnString(
      'customerKey',
      this,
    );
    encryptedBillingKey = _is.ColumnString(
      'encryptedBillingKey',
      this,
    );
    encryptedKeyPendingDeletion = _is.ColumnString(
      'encryptedKeyPendingDeletion',
      this,
    );
    nextPeriod = _is.ColumnInt(
      'nextPeriod',
      this,
      hasDefault: true,
    );
  }

  late final BillingSubscriptionUpdateTable updateTable;

  late final _is.ColumnUuid ownerId;

  late final _is.ColumnDateTime originUtc;

  late final _is.ColumnBool cancelAtPeriodEnd;

  late final _is.ColumnBool deleted;

  late final _is.ColumnString customerKey;

  late final _is.ColumnString encryptedBillingKey;

  late final _is.ColumnString encryptedKeyPendingDeletion;

  late final _is.ColumnInt nextPeriod;

  @override
  List<_is.Column> get columns => [
    id,
    ownerId,
    originUtc,
    cancelAtPeriodEnd,
    deleted,
    customerKey,
    encryptedBillingKey,
    encryptedKeyPendingDeletion,
    nextPeriod,
  ];
}

class BillingSubscriptionInclude extends _is.IncludeObject {
  BillingSubscriptionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BillingSubscription.t;
}

class BillingSubscriptionIncludeList extends _is.IncludeList {
  BillingSubscriptionIncludeList._({
    _is.WhereExpressionBuilder<BillingSubscriptionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BillingSubscription.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BillingSubscription.t;
}

class BillingSubscriptionRepository {
  const BillingSubscriptionRepository._();

  /// Returns a list of [BillingSubscription]s matching the given query parameters.
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
  Future<List<BillingSubscription>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingSubscriptionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<BillingSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BillingSubscription>(
      where: where?.call(BillingSubscription.t),
      orderBy: orderBy?.call(BillingSubscription.t),
      orderByList: orderByList?.call(BillingSubscription.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BillingSubscription] matching the given query parameters.
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
  Future<BillingSubscription?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingSubscriptionTable>? where,
    int? offset,
    _is.OrderByBuilder<BillingSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<BillingSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BillingSubscription>(
      where: where?.call(BillingSubscription.t),
      orderBy: orderBy?.call(BillingSubscription.t),
      orderByList: orderByList?.call(BillingSubscription.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BillingSubscription] by its [id] or null if no such row exists.
  Future<BillingSubscription?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BillingSubscription>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BillingSubscription]s in the list and returns the inserted rows.
  ///
  /// The returned [BillingSubscription]s will have their `id` fields set.
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
  Future<List<BillingSubscription>> insert(
    _is.DatabaseSession session,
    List<BillingSubscription> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BillingSubscription>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BillingSubscription] and returns the inserted row.
  ///
  /// The returned [BillingSubscription] will have its `id` field set.
  Future<BillingSubscription> insertRow(
    _is.DatabaseSession session,
    BillingSubscription row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BillingSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BillingSubscription]s in the list and returns the resulting rows.
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
  /// The returned [BillingSubscription]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingSubscription>> upsert(
    _is.DatabaseSession session,
    List<BillingSubscription> rows, {
    required _is.ColumnSelections<BillingSubscriptionTable> conflictColumns,
    _is.ColumnSelections<BillingSubscriptionTable>? updateColumns,
    _is.WhereExpressionBuilder<BillingSubscriptionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BillingSubscription>(
      rows,
      conflictColumns: conflictColumns(BillingSubscription.t),
      updateColumns: updateColumns?.call(BillingSubscription.t),
      updateWhere: updateWhere?.call(BillingSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BillingSubscription] and returns the resulting row.
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
  /// The returned [BillingSubscription] will have its `id` field set.
  Future<BillingSubscription?> upsertRow(
    _is.DatabaseSession session,
    BillingSubscription row, {
    required _is.ColumnSelections<BillingSubscriptionTable> conflictColumns,
    _is.ColumnSelections<BillingSubscriptionTable>? updateColumns,
    _is.WhereExpressionBuilder<BillingSubscriptionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BillingSubscription>(
      row,
      conflictColumns: conflictColumns(BillingSubscription.t),
      updateColumns: updateColumns?.call(BillingSubscription.t),
      updateWhere: updateWhere?.call(BillingSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates all [BillingSubscription]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingSubscription>> update(
    _is.DatabaseSession session,
    List<BillingSubscription> rows, {
    _is.ColumnSelections<BillingSubscriptionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BillingSubscription>(
      rows,
      columns: columns?.call(BillingSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BillingSubscription]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BillingSubscription> updateRow(
    _is.DatabaseSession session,
    BillingSubscription row, {
    _is.ColumnSelections<BillingSubscriptionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BillingSubscription>(
      row,
      columns: columns?.call(BillingSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BillingSubscription] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BillingSubscription?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BillingSubscriptionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BillingSubscription>(
      id,
      columnValues: columnValues(BillingSubscription.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BillingSubscription]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingSubscription>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BillingSubscriptionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<BillingSubscriptionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<BillingSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BillingSubscription>(
      columnValues: columnValues(BillingSubscription.t.updateTable),
      where: where(BillingSubscription.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BillingSubscription.t),
      orderByList: orderByList?.call(BillingSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BillingSubscription]s in the list and returns the deleted rows.
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
  Future<List<BillingSubscription>> delete(
    _is.DatabaseSession session,
    List<BillingSubscription> rows, {
    _is.OrderByBuilder<BillingSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<BillingSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BillingSubscription>(
      rows,
      orderBy: orderBy?.call(BillingSubscription.t),
      orderByList: orderByList?.call(BillingSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BillingSubscription].
  Future<BillingSubscription> deleteRow(
    _is.DatabaseSession session,
    BillingSubscription row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BillingSubscription>(
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
  Future<List<BillingSubscription>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BillingSubscriptionTable> where,
    _is.OrderByBuilder<BillingSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<BillingSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BillingSubscription>(
      where: where(BillingSubscription.t),
      orderBy: orderBy?.call(BillingSubscription.t),
      orderByList: orderByList?.call(BillingSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingSubscriptionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BillingSubscription>(
      where: where?.call(BillingSubscription.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BillingSubscription] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BillingSubscriptionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BillingSubscription>(
      where: where(BillingSubscription.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
