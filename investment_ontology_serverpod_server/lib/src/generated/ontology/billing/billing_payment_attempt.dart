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

abstract class BillingPaymentAttempt
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BillingPaymentAttempt._({
    this.id,
    required this.subscriptionId,
    required this.period,
    required this.orderId,
    required this.idempotencyKey,
    required this.status,
    this.paymentKey,
    required this.paidFromUtc,
    required this.paidThroughUtc,
    int? amountKrw,
    String? priceVersion,
    String? provider,
    int? retryCount,
    this.chargeStartedUtc,
    this.failedOrderIds,
  }) : amountKrw = amountKrw ?? 2900,
       priceVersion = priceVersion ?? 'legacy-2900',
       provider = provider ?? 'toss',
       retryCount = retryCount ?? 0;

  factory BillingPaymentAttempt({
    int? id,
    required int subscriptionId,
    required int period,
    required String orderId,
    required String idempotencyKey,
    required String status,
    String? paymentKey,
    required DateTime paidFromUtc,
    required DateTime paidThroughUtc,
    int? amountKrw,
    String? priceVersion,
    String? provider,
    int? retryCount,
    DateTime? chargeStartedUtc,
    List<String>? failedOrderIds,
  }) = _BillingPaymentAttemptImpl;

  factory BillingPaymentAttempt.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BillingPaymentAttempt(
      id: jsonSerialization['id'] as int?,
      subscriptionId: jsonSerialization['subscriptionId'] as int,
      period: jsonSerialization['period'] as int,
      orderId: jsonSerialization['orderId'] as String,
      idempotencyKey: jsonSerialization['idempotencyKey'] as String,
      status: jsonSerialization['status'] as String,
      paymentKey: jsonSerialization['paymentKey'] as String?,
      paidFromUtc: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['paidFromUtc'],
      ),
      paidThroughUtc: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['paidThroughUtc'],
      ),
      amountKrw: jsonSerialization['amountKrw'] as int?,
      priceVersion: jsonSerialization['priceVersion'] as String?,
      provider: jsonSerialization['provider'] as String?,
      retryCount: jsonSerialization['retryCount'] as int?,
      chargeStartedUtc: jsonSerialization['chargeStartedUtc'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['chargeStartedUtc'],
            ),
      failedOrderIds: jsonSerialization['failedOrderIds'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<List<String>>(
              jsonSerialization['failedOrderIds'],
            ),
    );
  }

  static final t = BillingPaymentAttemptTable();

  static const db = BillingPaymentAttemptRepository._();

  @override
  int? id;

  int subscriptionId;

  int period;

  String orderId;

  String idempotencyKey;

  String status;

  String? paymentKey;

  DateTime paidFromUtc;

  DateTime paidThroughUtc;

  int amountKrw;

  String priceVersion;

  String provider;

  int retryCount;

  DateTime? chargeStartedUtc;

  List<String>? failedOrderIds;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BillingPaymentAttempt]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BillingPaymentAttempt copyWith({
    int? id,
    int? subscriptionId,
    int? period,
    String? orderId,
    String? idempotencyKey,
    String? status,
    String? paymentKey,
    DateTime? paidFromUtc,
    DateTime? paidThroughUtc,
    int? amountKrw,
    String? priceVersion,
    String? provider,
    int? retryCount,
    DateTime? chargeStartedUtc,
    List<String>? failedOrderIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BillingPaymentAttempt',
      if (id != null) 'id': id,
      'subscriptionId': subscriptionId,
      'period': period,
      'orderId': orderId,
      'idempotencyKey': idempotencyKey,
      'status': status,
      if (paymentKey != null) 'paymentKey': paymentKey,
      'paidFromUtc': paidFromUtc.toJson(),
      'paidThroughUtc': paidThroughUtc.toJson(),
      'amountKrw': amountKrw,
      'priceVersion': priceVersion,
      'provider': provider,
      'retryCount': retryCount,
      if (chargeStartedUtc != null)
        'chargeStartedUtc': chargeStartedUtc?.toJson(),
      if (failedOrderIds != null) 'failedOrderIds': failedOrderIds?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static BillingPaymentAttemptInclude include() {
    return BillingPaymentAttemptInclude._();
  }

  static BillingPaymentAttemptIncludeList includeList({
    _is.WhereExpressionBuilder<BillingPaymentAttemptTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingPaymentAttemptTable>? orderBy,
    _is.OrderByListBuilder<BillingPaymentAttemptTable>? orderByList,
    BillingPaymentAttemptInclude? include,
  }) {
    return BillingPaymentAttemptIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BillingPaymentAttempt.t),
      orderByList: orderByList?.call(BillingPaymentAttempt.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BillingPaymentAttemptImpl extends BillingPaymentAttempt {
  _BillingPaymentAttemptImpl({
    int? id,
    required int subscriptionId,
    required int period,
    required String orderId,
    required String idempotencyKey,
    required String status,
    String? paymentKey,
    required DateTime paidFromUtc,
    required DateTime paidThroughUtc,
    int? amountKrw,
    String? priceVersion,
    String? provider,
    int? retryCount,
    DateTime? chargeStartedUtc,
    List<String>? failedOrderIds,
  }) : super._(
         id: id,
         subscriptionId: subscriptionId,
         period: period,
         orderId: orderId,
         idempotencyKey: idempotencyKey,
         status: status,
         paymentKey: paymentKey,
         paidFromUtc: paidFromUtc,
         paidThroughUtc: paidThroughUtc,
         amountKrw: amountKrw,
         priceVersion: priceVersion,
         provider: provider,
         retryCount: retryCount,
         chargeStartedUtc: chargeStartedUtc,
         failedOrderIds: failedOrderIds,
       );

  /// Returns a shallow copy of this [BillingPaymentAttempt]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BillingPaymentAttempt copyWith({
    Object? id = _Undefined,
    int? subscriptionId,
    int? period,
    String? orderId,
    String? idempotencyKey,
    String? status,
    Object? paymentKey = _Undefined,
    DateTime? paidFromUtc,
    DateTime? paidThroughUtc,
    int? amountKrw,
    String? priceVersion,
    String? provider,
    int? retryCount,
    Object? chargeStartedUtc = _Undefined,
    Object? failedOrderIds = _Undefined,
  }) {
    return BillingPaymentAttempt(
      id: id is int? ? id : this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      period: period ?? this.period,
      orderId: orderId ?? this.orderId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      paymentKey: paymentKey is String? ? paymentKey : this.paymentKey,
      paidFromUtc: paidFromUtc ?? this.paidFromUtc,
      paidThroughUtc: paidThroughUtc ?? this.paidThroughUtc,
      amountKrw: amountKrw ?? this.amountKrw,
      priceVersion: priceVersion ?? this.priceVersion,
      provider: provider ?? this.provider,
      retryCount: retryCount ?? this.retryCount,
      chargeStartedUtc: chargeStartedUtc is DateTime?
          ? chargeStartedUtc
          : this.chargeStartedUtc,
      failedOrderIds: failedOrderIds is List<String>?
          ? failedOrderIds
          : this.failedOrderIds?.map((e0) => e0).toList(),
    );
  }
}

class BillingPaymentAttemptUpdateTable
    extends _is.UpdateTable<BillingPaymentAttemptTable> {
  BillingPaymentAttemptUpdateTable(super.table);

  _is.ColumnValue<int, int> subscriptionId(int value) => _is.ColumnValue(
    table.subscriptionId,
    value,
  );

  _is.ColumnValue<int, int> period(int value) => _is.ColumnValue(
    table.period,
    value,
  );

  _is.ColumnValue<String, String> orderId(String value) => _is.ColumnValue(
    table.orderId,
    value,
  );

  _is.ColumnValue<String, String> idempotencyKey(String value) =>
      _is.ColumnValue(
        table.idempotencyKey,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> paymentKey(String? value) => _is.ColumnValue(
    table.paymentKey,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> paidFromUtc(DateTime value) =>
      _is.ColumnValue(
        table.paidFromUtc,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> paidThroughUtc(DateTime value) =>
      _is.ColumnValue(
        table.paidThroughUtc,
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

  _is.ColumnValue<int, int> retryCount(int value) => _is.ColumnValue(
    table.retryCount,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> chargeStartedUtc(DateTime? value) =>
      _is.ColumnValue(
        table.chargeStartedUtc,
        value,
      );

  _is.ColumnValue<List<String>, List<String>> failedOrderIds(
    List<String>? value,
  ) => _is.ColumnValue(
    table.failedOrderIds,
    value,
  );
}

class BillingPaymentAttemptTable extends _is.Table<int?> {
  BillingPaymentAttemptTable({super.tableRelation})
    : super(tableName: 'billing_payment_attempt') {
    updateTable = BillingPaymentAttemptUpdateTable(this);
    subscriptionId = _is.ColumnInt(
      'subscriptionId',
      this,
    );
    period = _is.ColumnInt(
      'period',
      this,
    );
    orderId = _is.ColumnString(
      'orderId',
      this,
    );
    idempotencyKey = _is.ColumnString(
      'idempotencyKey',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    paymentKey = _is.ColumnString(
      'paymentKey',
      this,
    );
    paidFromUtc = _is.ColumnDateTime(
      'paidFromUtc',
      this,
    );
    paidThroughUtc = _is.ColumnDateTime(
      'paidThroughUtc',
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
    retryCount = _is.ColumnInt(
      'retryCount',
      this,
      hasDefault: true,
    );
    chargeStartedUtc = _is.ColumnDateTime(
      'chargeStartedUtc',
      this,
    );
    failedOrderIds = _is.ColumnSerializable<List<String>>(
      'failedOrderIds',
      this,
    );
  }

  late final BillingPaymentAttemptUpdateTable updateTable;

  late final _is.ColumnInt subscriptionId;

  late final _is.ColumnInt period;

  late final _is.ColumnString orderId;

  late final _is.ColumnString idempotencyKey;

  late final _is.ColumnString status;

  late final _is.ColumnString paymentKey;

  late final _is.ColumnDateTime paidFromUtc;

  late final _is.ColumnDateTime paidThroughUtc;

  late final _is.ColumnInt amountKrw;

  late final _is.ColumnString priceVersion;

  late final _is.ColumnString provider;

  late final _is.ColumnInt retryCount;

  late final _is.ColumnDateTime chargeStartedUtc;

  late final _is.ColumnSerializable<List<String>> failedOrderIds;

  @override
  List<_is.Column> get columns => [
    id,
    subscriptionId,
    period,
    orderId,
    idempotencyKey,
    status,
    paymentKey,
    paidFromUtc,
    paidThroughUtc,
    amountKrw,
    priceVersion,
    provider,
    retryCount,
    chargeStartedUtc,
    failedOrderIds,
  ];
}

class BillingPaymentAttemptInclude extends _is.IncludeObject {
  BillingPaymentAttemptInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BillingPaymentAttempt.t;
}

class BillingPaymentAttemptIncludeList extends _is.IncludeList {
  BillingPaymentAttemptIncludeList._({
    _is.WhereExpressionBuilder<BillingPaymentAttemptTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BillingPaymentAttempt.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BillingPaymentAttempt.t;
}

class BillingPaymentAttemptRepository {
  const BillingPaymentAttemptRepository._();

  /// Returns a list of [BillingPaymentAttempt]s matching the given query parameters.
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
  Future<List<BillingPaymentAttempt>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingPaymentAttemptTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingPaymentAttemptTable>? orderBy,
    _is.OrderByListBuilder<BillingPaymentAttemptTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BillingPaymentAttempt>(
      where: where?.call(BillingPaymentAttempt.t),
      orderBy: orderBy?.call(BillingPaymentAttempt.t),
      orderByList: orderByList?.call(BillingPaymentAttempt.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BillingPaymentAttempt] matching the given query parameters.
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
  Future<BillingPaymentAttempt?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingPaymentAttemptTable>? where,
    int? offset,
    _is.OrderByBuilder<BillingPaymentAttemptTable>? orderBy,
    _is.OrderByListBuilder<BillingPaymentAttemptTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BillingPaymentAttempt>(
      where: where?.call(BillingPaymentAttempt.t),
      orderBy: orderBy?.call(BillingPaymentAttempt.t),
      orderByList: orderByList?.call(BillingPaymentAttempt.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BillingPaymentAttempt] by its [id] or null if no such row exists.
  Future<BillingPaymentAttempt?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BillingPaymentAttempt>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BillingPaymentAttempt]s in the list and returns the inserted rows.
  ///
  /// The returned [BillingPaymentAttempt]s will have their `id` fields set.
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
  Future<List<BillingPaymentAttempt>> insert(
    _is.DatabaseSession session,
    List<BillingPaymentAttempt> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BillingPaymentAttempt>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BillingPaymentAttempt] and returns the inserted row.
  ///
  /// The returned [BillingPaymentAttempt] will have its `id` field set.
  Future<BillingPaymentAttempt> insertRow(
    _is.DatabaseSession session,
    BillingPaymentAttempt row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BillingPaymentAttempt>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BillingPaymentAttempt]s in the list and returns the resulting rows.
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
  /// The returned [BillingPaymentAttempt]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingPaymentAttempt>> upsert(
    _is.DatabaseSession session,
    List<BillingPaymentAttempt> rows, {
    required _is.ColumnSelections<BillingPaymentAttemptTable> conflictColumns,
    _is.ColumnSelections<BillingPaymentAttemptTable>? updateColumns,
    _is.WhereExpressionBuilder<BillingPaymentAttemptTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BillingPaymentAttempt>(
      rows,
      conflictColumns: conflictColumns(BillingPaymentAttempt.t),
      updateColumns: updateColumns?.call(BillingPaymentAttempt.t),
      updateWhere: updateWhere?.call(BillingPaymentAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BillingPaymentAttempt] and returns the resulting row.
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
  /// The returned [BillingPaymentAttempt] will have its `id` field set.
  Future<BillingPaymentAttempt?> upsertRow(
    _is.DatabaseSession session,
    BillingPaymentAttempt row, {
    required _is.ColumnSelections<BillingPaymentAttemptTable> conflictColumns,
    _is.ColumnSelections<BillingPaymentAttemptTable>? updateColumns,
    _is.WhereExpressionBuilder<BillingPaymentAttemptTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BillingPaymentAttempt>(
      row,
      conflictColumns: conflictColumns(BillingPaymentAttempt.t),
      updateColumns: updateColumns?.call(BillingPaymentAttempt.t),
      updateWhere: updateWhere?.call(BillingPaymentAttempt.t),
      transaction: transaction,
    );
  }

  /// Updates all [BillingPaymentAttempt]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingPaymentAttempt>> update(
    _is.DatabaseSession session,
    List<BillingPaymentAttempt> rows, {
    _is.ColumnSelections<BillingPaymentAttemptTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BillingPaymentAttempt>(
      rows,
      columns: columns?.call(BillingPaymentAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BillingPaymentAttempt]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BillingPaymentAttempt> updateRow(
    _is.DatabaseSession session,
    BillingPaymentAttempt row, {
    _is.ColumnSelections<BillingPaymentAttemptTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BillingPaymentAttempt>(
      row,
      columns: columns?.call(BillingPaymentAttempt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BillingPaymentAttempt] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BillingPaymentAttempt?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BillingPaymentAttemptUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BillingPaymentAttempt>(
      id,
      columnValues: columnValues(BillingPaymentAttempt.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BillingPaymentAttempt]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BillingPaymentAttempt>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BillingPaymentAttemptUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<BillingPaymentAttemptTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BillingPaymentAttemptTable>? orderBy,
    _is.OrderByListBuilder<BillingPaymentAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BillingPaymentAttempt>(
      columnValues: columnValues(BillingPaymentAttempt.t.updateTable),
      where: where(BillingPaymentAttempt.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BillingPaymentAttempt.t),
      orderByList: orderByList?.call(BillingPaymentAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BillingPaymentAttempt]s in the list and returns the deleted rows.
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
  Future<List<BillingPaymentAttempt>> delete(
    _is.DatabaseSession session,
    List<BillingPaymentAttempt> rows, {
    _is.OrderByBuilder<BillingPaymentAttemptTable>? orderBy,
    _is.OrderByListBuilder<BillingPaymentAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BillingPaymentAttempt>(
      rows,
      orderBy: orderBy?.call(BillingPaymentAttempt.t),
      orderByList: orderByList?.call(BillingPaymentAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BillingPaymentAttempt].
  Future<BillingPaymentAttempt> deleteRow(
    _is.DatabaseSession session,
    BillingPaymentAttempt row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BillingPaymentAttempt>(
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
  Future<List<BillingPaymentAttempt>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BillingPaymentAttemptTable> where,
    _is.OrderByBuilder<BillingPaymentAttemptTable>? orderBy,
    _is.OrderByListBuilder<BillingPaymentAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BillingPaymentAttempt>(
      where: where(BillingPaymentAttempt.t),
      orderBy: orderBy?.call(BillingPaymentAttempt.t),
      orderByList: orderByList?.call(BillingPaymentAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BillingPaymentAttemptTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BillingPaymentAttempt>(
      where: where?.call(BillingPaymentAttempt.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BillingPaymentAttempt] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BillingPaymentAttemptTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BillingPaymentAttempt>(
      where: where(BillingPaymentAttempt.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
