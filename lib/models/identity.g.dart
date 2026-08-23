// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIdentityCollection on Isar {
  IsarCollection<Identity> get identitys => this.collection();
}

const IdentitySchema = CollectionSchema(
  name: r'Identity',
  id: 1410733637558640605,
  properties: {
    r'linkedHabitIds': PropertySchema(
      id: 0,
      name: r'linkedHabitIds',
      type: IsarType.stringList,
    ),
    r'statement': PropertySchema(
      id: 1,
      name: r'statement',
      type: IsarType.string,
    )
  },
  estimateSize: _identityEstimateSize,
  serialize: _identitySerialize,
  deserialize: _identityDeserialize,
  deserializeProp: _identityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _identityGetId,
  getLinks: _identityGetLinks,
  attach: _identityAttach,
  version: '3.1.0+1',
);

int _identityEstimateSize(
  Identity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.linkedHabitIds.length * 3;
  {
    for (var i = 0; i < object.linkedHabitIds.length; i++) {
      final value = object.linkedHabitIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.statement.length * 3;
  return bytesCount;
}

void _identitySerialize(
  Identity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.linkedHabitIds);
  writer.writeString(offsets[1], object.statement);
}

Identity _identityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Identity();
  object.id = id;
  object.linkedHabitIds = reader.readStringList(offsets[0]) ?? [];
  object.statement = reader.readString(offsets[1]);
  return object;
}

P _identityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _identityGetId(Identity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _identityGetLinks(Identity object) {
  return [];
}

void _identityAttach(IsarCollection<dynamic> col, Id id, Identity object) {
  object.id = id;
}

extension IdentityQueryWhereSort on QueryBuilder<Identity, Identity, QWhere> {
  QueryBuilder<Identity, Identity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IdentityQueryWhere on QueryBuilder<Identity, Identity, QWhereClause> {
  QueryBuilder<Identity, Identity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Identity, Identity, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Identity, Identity, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Identity, Identity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IdentityQueryFilter
    on QueryBuilder<Identity, Identity, QFilterCondition> {
  QueryBuilder<Identity, Identity, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkedHabitIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linkedHabitIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linkedHabitIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linkedHabitIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'linkedHabitIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'linkedHabitIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'linkedHabitIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'linkedHabitIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkedHabitIds',
        value: '',
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'linkedHabitIds',
        value: '',
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linkedHabitIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linkedHabitIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linkedHabitIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linkedHabitIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linkedHabitIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      linkedHabitIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linkedHabitIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statement',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statement',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition> statementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statement',
        value: '',
      ));
    });
  }

  QueryBuilder<Identity, Identity, QAfterFilterCondition>
      statementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statement',
        value: '',
      ));
    });
  }
}

extension IdentityQueryObject
    on QueryBuilder<Identity, Identity, QFilterCondition> {}

extension IdentityQueryLinks
    on QueryBuilder<Identity, Identity, QFilterCondition> {}

extension IdentityQuerySortBy on QueryBuilder<Identity, Identity, QSortBy> {
  QueryBuilder<Identity, Identity, QAfterSortBy> sortByStatement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statement', Sort.asc);
    });
  }

  QueryBuilder<Identity, Identity, QAfterSortBy> sortByStatementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statement', Sort.desc);
    });
  }
}

extension IdentityQuerySortThenBy
    on QueryBuilder<Identity, Identity, QSortThenBy> {
  QueryBuilder<Identity, Identity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Identity, Identity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Identity, Identity, QAfterSortBy> thenByStatement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statement', Sort.asc);
    });
  }

  QueryBuilder<Identity, Identity, QAfterSortBy> thenByStatementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statement', Sort.desc);
    });
  }
}

extension IdentityQueryWhereDistinct
    on QueryBuilder<Identity, Identity, QDistinct> {
  QueryBuilder<Identity, Identity, QDistinct> distinctByLinkedHabitIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linkedHabitIds');
    });
  }

  QueryBuilder<Identity, Identity, QDistinct> distinctByStatement(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statement', caseSensitive: caseSensitive);
    });
  }
}

extension IdentityQueryProperty
    on QueryBuilder<Identity, Identity, QQueryProperty> {
  QueryBuilder<Identity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Identity, List<String>, QQueryOperations>
      linkedHabitIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linkedHabitIds');
    });
  }

  QueryBuilder<Identity, String, QQueryOperations> statementProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statement');
    });
  }
}
