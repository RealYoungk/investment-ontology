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
import '../../ontology/models/business_product.dart' as _inhnrb3l;

abstract class BusinessProfile
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BusinessProfile._({
    this.id,
    required this.documentId,
    required this.ruleVersion,
    required this.products,
    required this.computedAt,
  });

  factory BusinessProfile({
    int? id,
    required int documentId,
    required int ruleVersion,
    required List<_inhnrb3l.BusinessProduct> products,
    required DateTime computedAt,
  }) = _BusinessProfileImpl;

  factory BusinessProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessProfile(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      ruleVersion: jsonSerialization['ruleVersion'] as int,
      products: _i4yshtjp.Protocol()
          .deserialize<List<_inhnrb3l.BusinessProduct>>(
            jsonSerialization['products'],
          ),
      computedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['computedAt'],
      ),
    );
  }

  static final t = BusinessProfileTable();

  static const db = BusinessProfileRepository._();

  @override
  int? id;

  int documentId;

  int ruleVersion;

  List<_inhnrb3l.BusinessProduct> products;

  DateTime computedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BusinessProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessProfile copyWith({
    int? id,
    int? documentId,
    int? ruleVersion,
    List<_inhnrb3l.BusinessProduct>? products,
    DateTime? computedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessProfile',
      if (id != null) 'id': id,
      'documentId': documentId,
      'ruleVersion': ruleVersion,
      'products': products.toJson(valueToJson: (v) => v.toJson()),
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessProfile',
      if (id != null) 'id': id,
      'documentId': documentId,
      'ruleVersion': ruleVersion,
      'products': products.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'computedAt': computedAt.toJson(),
    };
  }

  static BusinessProfileInclude include() {
    return BusinessProfileInclude._();
  }

  static BusinessProfileIncludeList includeList({
    _is.WhereExpressionBuilder<BusinessProfileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessProfileTable>? orderBy,
    _is.OrderByListBuilder<BusinessProfileTable>? orderByList,
    BusinessProfileInclude? include,
  }) {
    return BusinessProfileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BusinessProfile.t),
      orderByList: orderByList?.call(BusinessProfile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BusinessProfileImpl extends BusinessProfile {
  _BusinessProfileImpl({
    int? id,
    required int documentId,
    required int ruleVersion,
    required List<_inhnrb3l.BusinessProduct> products,
    required DateTime computedAt,
  }) : super._(
         id: id,
         documentId: documentId,
         ruleVersion: ruleVersion,
         products: products,
         computedAt: computedAt,
       );

  /// Returns a shallow copy of this [BusinessProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessProfile copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? ruleVersion,
    List<_inhnrb3l.BusinessProduct>? products,
    DateTime? computedAt,
  }) {
    return BusinessProfile(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      products: products ?? this.products.map((e0) => e0.copyWith()).toList(),
      computedAt: computedAt ?? this.computedAt,
    );
  }
}

class BusinessProfileUpdateTable extends _is.UpdateTable<BusinessProfileTable> {
  BusinessProfileUpdateTable(super.table);

  _is.ColumnValue<int, int> documentId(int value) => _is.ColumnValue(
    table.documentId,
    value,
  );

  _is.ColumnValue<int, int> ruleVersion(int value) => _is.ColumnValue(
    table.ruleVersion,
    value,
  );

  _is.ColumnValue<
    List<_inhnrb3l.BusinessProduct>,
    List<_inhnrb3l.BusinessProduct>
  >
  products(List<_inhnrb3l.BusinessProduct> value) => _is.ColumnValue(
    table.products,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> computedAt(DateTime value) =>
      _is.ColumnValue(
        table.computedAt,
        value,
      );
}

class BusinessProfileTable extends _is.Table<int?> {
  BusinessProfileTable({super.tableRelation})
    : super(tableName: 'business_profile') {
    updateTable = BusinessProfileUpdateTable(this);
    documentId = _is.ColumnInt(
      'documentId',
      this,
    );
    ruleVersion = _is.ColumnInt(
      'ruleVersion',
      this,
    );
    products = _is.ColumnSerializable<List<_inhnrb3l.BusinessProduct>>(
      'products',
      this,
    );
    computedAt = _is.ColumnDateTime(
      'computedAt',
      this,
    );
  }

  late final BusinessProfileUpdateTable updateTable;

  late final _is.ColumnInt documentId;

  late final _is.ColumnInt ruleVersion;

  late final _is.ColumnSerializable<List<_inhnrb3l.BusinessProduct>> products;

  late final _is.ColumnDateTime computedAt;

