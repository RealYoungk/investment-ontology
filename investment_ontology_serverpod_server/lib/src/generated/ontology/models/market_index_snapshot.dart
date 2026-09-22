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

/// 지수(코스피·코스닥·KRX·테마)의 하루 값. 공공데이터포털 금융위원회_지수시세정보(getStockMarketIndex_V2) 응답 한 행.
/// 지수 값은 원문 소수 그대로, 금액은 원 단위 정수. 등락률처럼 원천 값으로 계산되는 값은 등락률(fltRt)만 원문대로 둔다.
abstract class MarketIndexSnapshot
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MarketIndexSnapshot._({
    this.id,
    required this.baseDate,
    required this.series,
    required this.name,
    required this.close,
    this.change,
    this.changeRate,
    this.open,
    this.high,
    this.low,
    this.volume,
    this.tradingValue,
    this.marketCap,
    this.constituentCount,
    required this.sourceId,
  });

  factory MarketIndexSnapshot({
    int? id,
    required DateTime baseDate,
    required String series,
    required String name,
    required double close,
    double? change,
    double? changeRate,
    double? open,
    double? high,
    double? low,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? marketCap,
    int? constituentCount,
    required int sourceId,
  }) = _MarketIndexSnapshotImpl;

  factory MarketIndexSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketIndexSnapshot(
      id: jsonSerialization['id'] as int?,
      baseDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['baseDate'],
      ),
      series: jsonSerialization['series'] as String,
      name: jsonSerialization['name'] as String,
      close: (jsonSerialization['close'] as num).toDouble(),
      change: (jsonSerialization['change'] as num?)?.toDouble(),
      changeRate: (jsonSerialization['changeRate'] as num?)?.toDouble(),
      open: (jsonSerialization['open'] as num?)?.toDouble(),
      high: (jsonSerialization['high'] as num?)?.toDouble(),
      low: (jsonSerialization['low'] as num?)?.toDouble(),
      volume: jsonSerialization['volume'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['volume']),
      tradingValue: jsonSerialization['tradingValue'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['tradingValue']),
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
      constituentCount: jsonSerialization['constituentCount'] as int?,
      sourceId: jsonSerialization['sourceId'] as int,
    );
  }

  static final t = MarketIndexSnapshotTable();

  static const db = MarketIndexSnapshotRepository._();

  @override
  int? id;

  /// 기준일 (UTC 자정)
  DateTime baseDate;

  /// 지수 계열 (idxCsf: KOSPI시리즈 · KOSDAQ시리즈 · KRX시리즈 · 테마시리즈)
  String series;

  /// 지수명 (idxNm: 코스피, 코스닥, IT 서비스 …)
  String name;

  /// 종가 (clpr)
  double close;

  /// 전일 대비 (vs)
  double? change;

  /// 등락률 % (fltRt)
  double? changeRate;

  /// 시가·고가·저가 (mkp, hipr, lopr)
  double? open;

  double? high;

  double? low;

  /// 거래량 (trqu)
  BigInt? volume;

  /// 거래대금 (trPrc)
  BigInt? tradingValue;

  /// 상장시가총액 (lstgMrktTotAmt)
  BigInt? marketCap;

  /// 채용 종목 수 (epyItmsCnt)
  int? constituentCount;

  int sourceId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MarketIndexSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MarketIndexSnapshot copyWith({
    int? id,
    DateTime? baseDate,
    String? series,
    String? name,
    double? close,
    double? change,
    double? changeRate,
    double? open,
    double? high,
    double? low,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? marketCap,
    int? constituentCount,
    int? sourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketIndexSnapshot',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'series': series,
      'name': name,
      'close': close,
      if (change != null) 'change': change,
      if (changeRate != null) 'changeRate': changeRate,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (volume != null) 'volume': volume?.toJson(),
      if (tradingValue != null) 'tradingValue': tradingValue?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      if (constituentCount != null) 'constituentCount': constituentCount,
      'sourceId': sourceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketIndexSnapshot',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'series': series,
      'name': name,
      'close': close,
      if (change != null) 'change': change,
      if (changeRate != null) 'changeRate': changeRate,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (volume != null) 'volume': volume?.toJson(),
      if (tradingValue != null) 'tradingValue': tradingValue?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      if (constituentCount != null) 'constituentCount': constituentCount,
      'sourceId': sourceId,
    };
  }

  static MarketIndexSnapshotInclude include() {
    return MarketIndexSnapshotInclude._();
  }

  static MarketIndexSnapshotIncludeList includeList({
    _is.WhereExpressionBuilder<MarketIndexSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketIndexSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexSnapshotTable>? orderByList,
    MarketIndexSnapshotInclude? include,
  }) {
    return MarketIndexSnapshotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MarketIndexSnapshot.t),
      orderByList: orderByList?.call(MarketIndexSnapshot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketIndexSnapshotImpl extends MarketIndexSnapshot {
  _MarketIndexSnapshotImpl({
    int? id,
    required DateTime baseDate,
    required String series,
    required String name,
    required double close,
    double? change,
    double? changeRate,
    double? open,
    double? high,
    double? low,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? marketCap,
    int? constituentCount,
    required int sourceId,
  }) : super._(
         id: id,
         baseDate: baseDate,
         series: series,
         name: name,
         close: close,
         change: change,
         changeRate: changeRate,
         open: open,
         high: high,
         low: low,
         volume: volume,
         tradingValue: tradingValue,
         marketCap: marketCap,
         constituentCount: constituentCount,
         sourceId: sourceId,
       );

  /// Returns a shallow copy of this [MarketIndexSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MarketIndexSnapshot copyWith({
    Object? id = _Undefined,
    DateTime? baseDate,
    String? series,
    String? name,
    double? close,
    Object? change = _Undefined,
    Object? changeRate = _Undefined,
    Object? open = _Undefined,
    Object? high = _Undefined,
    Object? low = _Undefined,
    Object? volume = _Undefined,
    Object? tradingValue = _Undefined,
    Object? marketCap = _Undefined,
    Object? constituentCount = _Undefined,
    int? sourceId,
  }) {
    return MarketIndexSnapshot(
      id: id is int? ? id : this.id,
      baseDate: baseDate ?? this.baseDate,
      series: series ?? this.series,
      name: name ?? this.name,
      close: close ?? this.close,
      change: change is double? ? change : this.change,
      changeRate: changeRate is double? ? changeRate : this.changeRate,
      open: open is double? ? open : this.open,
      high: high is double? ? high : this.high,
      low: low is double? ? low : this.low,
      volume: volume is BigInt? ? volume : this.volume,
      tradingValue: tradingValue is BigInt? ? tradingValue : this.tradingValue,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
      constituentCount: constituentCount is int?
          ? constituentCount
          : this.constituentCount,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}

class MarketIndexSnapshotUpdateTable
    extends _is.UpdateTable<MarketIndexSnapshotTable> {
  MarketIndexSnapshotUpdateTable(super.table);

  _is.ColumnValue<DateTime, DateTime> baseDate(DateTime value) =>
      _is.ColumnValue(
        table.baseDate,
        value,
      );

  _is.ColumnValue<String, String> series(String value) => _is.ColumnValue(
    table.series,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<double, double> close(double value) => _is.ColumnValue(
    table.close,
    value,
  );

  _is.ColumnValue<double, double> change(double? value) => _is.ColumnValue(
    table.change,
    value,
  );

  _is.ColumnValue<double, double> changeRate(double? value) => _is.ColumnValue(
    table.changeRate,
    value,
  );

  _is.ColumnValue<double, double> open(double? value) => _is.ColumnValue(
    table.open,
    value,
  );

  _is.ColumnValue<double, double> high(double? value) => _is.ColumnValue(
    table.high,
    value,
  );

  _is.ColumnValue<double, double> low(double? value) => _is.ColumnValue(
    table.low,
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

  _is.ColumnValue<BigInt, BigInt> marketCap(BigInt? value) => _is.ColumnValue(
    table.marketCap,
    value,
  );

  _is.ColumnValue<int, int> constituentCount(int? value) => _is.ColumnValue(
    table.constituentCount,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int value) => _is.ColumnValue(
    table.sourceId,
    value,
  );
}

class MarketIndexSnapshotTable extends _is.Table<int?> {
  MarketIndexSnapshotTable({super.tableRelation})
    : super(tableName: 'market_index_snapshot') {
    updateTable = MarketIndexSnapshotUpdateTable(this);
    baseDate = _is.ColumnDateTime(
      'baseDate',
      this,
    );
    series = _is.ColumnString(
      'series',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    close = _is.ColumnDouble(
      'close',
      this,
    );
    change = _is.ColumnDouble(
      'change',
      this,
    );
    changeRate = _is.ColumnDouble(
      'changeRate',
      this,
    );
    open = _is.ColumnDouble(
      'open',
      this,
    );
    high = _is.ColumnDouble(
      'high',
      this,
    );
    low = _is.ColumnDouble(
      'low',
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
    marketCap = _is.ColumnBigInt(
      'marketCap',
      this,
    );
    constituentCount = _is.ColumnInt(
      'constituentCount',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
  }

  late final MarketIndexSnapshotUpdateTable updateTable;

  /// 기준일 (UTC 자정)
  late final _is.ColumnDateTime baseDate;

  /// 지수 계열 (idxCsf: KOSPI시리즈 · KOSDAQ시리즈 · KRX시리즈 · 테마시리즈)
  late final _is.ColumnString series;

  /// 지수명 (idxNm: 코스피, 코스닥, IT 서비스 …)
  late final _is.ColumnString name;

  /// 종가 (clpr)
  late final _is.ColumnDouble close;

  /// 전일 대비 (vs)
  late final _is.ColumnDouble change;

  /// 등락률 % (fltRt)
  late final _is.ColumnDouble changeRate;

  /// 시가·고가·저가 (mkp, hipr, lopr)
  late final _is.ColumnDouble open;

  late final _is.ColumnDouble high;

  late final _is.ColumnDouble low;

  /// 거래량 (trqu)
  late final _is.ColumnBigInt volume;

  /// 거래대금 (trPrc)
  late final _is.ColumnBigInt tradingValue;

  /// 상장시가총액 (lstgMrktTotAmt)
  late final _is.ColumnBigInt marketCap;

  /// 채용 종목 수 (epyItmsCnt)
  late final _is.ColumnInt constituentCount;

  late final _is.ColumnInt sourceId;

  @override
  List<_is.Column> get columns => [
    id,
    baseDate,
    series,
    name,
    close,
    change,
    changeRate,
    open,
    high,
    low,
    volume,
    tradingValue,
    marketCap,
    constituentCount,
    sourceId,
  ];
}

class MarketIndexSnapshotInclude extends _is.IncludeObject {
  MarketIndexSnapshotInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MarketIndexSnapshot.t;
}

class MarketIndexSnapshotIncludeList extends _is.IncludeList {
  MarketIndexSnapshotIncludeList._({
    _is.WhereExpressionBuilder<MarketIndexSnapshotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MarketIndexSnapshot.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MarketIndexSnapshot.t;
}

class MarketIndexSnapshotRepository {
  const MarketIndexSnapshotRepository._();

  /// Returns a list of [MarketIndexSnapshot]s matching the given query parameters.
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
  Future<List<MarketIndexSnapshot>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketIndexSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketIndexSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MarketIndexSnapshot>(
      where: where?.call(MarketIndexSnapshot.t),
      orderBy: orderBy?.call(MarketIndexSnapshot.t),
      orderByList: orderByList?.call(MarketIndexSnapshot.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MarketIndexSnapshot] matching the given query parameters.
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
  Future<MarketIndexSnapshot?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketIndexSnapshotTable>? where,
    int? offset,
    _is.OrderByBuilder<MarketIndexSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MarketIndexSnapshot>(
      where: where?.call(MarketIndexSnapshot.t),
      orderBy: orderBy?.call(MarketIndexSnapshot.t),
      orderByList: orderByList?.call(MarketIndexSnapshot.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MarketIndexSnapshot] by its [id] or null if no such row exists.
  Future<MarketIndexSnapshot?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MarketIndexSnapshot>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MarketIndexSnapshot]s in the list and returns the inserted rows.
  ///
  /// The returned [MarketIndexSnapshot]s will have their `id` fields set.
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
  Future<List<MarketIndexSnapshot>> insert(
    _is.DatabaseSession session,
    List<MarketIndexSnapshot> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MarketIndexSnapshot>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MarketIndexSnapshot] and returns the inserted row.
  ///
  /// The returned [MarketIndexSnapshot] will have its `id` field set.
  Future<MarketIndexSnapshot> insertRow(
    _is.DatabaseSession session,
    MarketIndexSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MarketIndexSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MarketIndexSnapshot]s in the list and returns the resulting rows.
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
  /// The returned [MarketIndexSnapshot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketIndexSnapshot>> upsert(
    _is.DatabaseSession session,
    List<MarketIndexSnapshot> rows, {
    required _is.ColumnSelections<MarketIndexSnapshotTable> conflictColumns,
    _is.ColumnSelections<MarketIndexSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<MarketIndexSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MarketIndexSnapshot>(
      rows,
      conflictColumns: conflictColumns(MarketIndexSnapshot.t),
      updateColumns: updateColumns?.call(MarketIndexSnapshot.t),
      updateWhere: updateWhere?.call(MarketIndexSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MarketIndexSnapshot] and returns the resulting row.
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
  /// The returned [MarketIndexSnapshot] will have its `id` field set.
  Future<MarketIndexSnapshot?> upsertRow(
    _is.DatabaseSession session,
    MarketIndexSnapshot row, {
    required _is.ColumnSelections<MarketIndexSnapshotTable> conflictColumns,
    _is.ColumnSelections<MarketIndexSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<MarketIndexSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MarketIndexSnapshot>(
      row,
      conflictColumns: conflictColumns(MarketIndexSnapshot.t),
      updateColumns: updateColumns?.call(MarketIndexSnapshot.t),
      updateWhere: updateWhere?.call(MarketIndexSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates all [MarketIndexSnapshot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketIndexSnapshot>> update(
    _is.DatabaseSession session,
    List<MarketIndexSnapshot> rows, {
    _is.ColumnSelections<MarketIndexSnapshotTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MarketIndexSnapshot>(
      rows,
      columns: columns?.call(MarketIndexSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MarketIndexSnapshot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MarketIndexSnapshot> updateRow(
    _is.DatabaseSession session,
    MarketIndexSnapshot row, {
    _is.ColumnSelections<MarketIndexSnapshotTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MarketIndexSnapshot>(
      row,
      columns: columns?.call(MarketIndexSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MarketIndexSnapshot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MarketIndexSnapshot?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MarketIndexSnapshotUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MarketIndexSnapshot>(
      id,
      columnValues: columnValues(MarketIndexSnapshot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MarketIndexSnapshot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketIndexSnapshot>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MarketIndexSnapshotUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<MarketIndexSnapshotTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketIndexSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MarketIndexSnapshot>(
      columnValues: columnValues(MarketIndexSnapshot.t.updateTable),
      where: where(MarketIndexSnapshot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MarketIndexSnapshot.t),
      orderByList: orderByList?.call(MarketIndexSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MarketIndexSnapshot]s in the list and returns the deleted rows.
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
  Future<List<MarketIndexSnapshot>> delete(
    _is.DatabaseSession session,
    List<MarketIndexSnapshot> rows, {
    _is.OrderByBuilder<MarketIndexSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MarketIndexSnapshot>(
      rows,
      orderBy: orderBy?.call(MarketIndexSnapshot.t),
      orderByList: orderByList?.call(MarketIndexSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MarketIndexSnapshot].
  Future<MarketIndexSnapshot> deleteRow(
    _is.DatabaseSession session,
    MarketIndexSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MarketIndexSnapshot>(
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
  Future<List<MarketIndexSnapshot>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MarketIndexSnapshotTable> where,
    _is.OrderByBuilder<MarketIndexSnapshotTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MarketIndexSnapshot>(
      where: where(MarketIndexSnapshot.t),
      orderBy: orderBy?.call(MarketIndexSnapshot.t),
      orderByList: orderByList?.call(MarketIndexSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketIndexSnapshotTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MarketIndexSnapshot>(
      where: where?.call(MarketIndexSnapshot.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MarketIndexSnapshot] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MarketIndexSnapshotTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MarketIndexSnapshot>(
      where: where(MarketIndexSnapshot.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
