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

/// 종목의 하루 시세. 공공데이터포털 금융위원회_주식시세정보(getStockPriceInfo) 응답 한 행.
/// 가격·금액은 원 단위 정수. 등락률처럼 원천 값으로 계산되는 값은 저장하지 않는다.
abstract class MarketSnapshot
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MarketSnapshot._({
    this.id,
    required this.securityId,
    required this.baseDate,
    this.closePrice,
    this.change,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.volume,
    this.tradingValue,
    this.listedShares,
    this.marketCap,
    required this.sourceId,
  });

  factory MarketSnapshot({
    int? id,
    required int securityId,
    required DateTime baseDate,
    BigInt? closePrice,
    BigInt? change,
    BigInt? openPrice,
    BigInt? highPrice,
    BigInt? lowPrice,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? listedShares,
    BigInt? marketCap,
    required int sourceId,
  }) = _MarketSnapshotImpl;

  factory MarketSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketSnapshot(
      id: jsonSerialization['id'] as int?,
      securityId: jsonSerialization['securityId'] as int,
      baseDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['baseDate'],
      ),
      closePrice: jsonSerialization['closePrice'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['closePrice']),
      change: jsonSerialization['change'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['change']),
      openPrice: jsonSerialization['openPrice'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['openPrice']),
      highPrice: jsonSerialization['highPrice'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['highPrice']),
      lowPrice: jsonSerialization['lowPrice'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['lowPrice']),
      volume: jsonSerialization['volume'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['volume']),
      tradingValue: jsonSerialization['tradingValue'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['tradingValue']),
      listedShares: jsonSerialization['listedShares'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['listedShares']),
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
      sourceId: jsonSerialization['sourceId'] as int,
    );
  }

  static final t = MarketSnapshotTable();

  static const db = MarketSnapshotRepository._();

  @override
  int? id;

  int securityId;

  /// 기준일 (UTC 자정)
  DateTime baseDate;

  /// 종가 (clpr)
  BigInt? closePrice;

  /// 전일 대비 (vs)
  BigInt? change;

  /// 시가·고가·저가 (mkp, hipr, lopr)
  BigInt? openPrice;

  BigInt? highPrice;

  BigInt? lowPrice;

  /// 거래량 (trqu)
  BigInt? volume;

  /// 거래대금 (trPrc)
  BigInt? tradingValue;

  /// 상장주식수 (lstgStCnt)
  BigInt? listedShares;

  /// 시가총액 (mrktTotAmt)
  BigInt? marketCap;

  int sourceId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MarketSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MarketSnapshot copyWith({
    int? id,
    int? securityId,
    DateTime? baseDate,
    BigInt? closePrice,
    BigInt? change,
    BigInt? openPrice,
    BigInt? highPrice,
    BigInt? lowPrice,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? listedShares,
    BigInt? marketCap,
    int? sourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketSnapshot',
      if (id != null) 'id': id,
      'securityId': securityId,
      'baseDate': baseDate.toJson(),
      if (closePrice != null) 'closePrice': closePrice?.toJson(),
      if (change != null) 'change': change?.toJson(),
      if (openPrice != null) 'openPrice': openPrice?.toJson(),
      if (highPrice != null) 'highPrice': highPrice?.toJson(),
      if (lowPrice != null) 'lowPrice': lowPrice?.toJson(),
      if (volume != null) 'volume': volume?.toJson(),
      if (tradingValue != null) 'tradingValue': tradingValue?.toJson(),
      if (listedShares != null) 'listedShares': listedShares?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      'sourceId': sourceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketSnapshot',
      if (id != null) 'id': id,
      'securityId': securityId,
      'baseDate': baseDate.toJson(),
      if (closePrice != null) 'closePrice': closePrice?.toJson(),
      if (change != null) 'change': change?.toJson(),
      if (openPrice != null) 'openPrice': openPrice?.toJson(),
      if (highPrice != null) 'highPrice': highPrice?.toJson(),
      if (lowPrice != null) 'lowPrice': lowPrice?.toJson(),
      if (volume != null) 'volume': volume?.toJson(),
      if (tradingValue != null) 'tradingValue': tradingValue?.toJson(),
      if (listedShares != null) 'listedShares': listedShares?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      'sourceId': sourceId,
    };
  }

  static MarketSnapshotInclude include() {
    return MarketSnapshotInclude._();
  }

  static MarketSnapshotIncludeList includeList({
    _is.WhereExpressionBuilder<MarketSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotTable>? orderByList,
    MarketSnapshotInclude? include,
  }) {
    return MarketSnapshotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MarketSnapshot.t),
      orderByList: orderByList?.call(MarketSnapshot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketSnapshotImpl extends MarketSnapshot {
  _MarketSnapshotImpl({
    int? id,
    required int securityId,
    required DateTime baseDate,
    BigInt? closePrice,
    BigInt? change,
    BigInt? openPrice,
    BigInt? highPrice,
    BigInt? lowPrice,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? listedShares,
    BigInt? marketCap,
    required int sourceId,
  }) : super._(
         id: id,
         securityId: securityId,
         baseDate: baseDate,
         closePrice: closePrice,
         change: change,
         openPrice: openPrice,
         highPrice: highPrice,
         lowPrice: lowPrice,
         volume: volume,
         tradingValue: tradingValue,
         listedShares: listedShares,
         marketCap: marketCap,
         sourceId: sourceId,
       );

  /// Returns a shallow copy of this [MarketSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MarketSnapshot copyWith({
    Object? id = _Undefined,
    int? securityId,
    DateTime? baseDate,
    Object? closePrice = _Undefined,
    Object? change = _Undefined,
    Object? openPrice = _Undefined,
    Object? highPrice = _Undefined,
    Object? lowPrice = _Undefined,
    Object? volume = _Undefined,
    Object? tradingValue = _Undefined,
    Object? listedShares = _Undefined,
    Object? marketCap = _Undefined,
    int? sourceId,
  }) {
    return MarketSnapshot(
      id: id is int? ? id : this.id,
      securityId: securityId ?? this.securityId,
      baseDate: baseDate ?? this.baseDate,
      closePrice: closePrice is BigInt? ? closePrice : this.closePrice,
      change: change is BigInt? ? change : this.change,
      openPrice: openPrice is BigInt? ? openPrice : this.openPrice,
      highPrice: highPrice is BigInt? ? highPrice : this.highPrice,
      lowPrice: lowPrice is BigInt? ? lowPrice : this.lowPrice,
      volume: volume is BigInt? ? volume : this.volume,
      tradingValue: tradingValue is BigInt? ? tradingValue : this.tradingValue,
      listedShares: listedShares is BigInt? ? listedShares : this.listedShares,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}

class MarketSnapshotUpdateTable extends _is.UpdateTable<MarketSnapshotTable> {
  MarketSnapshotUpdateTable(super.table);

  _is.ColumnValue<int, int> securityId(int value) => _is.ColumnValue(
    table.securityId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> baseDate(DateTime value) =>
      _is.ColumnValue(
        table.baseDate,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> closePrice(BigInt? value) => _is.ColumnValue(
    table.closePrice,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> change(BigInt? value) => _is.ColumnValue(
    table.change,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> openPrice(BigInt? value) => _is.ColumnValue(
    table.openPrice,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> highPrice(BigInt? value) => _is.ColumnValue(
    table.highPrice,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> lowPrice(BigInt? value) => _is.ColumnValue(
    table.lowPrice,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> volume(BigInt? value) => _is.ColumnValue(
    table.volume,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> tradingValue(BigInt? value) =>
      _is.ColumnValue(
        table.tradingValue,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> listedShares(BigInt? value) =>
      _is.ColumnValue(
        table.listedShares,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> marketCap(BigInt? value) => _is.ColumnValue(
    table.marketCap,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int value) => _is.ColumnValue(
    table.sourceId,
    value,
  );
}

class MarketSnapshotTable extends _is.Table<int?> {
  MarketSnapshotTable({super.tableRelation})
    : super(tableName: 'market_snapshot') {
    updateTable = MarketSnapshotUpdateTable(this);
    securityId = _is.ColumnInt(
      'securityId',
      this,
    );
    baseDate = _is.ColumnDateTime(
      'baseDate',
      this,
    );
    closePrice = _is.ColumnBigInt(
      'closePrice',
      this,
    );
    change = _is.ColumnBigInt(
      'change',
      this,
    );
    openPrice = _is.ColumnBigInt(
      'openPrice',
      this,
    );
    highPrice = _is.ColumnBigInt(
      'highPrice',
      this,
    );
    lowPrice = _is.ColumnBigInt(
      'lowPrice',
      this,
    );
    volume = _is.ColumnBigInt(
      'volume',
      this,
    );
    tradingValue = _is.ColumnBigInt(
      'tradingValue',
      this,
    );
    listedShares = _is.ColumnBigInt(
      'listedShares',
      this,
    );
    marketCap = _is.ColumnBigInt(
      'marketCap',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
  }

  late final MarketSnapshotUpdateTable updateTable;

  late final _is.ColumnInt securityId;

  /// 기준일 (UTC 자정)
  late final _is.ColumnDateTime baseDate;

  /// 종가 (clpr)
  late final _is.ColumnBigInt closePrice;

  /// 전일 대비 (vs)
  late final _is.ColumnBigInt change;

  /// 시가·고가·저가 (mkp, hipr, lopr)
  late final _is.ColumnBigInt openPrice;

  late final _is.ColumnBigInt highPrice;

  late final _is.ColumnBigInt lowPrice;

  /// 거래량 (trqu)
  late final _is.ColumnBigInt volume;

  /// 거래대금 (trPrc)
  late final _is.ColumnBigInt tradingValue;

  /// 상장주식수 (lstgStCnt)
  late final _is.ColumnBigInt listedShares;

  /// 시가총액 (mrktTotAmt)
  late final _is.ColumnBigInt marketCap;

  late final _is.ColumnInt sourceId;

  @override
  List<_is.Column> get columns => [
    id,
    securityId,
    baseDate,
    closePrice,
    change,
    openPrice,
    highPrice,
    lowPrice,
    volume,
    tradingValue,
    listedShares,
    marketCap,
    sourceId,
  ];
}

class MarketSnapshotInclude extends _is.IncludeObject {
  MarketSnapshotInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MarketSnapshot.t;
}

class MarketSnapshotIncludeList extends _is.IncludeList {
  MarketSnapshotIncludeList._({
    _is.WhereExpressionBuilder<MarketSnapshotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MarketSnapshot.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MarketSnapshot.t;
}

class MarketSnapshotRepository {
  const MarketSnapshotRepository._();

  /// Returns a list of [MarketSnapshot]s matching the given query parameters.
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
  Future<List<MarketSnapshot>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MarketSnapshot>(
      where: where?.call(MarketSnapshot.t),
      orderBy: orderBy?.call(MarketSnapshot.t),
      orderByList: orderByList?.call(MarketSnapshot.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MarketSnapshot] matching the given query parameters.
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
  Future<MarketSnapshot?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketSnapshotTable>? where,
    int? offset,
    _is.OrderByBuilder<MarketSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MarketSnapshot>(
      where: where?.call(MarketSnapshot.t),
      orderBy: orderBy?.call(MarketSnapshot.t),
      orderByList: orderByList?.call(MarketSnapshot.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MarketSnapshot] by its [id] or null if no such row exists.
  Future<MarketSnapshot?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MarketSnapshot>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MarketSnapshot]s in the list and returns the inserted rows.
  ///
  /// The returned [MarketSnapshot]s will have their `id` fields set.
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
  Future<List<MarketSnapshot>> insert(
    _is.DatabaseSession session,
    List<MarketSnapshot> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MarketSnapshot>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MarketSnapshot] and returns the inserted row.
  ///
  /// The returned [MarketSnapshot] will have its `id` field set.
  Future<MarketSnapshot> insertRow(
    _is.DatabaseSession session,
    MarketSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MarketSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MarketSnapshot]s in the list and returns the resulting rows.
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
  /// The returned [MarketSnapshot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketSnapshot>> upsert(
    _is.DatabaseSession session,
    List<MarketSnapshot> rows, {
    required _is.ColumnSelections<MarketSnapshotTable> conflictColumns,
    _is.ColumnSelections<MarketSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<MarketSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MarketSnapshot>(
      rows,
      conflictColumns: conflictColumns(MarketSnapshot.t),
      updateColumns: updateColumns?.call(MarketSnapshot.t),
      updateWhere: updateWhere?.call(MarketSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MarketSnapshot] and returns the resulting row.
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
  /// The returned [MarketSnapshot] will have its `id` field set.
  Future<MarketSnapshot?> upsertRow(
    _is.DatabaseSession session,
    MarketSnapshot row, {
    required _is.ColumnSelections<MarketSnapshotTable> conflictColumns,
    _is.ColumnSelections<MarketSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<MarketSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MarketSnapshot>(
      row,
      conflictColumns: conflictColumns(MarketSnapshot.t),
      updateColumns: updateColumns?.call(MarketSnapshot.t),
      updateWhere: updateWhere?.call(MarketSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates all [MarketSnapshot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketSnapshot>> update(
    _is.DatabaseSession session,
    List<MarketSnapshot> rows, {
    _is.ColumnSelections<MarketSnapshotTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MarketSnapshot>(
      rows,
      columns: columns?.call(MarketSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MarketSnapshot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MarketSnapshot> updateRow(
    _is.DatabaseSession session,
    MarketSnapshot row, {
    _is.ColumnSelections<MarketSnapshotTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MarketSnapshot>(
      row,
      columns: columns?.call(MarketSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MarketSnapshot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MarketSnapshot?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MarketSnapshotUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MarketSnapshot>(
      id,
      columnValues: columnValues(MarketSnapshot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MarketSnapshot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketSnapshot>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MarketSnapshotUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MarketSnapshotTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MarketSnapshot>(
      columnValues: columnValues(MarketSnapshot.t.updateTable),
      where: where(MarketSnapshot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MarketSnapshot.t),
      orderByList: orderByList?.call(MarketSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MarketSnapshot]s in the list and returns the deleted rows.
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
  Future<List<MarketSnapshot>> delete(
    _is.DatabaseSession session,
    List<MarketSnapshot> rows, {
    _is.OrderByBuilder<MarketSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MarketSnapshot>(
      rows,
      orderBy: orderBy?.call(MarketSnapshot.t),
      orderByList: orderByList?.call(MarketSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MarketSnapshot].
  Future<MarketSnapshot> deleteRow(
    _is.DatabaseSession session,
    MarketSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MarketSnapshot>(
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
  Future<List<MarketSnapshot>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MarketSnapshotTable> where,
    _is.OrderByBuilder<MarketSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MarketSnapshot>(
      where: where(MarketSnapshot.t),
      orderBy: orderBy?.call(MarketSnapshot.t),
      orderByList: orderByList?.call(MarketSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketSnapshotTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MarketSnapshot>(
      where: where?.call(MarketSnapshot.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MarketSnapshot] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MarketSnapshotTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MarketSnapshot>(
      where: where(MarketSnapshot.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
