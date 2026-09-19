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
import '../../ontology/models/market.dart' as _igwiku5p;
import '../../ontology/models/security_link_basis.dart' as _ipb681z0;

/// 종목. 식별자는 ISIN. 발행 기업은 법인등록번호 → DART 종목코드 → ISIN 발행체 코드 순서로 잇는다.
abstract class Security
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Security._({
    this.id,
    required this.isinCode,
    required this.shortCode,
    required this.name,
    this.market,
    this.crno,
    this.corpName,
    this.companyId,
    this.linkBasis,
    required this.lastSeenDate,
    this.sourceId,
  });

  factory Security({
    int? id,
    required String isinCode,
    required String shortCode,
    required String name,
    _igwiku5p.Market? market,
    String? crno,
    String? corpName,
    int? companyId,
    _ipb681z0.SecurityLinkBasis? linkBasis,
    required DateTime lastSeenDate,
    int? sourceId,
  }) = _SecurityImpl;

  factory Security.fromJson(Map<String, dynamic> jsonSerialization) {
    return Security(
      id: jsonSerialization['id'] as int?,
      isinCode: jsonSerialization['isinCode'] as String,
      shortCode: jsonSerialization['shortCode'] as String,
      name: jsonSerialization['name'] as String,
      market: jsonSerialization['market'] == null
          ? null
          : _igwiku5p.Market.fromJson((jsonSerialization['market'] as String)),
      crno: jsonSerialization['crno'] as String?,
      corpName: jsonSerialization['corpName'] as String?,
      companyId: jsonSerialization['companyId'] as int?,
      linkBasis: jsonSerialization['linkBasis'] == null
          ? null
          : _ipb681z0.SecurityLinkBasis.fromJson(
              (jsonSerialization['linkBasis'] as String),
            ),
      lastSeenDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenDate'],
      ),
      sourceId: jsonSerialization['sourceId'] as int?,
    );
  }

  static final t = SecurityTable();

  static const db = SecurityRepository._();

  @override
  int? id;

  String isinCode;

  /// 단축코드 (6자리)
  String shortCode;

  String name;

  _igwiku5p.Market? market;

  /// 법인등록번호 (13자리, 숫자만)
  String? crno;

  /// KRX상장종목정보의 법인명
  String? corpName;

  int? companyId;

  /// companyId를 정한 근거
  _ipb681z0.SecurityLinkBasis? linkBasis;

  /// 시세나 상장종목 목록에서 마지막으로 확인한 기준일 (UTC 자정)
  DateTime lastSeenDate;

  /// 종목 정보(이름·시장·법인)의 마지막 출처
  int? sourceId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Security]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Security copyWith({
    int? id,
    String? isinCode,
    String? shortCode,
    String? name,
    _igwiku5p.Market? market,
    String? crno,
    String? corpName,
    int? companyId,
    _ipb681z0.SecurityLinkBasis? linkBasis,
    DateTime? lastSeenDate,
    int? sourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Security',
      if (id != null) 'id': id,
      'isinCode': isinCode,
      'shortCode': shortCode,
      'name': name,
      if (market != null) 'market': market?.toJson(),
      if (crno != null) 'crno': crno,
      if (corpName != null) 'corpName': corpName,
      if (companyId != null) 'companyId': companyId,
      if (linkBasis != null) 'linkBasis': linkBasis?.toJson(),
      'lastSeenDate': lastSeenDate.toJson(),
      if (sourceId != null) 'sourceId': sourceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Security',
      if (id != null) 'id': id,
      'isinCode': isinCode,
      'shortCode': shortCode,
      'name': name,
      if (market != null) 'market': market?.toJson(),
      if (crno != null) 'crno': crno,
      if (corpName != null) 'corpName': corpName,
      if (companyId != null) 'companyId': companyId,
      if (linkBasis != null) 'linkBasis': linkBasis?.toJson(),
      'lastSeenDate': lastSeenDate.toJson(),
      if (sourceId != null) 'sourceId': sourceId,
    };
  }

  static SecurityInclude include() {
    return SecurityInclude._();
  }

  static SecurityIncludeList includeList({
    _is.WhereExpressionBuilder<SecurityTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SecurityTable>? orderBy,
    _is.OrderByListBuilder<SecurityTable>? orderByList,
    SecurityInclude? include,
  }) {
    return SecurityIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Security.t),
      orderByList: orderByList?.call(Security.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SecurityImpl extends Security {
  _SecurityImpl({
    int? id,
    required String isinCode,
    required String shortCode,
    required String name,
    _igwiku5p.Market? market,
    String? crno,
    String? corpName,
    int? companyId,
    _ipb681z0.SecurityLinkBasis? linkBasis,
    required DateTime lastSeenDate,
    int? sourceId,
  }) : super._(
         id: id,
         isinCode: isinCode,
         shortCode: shortCode,
         name: name,
         market: market,
         crno: crno,
         corpName: corpName,
         companyId: companyId,
         linkBasis: linkBasis,
         lastSeenDate: lastSeenDate,
         sourceId: sourceId,
       );

  /// Returns a shallow copy of this [Security]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Security copyWith({
    Object? id = _Undefined,
    String? isinCode,
    String? shortCode,
    String? name,
    Object? market = _Undefined,
    Object? crno = _Undefined,
    Object? corpName = _Undefined,
    Object? companyId = _Undefined,
    Object? linkBasis = _Undefined,
    DateTime? lastSeenDate,
    Object? sourceId = _Undefined,
  }) {
    return Security(
      id: id is int? ? id : this.id,
      isinCode: isinCode ?? this.isinCode,
      shortCode: shortCode ?? this.shortCode,
      name: name ?? this.name,
      market: market is _igwiku5p.Market? ? market : this.market,
      crno: crno is String? ? crno : this.crno,
      corpName: corpName is String? ? corpName : this.corpName,
      companyId: companyId is int? ? companyId : this.companyId,
      linkBasis: linkBasis is _ipb681z0.SecurityLinkBasis?
          ? linkBasis
          : this.linkBasis,
      lastSeenDate: lastSeenDate ?? this.lastSeenDate,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
    );
  }
}