  @override
  List<_is.Column> get columns => [
    id,
    documentId,
    ruleVersion,
    products,
    computedAt,
  ];
}

class BusinessProfileInclude extends _is.IncludeObject {
  BusinessProfileInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BusinessProfile.t;
}

class BusinessProfileIncludeList extends _is.IncludeList {
  BusinessProfileIncludeList._({
    _is.WhereExpressionBuilder<BusinessProfileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BusinessProfile.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BusinessProfile.t;
}

class BusinessProfileRepository {
  const BusinessProfileRepository._();

  /// Returns a list of [BusinessProfile]s matching the given query parameters.
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
  Future<List<BusinessProfile>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessProfileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessProfileTable>? orderBy,
    _is.OrderByListBuilder<BusinessProfileTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BusinessProfile>(
      where: where?.call(BusinessProfile.t),
      orderBy: orderBy?.call(BusinessProfile.t),
      orderByList: orderByList?.call(BusinessProfile.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BusinessProfile] matching the given query parameters.
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
  Future<BusinessProfile?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessProfileTable>? where,
    int? offset,
    _is.OrderByBuilder<BusinessProfileTable>? orderBy,
    _is.OrderByListBuilder<BusinessProfileTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BusinessProfile>(
      where: where?.call(BusinessProfile.t),
      orderBy: orderBy?.call(BusinessProfile.t),
      orderByList: orderByList?.call(BusinessProfile.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BusinessProfile] by its [id] or null if no such row exists.
  Future<BusinessProfile?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BusinessProfile>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BusinessProfile]s in the list and returns the inserted rows.
  ///
  /// The returned [BusinessProfile]s will have their `id` fields set.
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
  Future<List<BusinessProfile>> insert(
    _is.DatabaseSession session,
    List<BusinessProfile> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BusinessProfile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BusinessProfile] and returns the inserted row.
  ///
  /// The returned [BusinessProfile] will have its `id` field set.
  Future<BusinessProfile> insertRow(
    _is.DatabaseSession session,
    BusinessProfile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BusinessProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BusinessProfile]s in the list and returns the resulting rows.
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
  /// The returned [BusinessProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessProfile>> upsert(
    _is.DatabaseSession session,
    List<BusinessProfile> rows, {
    required _is.ColumnSelections<BusinessProfileTable> conflictColumns,
    _is.ColumnSelections<BusinessProfileTable>? updateColumns,
    _is.WhereExpressionBuilder<BusinessProfileTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BusinessProfile>(
      rows,
      conflictColumns: conflictColumns(BusinessProfile.t),
      updateColumns: updateColumns?.call(BusinessProfile.t),
      updateWhere: updateWhere?.call(BusinessProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BusinessProfile] and returns the resulting row.
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
  /// The returned [BusinessProfile] will have its `id` field set.
  Future<BusinessProfile?> upsertRow(
    _is.DatabaseSession session,
    BusinessProfile row, {
    required _is.ColumnSelections<BusinessProfileTable> conflictColumns,
    _is.ColumnSelections<BusinessProfileTable>? updateColumns,
    _is.WhereExpressionBuilder<BusinessProfileTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BusinessProfile>(
      row,
      conflictColumns: conflictColumns(BusinessProfile.t),
      updateColumns: updateColumns?.call(BusinessProfile.t),
      updateWhere: updateWhere?.call(BusinessProfile.t),
      transaction: transaction,
    );
  }

  /// Updates all [BusinessProfile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessProfile>> update(
    _is.DatabaseSession session,
    List<BusinessProfile> rows, {
    _is.ColumnSelections<BusinessProfileTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BusinessProfile>(
      rows,
      columns: columns?.call(BusinessProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BusinessProfile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BusinessProfile> updateRow(
    _is.DatabaseSession session,
    BusinessProfile row, {
    _is.ColumnSelections<BusinessProfileTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BusinessProfile>(
      row,
      columns: columns?.call(BusinessProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BusinessProfile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BusinessProfile?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BusinessProfileUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BusinessProfile>(
      id,
      columnValues: columnValues(BusinessProfile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BusinessProfile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessProfile>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BusinessProfileUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<BusinessProfileTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessProfileTable>? orderBy,
    _is.OrderByListBuilder<BusinessProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BusinessProfile>(
      columnValues: columnValues(BusinessProfile.t.updateTable),
      where: where(BusinessProfile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BusinessProfile.t),
      orderByList: orderByList?.call(BusinessProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BusinessProfile]s in the list and returns the deleted rows.
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
  Future<List<BusinessProfile>> delete(
    _is.DatabaseSession session,
    List<BusinessProfile> rows, {
    _is.OrderByBuilder<BusinessProfileTable>? orderBy,
    _is.OrderByListBuilder<BusinessProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BusinessProfile>(
      rows,
      orderBy: orderBy?.call(BusinessProfile.t),
      orderByList: orderByList?.call(BusinessProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BusinessProfile].
  Future<BusinessProfile> deleteRow(
    _is.DatabaseSession session,
    BusinessProfile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BusinessProfile>(
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
  Future<List<BusinessProfile>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BusinessProfileTable> where,
    _is.OrderByBuilder<BusinessProfileTable>? orderBy,
    _is.OrderByListBuilder<BusinessProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BusinessProfile>(
      where: where(BusinessProfile.t),
      orderBy: orderBy?.call(BusinessProfile.t),
      orderByList: orderByList?.call(BusinessProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessProfileTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BusinessProfile>(
      where: where?.call(BusinessProfile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BusinessProfile] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BusinessProfileTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BusinessProfile>(
      where: where(BusinessProfile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
