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

abstract class BillingCheckout
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BillingCheckout._({
    this.id,
    required this.ownerId,
    required this.subscriptionId,
    required this.stateHash,
    required this.expiresUtc,
    required this.status,
    bool? replaceCard,
    this.termsVersion,
    this.acceptedAtUtc,
    required this.issueIdempotencyKey,
    int? amountKrw,
    String? priceVersion,
    String? provider,
  }) : replaceCard = replaceCard ?? false,
       amountKrw = amountKrw ?? 2900,
       priceVersion = priceVersion ?? 'legacy-2900',
       provider = provider ?? 'toss';

  factory BillingCheckout({
    int? id,
    required _is.UuidValue ownerId,
    required int subscriptionId,
    required String stateHash,
    required DateTime expiresUtc,
    required String status,
    bool? replaceCard,
    String? termsVersion,
    DateTime? acceptedAtUtc,
    required String issueIdempotencyKey,
    int? amountKrw,
    String? priceVersion,
    String? provider,
  }) = _BillingCheckoutImpl;

  factory BillingCheckout.fromJson(Map<String, dynamic> jsonSerialization) {
    return BillingCheckout(
      id: jsonSerialization['id'] as int?,
      ownerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      subscriptionId: jsonSerialization['subscriptionId'] as int,
      stateHash: jsonSerialization['stateHash'] as String,
      expiresUtc: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresUtc'],
      ),
      status: jsonSerialization['status'] as String,
      replaceCard: jsonSerialization['replaceCard'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['replaceCard']),
      termsVersion: jsonSerialization['termsVersion'] as String?,
      acceptedAtUtc: jsonSerialization['acceptedAtUtc'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['acceptedAtUtc'],
            ),
      issueIdempotencyKey: jsonSerialization['issueIdempotencyKey'] as String,
      amountKrw: jsonSerialization['amountKrw'] as int?,
      priceVersion: jsonSerialization['priceVersion'] as String?,
      provider: jsonSerialization['provider'] as String?,
    );
  }

  static final t = BillingCheckoutTable();

  static const db = BillingCheckoutRepository._();

  @override
  int? id;

  _is.UuidValue ownerId;

  int subscriptionId;

  String stateHash;

  DateTime expiresUtc;

  String status;

  bool replaceCard;

  String? termsVersion;

  DateTime? acceptedAtUtc;

  String issueIdempotencyKey;

  int amountKrw;

  String priceVersion;

  String provider;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BillingCheckout]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BillingCheckout copyWith({
    int? id,
    _is.UuidValue? ownerId,
    int? subscriptionId,
    String? stateHash,
    DateTime? expiresUtc,
    String? status,
    bool? replaceCard,
    String? termsVersion,
    DateTime? acceptedAtUtc,
    String? issueIdempotencyKey,
    int? amountKrw,
    String? priceVersion,
    String? provider,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BillingCheckout',
      if (id != null) 'id': id,
      'ownerId': ownerId.toJson(),
      'subscriptionId': subscriptionId,
      'stateHash': stateHash,
      'expiresUtc': expiresUtc.toJson(),
      'status': status,
      'replaceCard': replaceCard,
      if (termsVersion != null) 'termsVersion': termsVersion,
      if (acceptedAtUtc != null) 'acceptedAtUtc': acceptedAtUtc?.toJson(),
      'issueIdempotencyKey': issueIdempotencyKey,
      'amountKrw': amountKrw,
      'priceVersion': priceVersion,
      'provider': provider,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static BillingCheckoutInclude include() {
    return BillingCheckoutInclude._();
  }

  static BillingCheckoutIncludeList includeList({
    _is.WhereExpressionBuilder<BillingCheckoutTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingCheckoutTable>? orderBy,
    _is.OrderByListBuilder<BillingCheckoutTable>? orderByList,
    BillingCheckoutInclude? include,
  }) {
    return BillingCheckoutIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BillingCheckout.t),
      orderByList: orderByList?.call(BillingCheckout.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BillingCheckoutImpl extends BillingCheckout {
  _BillingCheckoutImpl({
    int? id,
    required _is.UuidValue ownerId,
    required int subscriptionId,
    required String stateHash,
    required DateTime expiresUtc,
    required String status,
    bool? replaceCard,
    String? termsVersion,
    DateTime? acceptedAtUtc,
    required String issueIdempotencyKey,
    int? amountKrw,
    String? priceVersion,
    String? provider,
  }) : super._(
         id: id,
         ownerId: ownerId,
         subscriptionId: subscriptionId,
         stateHash: stateHash,
         expiresUtc: expiresUtc,
         status: status,
         replaceCard: replaceCard,
         termsVersion: termsVersion,
         acceptedAtUtc: acceptedAtUtc,
         issueIdempotencyKey: issueIdempotencyKey,
         amountKrw: amountKrw,
         priceVersion: priceVersion,
         provider: provider,
       );

  /// Returns a shallow copy of this [BillingCheckout]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BillingCheckout copyWith({
    Object? id = _Undefined,
    _is.UuidValue? ownerId,
    int? subscriptionId,
    String? stateHash,
    DateTime? expiresUtc,
    String? status,
    bool? replaceCard,
    Object? termsVersion = _Undefined,
    Object? acceptedAtUtc = _Undefined,
    String? issueIdempotencyKey,
    int? amountKrw,
    String? priceVersion,
    String? provider,
  }) {
    return BillingCheckout(
      id: id is int? ? id : this.id,
      ownerId: ownerId ?? this.ownerId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      stateHash: stateHash ?? this.stateHash,
      expiresUtc: expiresUtc ?? this.expiresUtc,
      status: status ?? this.status,
      replaceCard: replaceCard ?? this.replaceCard,
      termsVersion: termsVersion is String? ? termsVersion : this.termsVersion,
      acceptedAtUtc: acceptedAtUtc is DateTime?
          ? acceptedAtUtc
          : this.acceptedAtUtc,
      issueIdempotencyKey: issueIdempotencyKey ?? this.issueIdempotencyKey,
      amountKrw: amountKrw ?? this.amountKrw,
      priceVersion: priceVersion ?? this.priceVersion,
      provider: provider ?? this.provider,
    );
  }
}

class BillingCheckoutUpdateTable extends _is.UpdateTable<BillingCheckoutTable> {
  BillingCheckoutUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> ownerId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.ownerId,
        value,
      );

  _is.ColumnValue<int, int> subscriptionId(int value) => _is.ColumnValue(
    table.subscriptionId,
    value,
  );

  _is.ColumnValue<String, String> stateHash(String value) => _is.ColumnValue(
    table.stateHash,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> expiresUtc(DateTime value) =>
      _is.ColumnValue(
        table.expiresUtc,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<bool, bool> replaceCard(bool value) => _is.ColumnValue(
    table.replaceCard,
    value,
  );

  _is.ColumnValue<String, String> termsVersion(String? value) =>
      _is.ColumnValue(
        table.termsVersion,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> acceptedAtUtc(DateTime? value) =>
      _is.ColumnValue(
        table.acceptedAtUtc,
        value,
      );

  _is.ColumnValue<String, String> issueIdempotencyKey(String value) =>
      _is.ColumnValue(
        table.issueIdempotencyKey,
        value,
      );

  _is.ColumnValue<int, int> amountKrw(int value) => _is.ColumnValue(
    table.amountKrw,
    value,
  );

  _is.ColumnValue<String, String> priceVersion(String value) => _is.ColumnValue(
    table.priceVersion,
    value,
  );

  _is.ColumnValue<String, String> provider(String value) => _is.ColumnValue(
    table.provider,
    value,
  );
}

class BillingCheckoutTable extends _is.Table<int?> {
  BillingCheckoutTable({super.tableRelation})
    : super(tableName: 'billing_checkout') {
    updateTable = BillingCheckoutUpdateTable(this);
    ownerId = _is.ColumnUuid(
      'ownerId',
      this,
    );
    subscriptionId = _is.ColumnInt(
      'subscriptionId',
      this,
    );
    stateHash = _is.ColumnString(
      'stateHash',
      this,
    );
    expiresUtc = _is.ColumnDateTime(
      'expiresUtc',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    replaceCard = _is.ColumnBool(
      'replaceCard',
      this,
      hasDefault: true,
    );
    termsVersion = _is.ColumnString(
      'termsVersion',
      this,
    );
    acceptedAtUtc = _is.ColumnDateTime(
      'acceptedAtUtc',
      this,
    );
    issueIdempotencyKey = _is.ColumnString(
      'issueIdempotencyKey',
      this,
    );
    amountKrw = _is.ColumnInt(
      'amountKrw',
      this,
      hasDefault: true,
    );
    priceVersion = _is.ColumnString(
      'priceVersion',
      this,
      hasDefault: true,
    );
    provider = _is.ColumnString(
      'provider',
      this,
      hasDefault: true,
    );
  }

  late final BillingCheckoutUpdateTable updateTable;

  late final _is.ColumnUuid ownerId;

  late final _is.ColumnInt subscriptionId;

  late final _is.ColumnString stateHash;

  late final _is.ColumnDateTime expiresUtc;

  late final _is.ColumnString status;

  late final _is.ColumnBool replaceCard;

  late final _is.ColumnString termsVersion;

  late final _is.ColumnDateTime acceptedAtUtc;

  late final _is.ColumnString issueIdempotencyKey;

  late final _is.ColumnInt amountKrw;

  late final _is.ColumnString priceVersion;

  late final _is.ColumnString provider;

  @override
  List<_is.Column> get columns => [
    id,
    ownerId,
    subscriptionId,
    stateHash,
    expiresUtc,
    status,
    replaceCard,
    termsVersion,
    acceptedAtUtc,
    issueIdempotencyKey,
    amountKrw,
    priceVersion,
    provider,
  ];
}

class BillingCheckoutInclude extends _is.IncludeObject {
  BillingCheckoutInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BillingCheckout.t;
}

class BillingCheckoutIncludeList extends _is.IncludeList {
  BillingCheckoutIncludeList._({
    _is.WhereExpressionBuilder<BillingCheckoutTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BillingCheckout.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BillingCheckout.t;
}

class BillingCheckoutRepository {
  const BillingCheckoutRepository._();

  /// Returns a list of [BillingCheckout]s matching the given query parameters.
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
  Future<List<BillingCheckout>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingCheckoutTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingCheckoutTable>? orderBy,
    _is.OrderByListBuilder<BillingCheckoutTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BillingCheckout>(
      where: where?.call(BillingCheckout.t),
      orderBy: orderBy?.call(BillingCheckout.t),
      orderByList: orderByList?.call(BillingCheckout.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BillingCheckout] matching the given query parameters.
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
  Future<BillingCheckout?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingCheckoutTable>? where,
    int? offset,
    _is.OrderByBuilder<BillingCheckoutTable>? orderBy,
    _is.OrderByListBuilder<BillingCheckoutTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BillingCheckout>(
      where: where?.call(BillingCheckout.t),
      orderBy: orderBy?.call(BillingCheckout.t),
      orderByList: orderByList?.call(BillingCheckout.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BillingCheckout] by its [id] or null if no such row exists.
  Future<BillingCheckout?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BillingCheckout>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BillingCheckout]s in the list and returns the inserted rows.
  ///
  /// The returned [BillingCheckout]s will have their `id` fields set.
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
  Future<List<BillingCheckout>> insert(
    _is.DatabaseSession session,
    List<BillingCheckout> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BillingCheckout>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BillingCheckout] and returns the inserted row.
  ///
  /// The returned [BillingCheckout] will have its `id` field set.
  Future<BillingCheckout> insertRow(
    _is.DatabaseSession session,
    BillingCheckout row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BillingCheckout>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BillingCheckout]s in the list and returns the resulting rows.
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
  /// The returned [BillingCheckout]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingCheckout>> upsert(
    _is.DatabaseSession session,
    List<BillingCheckout> rows, {
    required _is.ColumnSelections<BillingCheckoutTable> conflictColumns,
    _is.ColumnSelections<BillingCheckoutTable>? updateColumns,
    _is.WhereExpressionBuilder<BillingCheckoutTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BillingCheckout>(
      rows,
      conflictColumns: conflictColumns(BillingCheckout.t),
      updateColumns: updateColumns?.call(BillingCheckout.t),
      updateWhere: updateWhere?.call(BillingCheckout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BillingCheckout] and returns the resulting row.
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
  /// The returned [BillingCheckout] will have its `id` field set.
  Future<BillingCheckout?> upsertRow(
    _is.DatabaseSession session,
    BillingCheckout row, {
    required _is.ColumnSelections<BillingCheckoutTable> conflictColumns,
    _is.ColumnSelections<BillingCheckoutTable>? updateColumns,
    _is.WhereExpressionBuilder<BillingCheckoutTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BillingCheckout>(
      row,
      conflictColumns: conflictColumns(BillingCheckout.t),
      updateColumns: updateColumns?.call(BillingCheckout.t),
      updateWhere: updateWhere?.call(BillingCheckout.t),
      transaction: transaction,
    );
  }

  /// Updates all [BillingCheckout]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingCheckout>> update(
    _is.DatabaseSession session,
    List<BillingCheckout> rows, {
    _is.ColumnSelections<BillingCheckoutTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BillingCheckout>(
      rows,
      columns: columns?.call(BillingCheckout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BillingCheckout]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BillingCheckout> updateRow(
    _is.DatabaseSession session,
    BillingCheckout row, {
    _is.ColumnSelections<BillingCheckoutTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BillingCheckout>(
      row,
      columns: columns?.call(BillingCheckout.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BillingCheckout] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BillingCheckout?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BillingCheckoutUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BillingCheckout>(
      id,
      columnValues: columnValues(BillingCheckout.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BillingCheckout]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingCheckout>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BillingCheckoutUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<BillingCheckoutTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingCheckoutTable>? orderBy,
    _is.OrderByListBuilder<BillingCheckoutTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BillingCheckout>(
      columnValues: columnValues(BillingCheckout.t.updateTable),
      where: where(BillingCheckout.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BillingCheckout.t),
      orderByList: orderByList?.call(BillingCheckout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BillingCheckout]s in the list and returns the deleted rows.
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
  Future<List<BillingCheckout>> delete(
    _is.DatabaseSession session,
    List<BillingCheckout> rows, {
    _is.OrderByBuilder<BillingCheckoutTable>? orderBy,
    _is.OrderByListBuilder<BillingCheckoutTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BillingCheckout>(
      rows,
      orderBy: orderBy?.call(BillingCheckout.t),
      orderByList: orderByList?.call(BillingCheckout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BillingCheckout].
  Future<BillingCheckout> deleteRow(
    _is.DatabaseSession session,
    BillingCheckout row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BillingCheckout>(
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
  Future<List<BillingCheckout>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BillingCheckoutTable> where,
    _is.OrderByBuilder<BillingCheckoutTable>? orderBy,
    _is.OrderByListBuilder<BillingCheckoutTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BillingCheckout>(
      where: where(BillingCheckout.t),
      orderBy: orderBy?.call(BillingCheckout.t),
      orderByList: orderByList?.call(BillingCheckout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingCheckoutTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BillingCheckout>(
      where: where?.call(BillingCheckout.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BillingCheckout] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BillingCheckoutTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BillingCheckout>(
      where: where(BillingCheckout.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