class SecurityUpdateTable extends _is.UpdateTable<SecurityTable> {
  SecurityUpdateTable(super.table);

  _is.ColumnValue<String, String> isinCode(String value) => _is.ColumnValue(
    table.isinCode,
    value,
  );

  _is.ColumnValue<String, String> shortCode(String value) => _is.ColumnValue(
    table.shortCode,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<_igwiku5p.Market, _igwiku5p.Market> market(
    _igwiku5p.Market? value,
  ) => _is.ColumnValue(
    table.market,
    value,
  );

  _is.ColumnValue<String, String> crno(String? value) => _is.ColumnValue(
    table.crno,
    value,
  );

  _is.ColumnValue<String, String> corpName(String? value) => _is.ColumnValue(
    table.corpName,
    value,
  );

  _is.ColumnValue<int, int> companyId(int? value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<_ipb681z0.SecurityLinkBasis, _ipb681z0.SecurityLinkBasis>
  linkBasis(_ipb681z0.SecurityLinkBasis? value) => _is.ColumnValue(
    table.linkBasis,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> lastSeenDate(DateTime value) =>
      _is.ColumnValue(
        table.lastSeenDate,
        value,
      );

  _is.ColumnValue<int, int> sourceId(int? value) => _is.ColumnValue(
    table.sourceId,
    value,
  );
}

class SecurityTable extends _is.Table<int?> {
  SecurityTable({super.tableRelation}) : super(tableName: 'security') {
    updateTable = SecurityUpdateTable(this);
    isinCode = _is.ColumnString(
      'isinCode',
      this,
    );
    shortCode = _is.ColumnString(
      'shortCode',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    market = _is.ColumnEnum(
      'market',
      this,
      _is.EnumSerialization.byName,
    );
    crno = _is.ColumnString(
      'crno',
      this,
    );
    corpName = _is.ColumnString(
      'corpName',
      this,
    );
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    linkBasis = _is.ColumnEnum(
      'linkBasis',
      this,
      _is.EnumSerialization.byName,
    );
    lastSeenDate = _is.ColumnDateTime(
      'lastSeenDate',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
  }

  late final SecurityUpdateTable updateTable;

  late final _is.ColumnString isinCode;

  /// 단축코드 (6자리)
  late final _is.ColumnString shortCode;

  late final _is.ColumnString name;

  late final _is.ColumnEnum<_igwiku5p.Market> market;

  /// 법인등록번호 (13자리, 숫자만)
  late final _is.ColumnString crno;

  /// KRX상장종목정보의 법인명
  late final _is.ColumnString corpName;

  late final _is.ColumnInt companyId;

  /// companyId를 정한 근거
  late final _is.ColumnEnum<_ipb681z0.SecurityLinkBasis> linkBasis;

  /// 시세나 상장종목 목록에서 마지막으로 확인한 기준일 (UTC 자정)
  late final _is.ColumnDateTime lastSeenDate;

  /// 종목 정보(이름·시장·법인)의 마지막 출처
  late final _is.ColumnInt sourceId;

  @override
  List<_is.Column> get columns => [
    id,
    isinCode,
    shortCode,
    name,
    market,
    crno,
    corpName,
    companyId,
    linkBasis,
    lastSeenDate,
    sourceId,
  ];
}

class SecurityInclude extends _is.IncludeObject {
  SecurityInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Security.t;
}

class SecurityIncludeList extends _is.IncludeList {
  SecurityIncludeList._({
    _is.WhereExpressionBuilder<SecurityTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Security.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Security.t;
}

class SecurityRepository {
  const SecurityRepository._();

  /// Returns a list of [Security]s matching the given query parameters.
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
  Future<List<Security>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SecurityTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SecurityTable>? orderBy,
    _is.OrderByListBuilder<SecurityTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Security>(
      where: where?.call(Security.t),
      orderBy: orderBy?.call(Security.t),
      orderByList: orderByList?.call(Security.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Security] matching the given query parameters.
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
  Future<Security?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SecurityTable>? where,
    int? offset,
    _is.OrderByBuilder<SecurityTable>? orderBy,
    _is.OrderByListBuilder<SecurityTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Security>(
      where: where?.call(Security.t),
      orderBy: orderBy?.call(Security.t),
      orderByList: orderByList?.call(Security.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Security] by its [id] or null if no such row exists.
  Future<Security?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Security>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Security]s in the list and returns the inserted rows.
  ///
  /// The returned [Security]s will have their `id` fields set.
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
  Future<List<Security>> insert(
    _is.DatabaseSession session,
    List<Security> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Security>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Security] and returns the inserted row.
  ///
  /// The returned [Security] will have its `id` field set.
  Future<Security> insertRow(
    _is.DatabaseSession session,
    Security row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Security>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Security]s in the list and returns the resulting rows.
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
  /// The returned [Security]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Security>> upsert(
    _is.DatabaseSession session,
    List<Security> rows, {
    required _is.ColumnSelections<SecurityTable> conflictColumns,
    _is.ColumnSelections<SecurityTable>? updateColumns,
    _is.WhereExpressionBuilder<SecurityTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Security>(
      rows,
      conflictColumns: conflictColumns(Security.t),
      updateColumns: updateColumns?.call(Security.t),
      updateWhere: updateWhere?.call(Security.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Security] and returns the resulting row.
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
  /// The returned [Security] will have its `id` field set.
  Future<Security?> upsertRow(
    _is.DatabaseSession session,
    Security row, {
    required _is.ColumnSelections<SecurityTable> conflictColumns,
    _is.ColumnSelections<SecurityTable>? updateColumns,
    _is.WhereExpressionBuilder<SecurityTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Security>(
      row,
      conflictColumns: conflictColumns(Security.t),
      updateColumns: updateColumns?.call(Security.t),
      updateWhere: updateWhere?.call(Security.t),
      transaction: transaction,
    );
  }

  /// Updates all [Security]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Security>> update(
    _is.DatabaseSession session,
    List<Security> rows, {
    _is.ColumnSelections<SecurityTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Security>(
      rows,
      columns: columns?.call(Security.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Security]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Security> updateRow(
    _is.DatabaseSession session,
    Security row, {
    _is.ColumnSelections<SecurityTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Security>(
      row,
      columns: columns?.call(Security.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Security] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Security?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SecurityUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Security>(
      id,
      columnValues: columnValues(Security.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Security]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Security>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SecurityUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SecurityTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SecurityTable>? orderBy,
    _is.OrderByListBuilder<SecurityTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Security>(
      columnValues: columnValues(Security.t.updateTable),
      where: where(Security.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Security.t),
      orderByList: orderByList?.call(Security.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Security]s in the list and returns the deleted rows.
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
  Future<List<Security>> delete(
    _is.DatabaseSession session,
    List<Security> rows, {
    _is.OrderByBuilder<SecurityTable>? orderBy,
    _is.OrderByListBuilder<SecurityTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Security>(
      rows,
      orderBy: orderBy?.call(Security.t),
      orderByList: orderByList?.call(Security.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Security].
  Future<Security> deleteRow(
    _is.DatabaseSession session,
    Security row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Security>(
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
  Future<List<Security>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SecurityTable> where,
    _is.OrderByBuilder<SecurityTable>? orderBy,
    _is.OrderByListBuilder<SecurityTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Security>(
      where: where(Security.t),
      orderBy: orderBy?.call(Security.t),
      orderByList: orderByList?.call(Security.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SecurityTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Security>(
      where: where?.call(Security.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Security] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SecurityTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Security>(
      where: where(Security.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
