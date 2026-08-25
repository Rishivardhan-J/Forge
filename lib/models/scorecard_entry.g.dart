// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scorecard_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetScorecardEntryCollection on Isar {
  IsarCollection<ScorecardEntry> get scorecardEntrys => this.collection();
}

const ScorecardEntrySchema = CollectionSchema(
  name: r'ScorecardEntry',
  id: 6519173859036438540,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'label': PropertySchema(
      id: 1,
      name: r'label',
      type: IsarType.string,
    ),
    r'verdict': PropertySchema(
      id: 2,
      name: r'verdict',
      type: IsarType.byte,
      enumMap: _ScorecardEntryverdictEnumValueMap,
    )
  },
  estimateSize: _scorecardEntryEstimateSize,
  serialize: _scorecardEntrySerialize,
  deserialize: _scorecardEntryDeserialize,
  deserializeProp: _scorecardEntryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _scorecardEntryGetId,
  getLinks: _scorecardEntryGetLinks,
  attach: _scorecardEntryAttach,
  version: '3.1.0+1',
);

int _scorecardEntryEstimateSize(
  ScorecardEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.label.length * 3;
  return bytesCount;
}

void _scorecardEntrySerialize(
  ScorecardEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.label);
  writer.writeByte(offsets[2], object.verdict.index);
}

ScorecardEntry _scorecardEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ScorecardEntry();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.label = reader.readString(offsets[1]);
  object.verdict =
      _ScorecardEntryverdictValueEnumMap[reader.readByteOrNull(offsets[2])] ??
          ScorecardVerdict.positive;
  return object;
}

P _scorecardEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (_ScorecardEntryverdictValueEnumMap[
              reader.readByteOrNull(offset)] ??
          ScorecardVerdict.positive) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ScorecardEntryverdictEnumValueMap = {
  'positive': 0,
  'negative': 1,
  'neutral': 2,
};
const _ScorecardEntryverdictValueEnumMap = {
  0: ScorecardVerdict.positive,
  1: ScorecardVerdict.negative,
  2: ScorecardVerdict.neutral,
};

Id _scorecardEntryGetId(ScorecardEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _scorecardEntryGetLinks(ScorecardEntry object) {
  return [];
}

void _scorecardEntryAttach(
    IsarCollection<dynamic> col, Id id, ScorecardEntry object) {
  object.id = id;
}

extension ScorecardEntryQueryWhereSort
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QWhere> {
  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ScorecardEntryQueryWhere
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QWhereClause> {
  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterWhereClause> idBetween(
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

extension ScorecardEntryQueryFilter
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QFilterCondition> {
  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      verdictEqualTo(ScorecardVerdict value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verdict',
        value: value,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      verdictGreaterThan(
    ScorecardVerdict value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verdict',
        value: value,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      verdictLessThan(
    ScorecardVerdict value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verdict',
        value: value,
      ));
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterFilterCondition>
      verdictBetween(
    ScorecardVerdict lower,
    ScorecardVerdict upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verdict',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ScorecardEntryQueryObject
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QFilterCondition> {}

extension ScorecardEntryQueryLinks
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QFilterCondition> {}

extension ScorecardEntryQuerySortBy
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QSortBy> {
  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> sortByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> sortByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> sortByVerdict() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verdict', Sort.asc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy>
      sortByVerdictDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verdict', Sort.desc);
    });
  }
}

extension ScorecardEntryQuerySortThenBy
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QSortThenBy> {
  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> thenByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> thenByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy> thenByVerdict() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verdict', Sort.asc);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QAfterSortBy>
      thenByVerdictDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verdict', Sort.desc);
    });
  }
}

extension ScorecardEntryQueryWhereDistinct
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QDistinct> {
  QueryBuilder<ScorecardEntry, ScorecardEntry, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QDistinct> distinctByLabel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'label', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardEntry, QDistinct> distinctByVerdict() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verdict');
    });
  }
}

extension ScorecardEntryQueryProperty
    on QueryBuilder<ScorecardEntry, ScorecardEntry, QQueryProperty> {
  QueryBuilder<ScorecardEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ScorecardEntry, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ScorecardEntry, String, QQueryOperations> labelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'label');
    });
  }

  QueryBuilder<ScorecardEntry, ScorecardVerdict, QQueryOperations>
      verdictProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verdict');
    });
  }
}
