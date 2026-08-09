// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DatabaseMetadataTable extends DatabaseMetadata
    with TableInfo<$DatabaseMetadataTable, DatabaseMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatabaseMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'database_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<DatabaseMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DatabaseMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatabaseMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DatabaseMetadataTable createAlias(String alias) {
    return $DatabaseMetadataTable(attachedDatabase, alias);
  }
}

class DatabaseMetadataData extends DataClass
    implements Insertable<DatabaseMetadataData> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const DatabaseMetadataData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DatabaseMetadataCompanion toCompanion(bool nullToAbsent) {
    return DatabaseMetadataCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory DatabaseMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatabaseMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DatabaseMetadataData copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => DatabaseMetadataData(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DatabaseMetadataData copyWithCompanion(DatabaseMetadataCompanion data) {
    return DatabaseMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatabaseMetadataData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class DatabaseMetadataCompanion extends UpdateCompanion<DatabaseMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DatabaseMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DatabaseMetadataCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<DatabaseMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DatabaseMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DatabaseMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessProfilesTable extends BusinessProfiles
    with TableInfo<$BusinessProfilesTable, BusinessProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinCodeMeta = const VerificationMeta(
    'pinCode',
  );
  @override
  late final GeneratedColumn<String> pinCode = GeneratedColumn<String>(
    'pin_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gstRegisteredMeta = const VerificationMeta(
    'gstRegistered',
  );
  @override
  late final GeneratedColumn<bool> gstRegistered = GeneratedColumn<bool>(
    'gst_registered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gst_registered" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
    'gstin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _panMeta = const VerificationMeta('pan');
  @override
  late final GeneratedColumn<String> pan = GeneratedColumn<String>(
    'pan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoicePrefixMeta = const VerificationMeta(
    'invoicePrefix',
  );
  @override
  late final GeneratedColumn<String> invoicePrefix = GeneratedColumn<String>(
    'invoice_prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INV'),
  );
  static const VerificationMeta _startingInvoiceNumberMeta =
      const VerificationMeta('startingInvoiceNumber');
  @override
  late final GeneratedColumn<int> startingInvoiceNumber = GeneratedColumn<int>(
    'starting_invoice_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _currencySymbolMeta = const VerificationMeta(
    'currencySymbol',
  );
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
    'currency_symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('₹'),
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountHolderNameMeta = const VerificationMeta(
    'accountHolderName',
  );
  @override
  late final GeneratedColumn<String> accountHolderName =
      GeneratedColumn<String>(
        'account_holder_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _accountNumberMeta = const VerificationMeta(
    'accountNumber',
  );
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
    'account_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ifscMeta = const VerificationMeta('ifsc');
  @override
  late final GeneratedColumn<String> ifsc = GeneratedColumn<String>(
    'ifsc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _upiIdMeta = const VerificationMeta('upiId');
  @override
  late final GeneratedColumn<String> upiId = GeneratedColumn<String>(
    'upi_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentQrPathMeta = const VerificationMeta(
    'paymentQrPath',
  );
  @override
  late final GeneratedColumn<String> paymentQrPath = GeneratedColumn<String>(
    'payment_qr_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signaturePathMeta = const VerificationMeta(
    'signaturePath',
  );
  @override
  late final GeneratedColumn<String> signaturePath = GeneratedColumn<String>(
    'signature_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessName,
    ownerName,
    logoPath,
    mobile,
    email,
    address,
    city,
    state,
    pinCode,
    gstRegistered,
    gstin,
    pan,
    invoicePrefix,
    startingInvoiceNumber,
    currencyCode,
    currencySymbol,
    bankName,
    accountHolderName,
    accountNumber,
    ifsc,
    upiId,
    paymentQrPath,
    signaturePath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('pin_code')) {
      context.handle(
        _pinCodeMeta,
        pinCode.isAcceptableOrUnknown(data['pin_code']!, _pinCodeMeta),
      );
    }
    if (data.containsKey('gst_registered')) {
      context.handle(
        _gstRegisteredMeta,
        gstRegistered.isAcceptableOrUnknown(
          data['gst_registered']!,
          _gstRegisteredMeta,
        ),
      );
    }
    if (data.containsKey('gstin')) {
      context.handle(
        _gstinMeta,
        gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta),
      );
    }
    if (data.containsKey('pan')) {
      context.handle(
        _panMeta,
        pan.isAcceptableOrUnknown(data['pan']!, _panMeta),
      );
    }
    if (data.containsKey('invoice_prefix')) {
      context.handle(
        _invoicePrefixMeta,
        invoicePrefix.isAcceptableOrUnknown(
          data['invoice_prefix']!,
          _invoicePrefixMeta,
        ),
      );
    }
    if (data.containsKey('starting_invoice_number')) {
      context.handle(
        _startingInvoiceNumberMeta,
        startingInvoiceNumber.isAcceptableOrUnknown(
          data['starting_invoice_number']!,
          _startingInvoiceNumberMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
        _currencySymbolMeta,
        currencySymbol.isAcceptableOrUnknown(
          data['currency_symbol']!,
          _currencySymbolMeta,
        ),
      );
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    }
    if (data.containsKey('account_holder_name')) {
      context.handle(
        _accountHolderNameMeta,
        accountHolderName.isAcceptableOrUnknown(
          data['account_holder_name']!,
          _accountHolderNameMeta,
        ),
      );
    }
    if (data.containsKey('account_number')) {
      context.handle(
        _accountNumberMeta,
        accountNumber.isAcceptableOrUnknown(
          data['account_number']!,
          _accountNumberMeta,
        ),
      );
    }
    if (data.containsKey('ifsc')) {
      context.handle(
        _ifscMeta,
        ifsc.isAcceptableOrUnknown(data['ifsc']!, _ifscMeta),
      );
    }
    if (data.containsKey('upi_id')) {
      context.handle(
        _upiIdMeta,
        upiId.isAcceptableOrUnknown(data['upi_id']!, _upiIdMeta),
      );
    }
    if (data.containsKey('payment_qr_path')) {
      context.handle(
        _paymentQrPathMeta,
        paymentQrPath.isAcceptableOrUnknown(
          data['payment_qr_path']!,
          _paymentQrPathMeta,
        ),
      );
    }
    if (data.containsKey('signature_path')) {
      context.handle(
        _signaturePathMeta,
        signaturePath.isAcceptableOrUnknown(
          data['signature_path']!,
          _signaturePathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      ),
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      pinCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_code'],
      ),
      gstRegistered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gst_registered'],
      )!,
      gstin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gstin'],
      ),
      pan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pan'],
      ),
      invoicePrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_prefix'],
      )!,
      startingInvoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starting_invoice_number'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      currencySymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_symbol'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      ),
      accountHolderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_holder_name'],
      ),
      accountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_number'],
      ),
      ifsc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ifsc'],
      ),
      upiId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upi_id'],
      ),
      paymentQrPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_qr_path'],
      ),
      signaturePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BusinessProfilesTable createAlias(String alias) {
    return $BusinessProfilesTable(attachedDatabase, alias);
  }
}

class BusinessProfile extends DataClass implements Insertable<BusinessProfile> {
  final int id;
  final String businessName;
  final String? ownerName;
  final String? logoPath;
  final String? mobile;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final bool gstRegistered;
  final String? gstin;
  final String? pan;
  final String invoicePrefix;
  final int startingInvoiceNumber;
  final String currencyCode;
  final String currencySymbol;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifsc;
  final String? upiId;
  final String? paymentQrPath;
  final String? signaturePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BusinessProfile({
    required this.id,
    required this.businessName,
    this.ownerName,
    this.logoPath,
    this.mobile,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    required this.gstRegistered,
    this.gstin,
    this.pan,
    required this.invoicePrefix,
    required this.startingInvoiceNumber,
    required this.currencyCode,
    required this.currencySymbol,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.ifsc,
    this.upiId,
    this.paymentQrPath,
    this.signaturePath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['business_name'] = Variable<String>(businessName);
    if (!nullToAbsent || ownerName != null) {
      map['owner_name'] = Variable<String>(ownerName);
    }
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || pinCode != null) {
      map['pin_code'] = Variable<String>(pinCode);
    }
    map['gst_registered'] = Variable<bool>(gstRegistered);
    if (!nullToAbsent || gstin != null) {
      map['gstin'] = Variable<String>(gstin);
    }
    if (!nullToAbsent || pan != null) {
      map['pan'] = Variable<String>(pan);
    }
    map['invoice_prefix'] = Variable<String>(invoicePrefix);
    map['starting_invoice_number'] = Variable<int>(startingInvoiceNumber);
    map['currency_code'] = Variable<String>(currencyCode);
    map['currency_symbol'] = Variable<String>(currencySymbol);
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || accountHolderName != null) {
      map['account_holder_name'] = Variable<String>(accountHolderName);
    }
    if (!nullToAbsent || accountNumber != null) {
      map['account_number'] = Variable<String>(accountNumber);
    }
    if (!nullToAbsent || ifsc != null) {
      map['ifsc'] = Variable<String>(ifsc);
    }
    if (!nullToAbsent || upiId != null) {
      map['upi_id'] = Variable<String>(upiId);
    }
    if (!nullToAbsent || paymentQrPath != null) {
      map['payment_qr_path'] = Variable<String>(paymentQrPath);
    }
    if (!nullToAbsent || signaturePath != null) {
      map['signature_path'] = Variable<String>(signaturePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BusinessProfilesCompanion toCompanion(bool nullToAbsent) {
    return BusinessProfilesCompanion(
      id: Value(id),
      businessName: Value(businessName),
      ownerName: ownerName == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerName),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      mobile: mobile == null && nullToAbsent
          ? const Value.absent()
          : Value(mobile),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      pinCode: pinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCode),
      gstRegistered: Value(gstRegistered),
      gstin: gstin == null && nullToAbsent
          ? const Value.absent()
          : Value(gstin),
      pan: pan == null && nullToAbsent ? const Value.absent() : Value(pan),
      invoicePrefix: Value(invoicePrefix),
      startingInvoiceNumber: Value(startingInvoiceNumber),
      currencyCode: Value(currencyCode),
      currencySymbol: Value(currencySymbol),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      accountHolderName: accountHolderName == null && nullToAbsent
          ? const Value.absent()
          : Value(accountHolderName),
      accountNumber: accountNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(accountNumber),
      ifsc: ifsc == null && nullToAbsent ? const Value.absent() : Value(ifsc),
      upiId: upiId == null && nullToAbsent
          ? const Value.absent()
          : Value(upiId),
      paymentQrPath: paymentQrPath == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentQrPath),
      signaturePath: signaturePath == null && nullToAbsent
          ? const Value.absent()
          : Value(signaturePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BusinessProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessProfile(
      id: serializer.fromJson<int>(json['id']),
      businessName: serializer.fromJson<String>(json['businessName']),
      ownerName: serializer.fromJson<String?>(json['ownerName']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      city: serializer.fromJson<String?>(json['city']),
      state: serializer.fromJson<String?>(json['state']),
      pinCode: serializer.fromJson<String?>(json['pinCode']),
      gstRegistered: serializer.fromJson<bool>(json['gstRegistered']),
      gstin: serializer.fromJson<String?>(json['gstin']),
      pan: serializer.fromJson<String?>(json['pan']),
      invoicePrefix: serializer.fromJson<String>(json['invoicePrefix']),
      startingInvoiceNumber: serializer.fromJson<int>(
        json['startingInvoiceNumber'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      currencySymbol: serializer.fromJson<String>(json['currencySymbol']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      accountHolderName: serializer.fromJson<String?>(
        json['accountHolderName'],
      ),
      accountNumber: serializer.fromJson<String?>(json['accountNumber']),
      ifsc: serializer.fromJson<String?>(json['ifsc']),
      upiId: serializer.fromJson<String?>(json['upiId']),
      paymentQrPath: serializer.fromJson<String?>(json['paymentQrPath']),
      signaturePath: serializer.fromJson<String?>(json['signaturePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'businessName': serializer.toJson<String>(businessName),
      'ownerName': serializer.toJson<String?>(ownerName),
      'logoPath': serializer.toJson<String?>(logoPath),
      'mobile': serializer.toJson<String?>(mobile),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'city': serializer.toJson<String?>(city),
      'state': serializer.toJson<String?>(state),
      'pinCode': serializer.toJson<String?>(pinCode),
      'gstRegistered': serializer.toJson<bool>(gstRegistered),
      'gstin': serializer.toJson<String?>(gstin),
      'pan': serializer.toJson<String?>(pan),
      'invoicePrefix': serializer.toJson<String>(invoicePrefix),
      'startingInvoiceNumber': serializer.toJson<int>(startingInvoiceNumber),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'currencySymbol': serializer.toJson<String>(currencySymbol),
      'bankName': serializer.toJson<String?>(bankName),
      'accountHolderName': serializer.toJson<String?>(accountHolderName),
      'accountNumber': serializer.toJson<String?>(accountNumber),
      'ifsc': serializer.toJson<String?>(ifsc),
      'upiId': serializer.toJson<String?>(upiId),
      'paymentQrPath': serializer.toJson<String?>(paymentQrPath),
      'signaturePath': serializer.toJson<String?>(signaturePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BusinessProfile copyWith({
    int? id,
    String? businessName,
    Value<String?> ownerName = const Value.absent(),
    Value<String?> logoPath = const Value.absent(),
    Value<String?> mobile = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> state = const Value.absent(),
    Value<String?> pinCode = const Value.absent(),
    bool? gstRegistered,
    Value<String?> gstin = const Value.absent(),
    Value<String?> pan = const Value.absent(),
    String? invoicePrefix,
    int? startingInvoiceNumber,
    String? currencyCode,
    String? currencySymbol,
    Value<String?> bankName = const Value.absent(),
    Value<String?> accountHolderName = const Value.absent(),
    Value<String?> accountNumber = const Value.absent(),
    Value<String?> ifsc = const Value.absent(),
    Value<String?> upiId = const Value.absent(),
    Value<String?> paymentQrPath = const Value.absent(),
    Value<String?> signaturePath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BusinessProfile(
    id: id ?? this.id,
    businessName: businessName ?? this.businessName,
    ownerName: ownerName.present ? ownerName.value : this.ownerName,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    mobile: mobile.present ? mobile.value : this.mobile,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    city: city.present ? city.value : this.city,
    state: state.present ? state.value : this.state,
    pinCode: pinCode.present ? pinCode.value : this.pinCode,
    gstRegistered: gstRegistered ?? this.gstRegistered,
    gstin: gstin.present ? gstin.value : this.gstin,
    pan: pan.present ? pan.value : this.pan,
    invoicePrefix: invoicePrefix ?? this.invoicePrefix,
    startingInvoiceNumber: startingInvoiceNumber ?? this.startingInvoiceNumber,
    currencyCode: currencyCode ?? this.currencyCode,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    bankName: bankName.present ? bankName.value : this.bankName,
    accountHolderName: accountHolderName.present
        ? accountHolderName.value
        : this.accountHolderName,
    accountNumber: accountNumber.present
        ? accountNumber.value
        : this.accountNumber,
    ifsc: ifsc.present ? ifsc.value : this.ifsc,
    upiId: upiId.present ? upiId.value : this.upiId,
    paymentQrPath: paymentQrPath.present
        ? paymentQrPath.value
        : this.paymentQrPath,
    signaturePath: signaturePath.present
        ? signaturePath.value
        : this.signaturePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BusinessProfile copyWithCompanion(BusinessProfilesCompanion data) {
    return BusinessProfile(
      id: data.id.present ? data.id.value : this.id,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      pinCode: data.pinCode.present ? data.pinCode.value : this.pinCode,
      gstRegistered: data.gstRegistered.present
          ? data.gstRegistered.value
          : this.gstRegistered,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
      pan: data.pan.present ? data.pan.value : this.pan,
      invoicePrefix: data.invoicePrefix.present
          ? data.invoicePrefix.value
          : this.invoicePrefix,
      startingInvoiceNumber: data.startingInvoiceNumber.present
          ? data.startingInvoiceNumber.value
          : this.startingInvoiceNumber,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      accountHolderName: data.accountHolderName.present
          ? data.accountHolderName.value
          : this.accountHolderName,
      accountNumber: data.accountNumber.present
          ? data.accountNumber.value
          : this.accountNumber,
      ifsc: data.ifsc.present ? data.ifsc.value : this.ifsc,
      upiId: data.upiId.present ? data.upiId.value : this.upiId,
      paymentQrPath: data.paymentQrPath.present
          ? data.paymentQrPath.value
          : this.paymentQrPath,
      signaturePath: data.signaturePath.present
          ? data.signaturePath.value
          : this.signaturePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessProfile(')
          ..write('id: $id, ')
          ..write('businessName: $businessName, ')
          ..write('ownerName: $ownerName, ')
          ..write('logoPath: $logoPath, ')
          ..write('mobile: $mobile, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('pinCode: $pinCode, ')
          ..write('gstRegistered: $gstRegistered, ')
          ..write('gstin: $gstin, ')
          ..write('pan: $pan, ')
          ..write('invoicePrefix: $invoicePrefix, ')
          ..write('startingInvoiceNumber: $startingInvoiceNumber, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('bankName: $bankName, ')
          ..write('accountHolderName: $accountHolderName, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('ifsc: $ifsc, ')
          ..write('upiId: $upiId, ')
          ..write('paymentQrPath: $paymentQrPath, ')
          ..write('signaturePath: $signaturePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessName,
    ownerName,
    logoPath,
    mobile,
    email,
    address,
    city,
    state,
    pinCode,
    gstRegistered,
    gstin,
    pan,
    invoicePrefix,
    startingInvoiceNumber,
    currencyCode,
    currencySymbol,
    bankName,
    accountHolderName,
    accountNumber,
    ifsc,
    upiId,
    paymentQrPath,
    signaturePath,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessProfile &&
          other.id == this.id &&
          other.businessName == this.businessName &&
          other.ownerName == this.ownerName &&
          other.logoPath == this.logoPath &&
          other.mobile == this.mobile &&
          other.email == this.email &&
          other.address == this.address &&
          other.city == this.city &&
          other.state == this.state &&
          other.pinCode == this.pinCode &&
          other.gstRegistered == this.gstRegistered &&
          other.gstin == this.gstin &&
          other.pan == this.pan &&
          other.invoicePrefix == this.invoicePrefix &&
          other.startingInvoiceNumber == this.startingInvoiceNumber &&
          other.currencyCode == this.currencyCode &&
          other.currencySymbol == this.currencySymbol &&
          other.bankName == this.bankName &&
          other.accountHolderName == this.accountHolderName &&
          other.accountNumber == this.accountNumber &&
          other.ifsc == this.ifsc &&
          other.upiId == this.upiId &&
          other.paymentQrPath == this.paymentQrPath &&
          other.signaturePath == this.signaturePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BusinessProfilesCompanion extends UpdateCompanion<BusinessProfile> {
  final Value<int> id;
  final Value<String> businessName;
  final Value<String?> ownerName;
  final Value<String?> logoPath;
  final Value<String?> mobile;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> city;
  final Value<String?> state;
  final Value<String?> pinCode;
  final Value<bool> gstRegistered;
  final Value<String?> gstin;
  final Value<String?> pan;
  final Value<String> invoicePrefix;
  final Value<int> startingInvoiceNumber;
  final Value<String> currencyCode;
  final Value<String> currencySymbol;
  final Value<String?> bankName;
  final Value<String?> accountHolderName;
  final Value<String?> accountNumber;
  final Value<String?> ifsc;
  final Value<String?> upiId;
  final Value<String?> paymentQrPath;
  final Value<String?> signaturePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BusinessProfilesCompanion({
    this.id = const Value.absent(),
    this.businessName = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.mobile = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.gstRegistered = const Value.absent(),
    this.gstin = const Value.absent(),
    this.pan = const Value.absent(),
    this.invoicePrefix = const Value.absent(),
    this.startingInvoiceNumber = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountHolderName = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.ifsc = const Value.absent(),
    this.upiId = const Value.absent(),
    this.paymentQrPath = const Value.absent(),
    this.signaturePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BusinessProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String businessName,
    this.ownerName = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.mobile = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.gstRegistered = const Value.absent(),
    this.gstin = const Value.absent(),
    this.pan = const Value.absent(),
    this.invoicePrefix = const Value.absent(),
    this.startingInvoiceNumber = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountHolderName = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.ifsc = const Value.absent(),
    this.upiId = const Value.absent(),
    this.paymentQrPath = const Value.absent(),
    this.signaturePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : businessName = Value(businessName);
  static Insertable<BusinessProfile> custom({
    Expression<int>? id,
    Expression<String>? businessName,
    Expression<String>? ownerName,
    Expression<String>? logoPath,
    Expression<String>? mobile,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? pinCode,
    Expression<bool>? gstRegistered,
    Expression<String>? gstin,
    Expression<String>? pan,
    Expression<String>? invoicePrefix,
    Expression<int>? startingInvoiceNumber,
    Expression<String>? currencyCode,
    Expression<String>? currencySymbol,
    Expression<String>? bankName,
    Expression<String>? accountHolderName,
    Expression<String>? accountNumber,
    Expression<String>? ifsc,
    Expression<String>? upiId,
    Expression<String>? paymentQrPath,
    Expression<String>? signaturePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessName != null) 'business_name': businessName,
      if (ownerName != null) 'owner_name': ownerName,
      if (logoPath != null) 'logo_path': logoPath,
      if (mobile != null) 'mobile': mobile,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pinCode != null) 'pin_code': pinCode,
      if (gstRegistered != null) 'gst_registered': gstRegistered,
      if (gstin != null) 'gstin': gstin,
      if (pan != null) 'pan': pan,
      if (invoicePrefix != null) 'invoice_prefix': invoicePrefix,
      if (startingInvoiceNumber != null)
        'starting_invoice_number': startingInvoiceNumber,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (bankName != null) 'bank_name': bankName,
      if (accountHolderName != null) 'account_holder_name': accountHolderName,
      if (accountNumber != null) 'account_number': accountNumber,
      if (ifsc != null) 'ifsc': ifsc,
      if (upiId != null) 'upi_id': upiId,
      if (paymentQrPath != null) 'payment_qr_path': paymentQrPath,
      if (signaturePath != null) 'signature_path': signaturePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BusinessProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? businessName,
    Value<String?>? ownerName,
    Value<String?>? logoPath,
    Value<String?>? mobile,
    Value<String?>? email,
    Value<String?>? address,
    Value<String?>? city,
    Value<String?>? state,
    Value<String?>? pinCode,
    Value<bool>? gstRegistered,
    Value<String?>? gstin,
    Value<String?>? pan,
    Value<String>? invoicePrefix,
    Value<int>? startingInvoiceNumber,
    Value<String>? currencyCode,
    Value<String>? currencySymbol,
    Value<String?>? bankName,
    Value<String?>? accountHolderName,
    Value<String?>? accountNumber,
    Value<String?>? ifsc,
    Value<String?>? upiId,
    Value<String?>? paymentQrPath,
    Value<String?>? signaturePath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BusinessProfilesCompanion(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      logoPath: logoPath ?? this.logoPath,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      gstRegistered: gstRegistered ?? this.gstRegistered,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      startingInvoiceNumber:
          startingInvoiceNumber ?? this.startingInvoiceNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      upiId: upiId ?? this.upiId,
      paymentQrPath: paymentQrPath ?? this.paymentQrPath,
      signaturePath: signaturePath ?? this.signaturePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (pinCode.present) {
      map['pin_code'] = Variable<String>(pinCode.value);
    }
    if (gstRegistered.present) {
      map['gst_registered'] = Variable<bool>(gstRegistered.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (pan.present) {
      map['pan'] = Variable<String>(pan.value);
    }
    if (invoicePrefix.present) {
      map['invoice_prefix'] = Variable<String>(invoicePrefix.value);
    }
    if (startingInvoiceNumber.present) {
      map['starting_invoice_number'] = Variable<int>(
        startingInvoiceNumber.value,
      );
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (accountHolderName.present) {
      map['account_holder_name'] = Variable<String>(accountHolderName.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (ifsc.present) {
      map['ifsc'] = Variable<String>(ifsc.value);
    }
    if (upiId.present) {
      map['upi_id'] = Variable<String>(upiId.value);
    }
    if (paymentQrPath.present) {
      map['payment_qr_path'] = Variable<String>(paymentQrPath.value);
    }
    if (signaturePath.present) {
      map['signature_path'] = Variable<String>(signaturePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessProfilesCompanion(')
          ..write('id: $id, ')
          ..write('businessName: $businessName, ')
          ..write('ownerName: $ownerName, ')
          ..write('logoPath: $logoPath, ')
          ..write('mobile: $mobile, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('pinCode: $pinCode, ')
          ..write('gstRegistered: $gstRegistered, ')
          ..write('gstin: $gstin, ')
          ..write('pan: $pan, ')
          ..write('invoicePrefix: $invoicePrefix, ')
          ..write('startingInvoiceNumber: $startingInvoiceNumber, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('bankName: $bankName, ')
          ..write('accountHolderName: $accountHolderName, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('ifsc: $ifsc, ')
          ..write('upiId: $upiId, ')
          ..write('paymentQrPath: $paymentQrPath, ')
          ..write('signaturePath: $signaturePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinCodeMeta = const VerificationMeta(
    'pinCode',
  );
  @override
  late final GeneratedColumn<String> pinCode = GeneratedColumn<String>(
    'pin_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
    'gstin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    companyName,
    mobile,
    email,
    address,
    city,
    state,
    pinCode,
    gstin,
    notes,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Customer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('pin_code')) {
      context.handle(
        _pinCodeMeta,
        pinCode.isAcceptableOrUnknown(data['pin_code']!, _pinCodeMeta),
      );
    }
    if (data.containsKey('gstin')) {
      context.handle(
        _gstinMeta,
        gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      pinCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_code'],
      ),
      gstin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gstin'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final int id;
  final String name;
  final String? companyName;
  final String? mobile;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? gstin;
  final String? notes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Customer({
    required this.id,
    required this.name,
    this.companyName,
    this.mobile,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.gstin,
    this.notes,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || pinCode != null) {
      map['pin_code'] = Variable<String>(pinCode);
    }
    if (!nullToAbsent || gstin != null) {
      map['gstin'] = Variable<String>(gstin);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      mobile: mobile == null && nullToAbsent
          ? const Value.absent()
          : Value(mobile),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      pinCode: pinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCode),
      gstin: gstin == null && nullToAbsent
          ? const Value.absent()
          : Value(gstin),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Customer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      city: serializer.fromJson<String?>(json['city']),
      state: serializer.fromJson<String?>(json['state']),
      pinCode: serializer.fromJson<String?>(json['pinCode']),
      gstin: serializer.fromJson<String?>(json['gstin']),
      notes: serializer.fromJson<String?>(json['notes']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'companyName': serializer.toJson<String?>(companyName),
      'mobile': serializer.toJson<String?>(mobile),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'city': serializer.toJson<String?>(city),
      'state': serializer.toJson<String?>(state),
      'pinCode': serializer.toJson<String?>(pinCode),
      'gstin': serializer.toJson<String?>(gstin),
      'notes': serializer.toJson<String?>(notes),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    Value<String?> companyName = const Value.absent(),
    Value<String?> mobile = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> state = const Value.absent(),
    Value<String?> pinCode = const Value.absent(),
    Value<String?> gstin = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    companyName: companyName.present ? companyName.value : this.companyName,
    mobile: mobile.present ? mobile.value : this.mobile,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    city: city.present ? city.value : this.city,
    state: state.present ? state.value : this.state,
    pinCode: pinCode.present ? pinCode.value : this.pinCode,
    gstin: gstin.present ? gstin.value : this.gstin,
    notes: notes.present ? notes.value : this.notes,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      pinCode: data.pinCode.present ? data.pinCode.value : this.pinCode,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
      notes: data.notes.present ? data.notes.value : this.notes,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('companyName: $companyName, ')
          ..write('mobile: $mobile, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('pinCode: $pinCode, ')
          ..write('gstin: $gstin, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    companyName,
    mobile,
    email,
    address,
    city,
    state,
    pinCode,
    gstin,
    notes,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.companyName == this.companyName &&
          other.mobile == this.mobile &&
          other.email == this.email &&
          other.address == this.address &&
          other.city == this.city &&
          other.state == this.state &&
          other.pinCode == this.pinCode &&
          other.gstin == this.gstin &&
          other.notes == this.notes &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> companyName;
  final Value<String?> mobile;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> city;
  final Value<String?> state;
  final Value<String?> pinCode;
  final Value<String?> gstin;
  final Value<String?> notes;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.companyName = const Value.absent(),
    this.mobile = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.gstin = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.companyName = const Value.absent(),
    this.mobile = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.gstin = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? companyName,
    Expression<String>? mobile,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? pinCode,
    Expression<String>? gstin,
    Expression<String>? notes,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (companyName != null) 'company_name': companyName,
      if (mobile != null) 'mobile': mobile,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pinCode != null) 'pin_code': pinCode,
      if (gstin != null) 'gstin': gstin,
      if (notes != null) 'notes': notes,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CustomersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? companyName,
    Value<String?>? mobile,
    Value<String?>? email,
    Value<String?>? address,
    Value<String?>? city,
    Value<String?>? state,
    Value<String?>? pinCode,
    Value<String?>? gstin,
    Value<String?>? notes,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      gstin: gstin ?? this.gstin,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (pinCode.present) {
      map['pin_code'] = Variable<String>(pinCode.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('companyName: $companyName, ')
          ..write('mobile: $mobile, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('pinCode: $pinCode, ')
          ..write('gstin: $gstin, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ProductServicesTable extends ProductServices
    with TableInfo<$ProductServicesTable, ProductService> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductServicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salePriceMinorMeta = const VerificationMeta(
    'salePriceMinor',
  );
  @override
  late final GeneratedColumn<int> salePriceMinor = GeneratedColumn<int>(
    'sale_price_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hsnSacMeta = const VerificationMeta('hsnSac');
  @override
  late final GeneratedColumn<String> hsnSac = GeneratedColumn<String>(
    'hsn_sac',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxRateBasisPointsMeta =
      const VerificationMeta('taxRateBasisPoints');
  @override
  late final GeneratedColumn<int> taxRateBasisPoints = GeneratedColumn<int>(
    'tax_rate_basis_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    description,
    unit,
    salePriceMinor,
    hsnSac,
    taxRateBasisPoints,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_services';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductService> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('sale_price_minor')) {
      context.handle(
        _salePriceMinorMeta,
        salePriceMinor.isAcceptableOrUnknown(
          data['sale_price_minor']!,
          _salePriceMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salePriceMinorMeta);
    }
    if (data.containsKey('hsn_sac')) {
      context.handle(
        _hsnSacMeta,
        hsnSac.isAcceptableOrUnknown(data['hsn_sac']!, _hsnSacMeta),
      );
    }
    if (data.containsKey('tax_rate_basis_points')) {
      context.handle(
        _taxRateBasisPointsMeta,
        taxRateBasisPoints.isAcceptableOrUnknown(
          data['tax_rate_basis_points']!,
          _taxRateBasisPointsMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductService map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductService(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      salePriceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sale_price_minor'],
      )!,
      hsnSac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hsn_sac'],
      ),
      taxRateBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_basis_points'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductServicesTable createAlias(String alias) {
    return $ProductServicesTable(attachedDatabase, alias);
  }
}

class ProductService extends DataClass implements Insertable<ProductService> {
  final int id;
  final String name;
  final String type;
  final String? description;
  final String unit;
  final int salePriceMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProductService({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    required this.unit,
    required this.salePriceMinor,
    this.hsnSac,
    required this.taxRateBasisPoints,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['unit'] = Variable<String>(unit);
    map['sale_price_minor'] = Variable<int>(salePriceMinor);
    if (!nullToAbsent || hsnSac != null) {
      map['hsn_sac'] = Variable<String>(hsnSac);
    }
    map['tax_rate_basis_points'] = Variable<int>(taxRateBasisPoints);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductServicesCompanion toCompanion(bool nullToAbsent) {
    return ProductServicesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      unit: Value(unit),
      salePriceMinor: Value(salePriceMinor),
      hsnSac: hsnSac == null && nullToAbsent
          ? const Value.absent()
          : Value(hsnSac),
      taxRateBasisPoints: Value(taxRateBasisPoints),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductService.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductService(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String?>(json['description']),
      unit: serializer.fromJson<String>(json['unit']),
      salePriceMinor: serializer.fromJson<int>(json['salePriceMinor']),
      hsnSac: serializer.fromJson<String?>(json['hsnSac']),
      taxRateBasisPoints: serializer.fromJson<int>(json['taxRateBasisPoints']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String?>(description),
      'unit': serializer.toJson<String>(unit),
      'salePriceMinor': serializer.toJson<int>(salePriceMinor),
      'hsnSac': serializer.toJson<String?>(hsnSac),
      'taxRateBasisPoints': serializer.toJson<int>(taxRateBasisPoints),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductService copyWith({
    int? id,
    String? name,
    String? type,
    Value<String?> description = const Value.absent(),
    String? unit,
    int? salePriceMinor,
    Value<String?> hsnSac = const Value.absent(),
    int? taxRateBasisPoints,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProductService(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    description: description.present ? description.value : this.description,
    unit: unit ?? this.unit,
    salePriceMinor: salePriceMinor ?? this.salePriceMinor,
    hsnSac: hsnSac.present ? hsnSac.value : this.hsnSac,
    taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductService copyWithCompanion(ProductServicesCompanion data) {
    return ProductService(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      description: data.description.present
          ? data.description.value
          : this.description,
      unit: data.unit.present ? data.unit.value : this.unit,
      salePriceMinor: data.salePriceMinor.present
          ? data.salePriceMinor.value
          : this.salePriceMinor,
      hsnSac: data.hsnSac.present ? data.hsnSac.value : this.hsnSac,
      taxRateBasisPoints: data.taxRateBasisPoints.present
          ? data.taxRateBasisPoints.value
          : this.taxRateBasisPoints,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductService(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('unit: $unit, ')
          ..write('salePriceMinor: $salePriceMinor, ')
          ..write('hsnSac: $hsnSac, ')
          ..write('taxRateBasisPoints: $taxRateBasisPoints, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    description,
    unit,
    salePriceMinor,
    hsnSac,
    taxRateBasisPoints,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductService &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.description == this.description &&
          other.unit == this.unit &&
          other.salePriceMinor == this.salePriceMinor &&
          other.hsnSac == this.hsnSac &&
          other.taxRateBasisPoints == this.taxRateBasisPoints &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductServicesCompanion extends UpdateCompanion<ProductService> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> description;
  final Value<String> unit;
  final Value<int> salePriceMinor;
  final Value<String?> hsnSac;
  final Value<int> taxRateBasisPoints;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductServicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.unit = const Value.absent(),
    this.salePriceMinor = const Value.absent(),
    this.hsnSac = const Value.absent(),
    this.taxRateBasisPoints = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductServicesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    this.description = const Value.absent(),
    required String unit,
    required int salePriceMinor,
    this.hsnSac = const Value.absent(),
    this.taxRateBasisPoints = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       unit = Value(unit),
       salePriceMinor = Value(salePriceMinor);
  static Insertable<ProductService> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? description,
    Expression<String>? unit,
    Expression<int>? salePriceMinor,
    Expression<String>? hsnSac,
    Expression<int>? taxRateBasisPoints,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (unit != null) 'unit': unit,
      if (salePriceMinor != null) 'sale_price_minor': salePriceMinor,
      if (hsnSac != null) 'hsn_sac': hsnSac,
      if (taxRateBasisPoints != null)
        'tax_rate_basis_points': taxRateBasisPoints,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductServicesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? description,
    Value<String>? unit,
    Value<int>? salePriceMinor,
    Value<String?>? hsnSac,
    Value<int>? taxRateBasisPoints,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProductServicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      salePriceMinor: salePriceMinor ?? this.salePriceMinor,
      hsnSac: hsnSac ?? this.hsnSac,
      taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (salePriceMinor.present) {
      map['sale_price_minor'] = Variable<int>(salePriceMinor.value);
    }
    if (hsnSac.present) {
      map['hsn_sac'] = Variable<String>(hsnSac.value);
    }
    if (taxRateBasisPoints.present) {
      map['tax_rate_basis_points'] = Variable<int>(taxRateBasisPoints.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductServicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('unit: $unit, ')
          ..write('salePriceMinor: $salePriceMinor, ')
          ..write('hsnSac: $hsnSac, ')
          ..write('taxRateBasisPoints: $taxRateBasisPoints, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices with TableInfo<$InvoicesTable, Invoice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentTypeMeta = const VerificationMeta(
    'documentType',
  );
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
    'document_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('invoice'),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerCompanyMeta = const VerificationMeta(
    'customerCompany',
  );
  @override
  late final GeneratedColumn<String> customerCompany = GeneratedColumn<String>(
    'customer_company',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerMobileMeta = const VerificationMeta(
    'customerMobile',
  );
  @override
  late final GeneratedColumn<String> customerMobile = GeneratedColumn<String>(
    'customer_mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerEmailMeta = const VerificationMeta(
    'customerEmail',
  );
  @override
  late final GeneratedColumn<String> customerEmail = GeneratedColumn<String>(
    'customer_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerAddressMeta = const VerificationMeta(
    'customerAddress',
  );
  @override
  late final GeneratedColumn<String> customerAddress = GeneratedColumn<String>(
    'customer_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerCityMeta = const VerificationMeta(
    'customerCity',
  );
  @override
  late final GeneratedColumn<String> customerCity = GeneratedColumn<String>(
    'customer_city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerStateMeta = const VerificationMeta(
    'customerState',
  );
  @override
  late final GeneratedColumn<String> customerState = GeneratedColumn<String>(
    'customer_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerPinCodeMeta = const VerificationMeta(
    'customerPinCode',
  );
  @override
  late final GeneratedColumn<String> customerPinCode = GeneratedColumn<String>(
    'customer_pin_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerGstinMeta = const VerificationMeta(
    'customerGstin',
  );
  @override
  late final GeneratedColumn<String> customerGstin = GeneratedColumn<String>(
    'customer_gstin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceDateMeta = const VerificationMeta(
    'invoiceDate',
  );
  @override
  late final GeneratedColumn<DateTime> invoiceDate = GeneratedColumn<DateTime>(
    'invoice_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxTypeMeta = const VerificationMeta(
    'taxType',
  );
  @override
  late final GeneratedColumn<String> taxType = GeneratedColumn<String>(
    'tax_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<int> discountValue = GeneratedColumn<int>(
    'discount_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subtotalMinorMeta = const VerificationMeta(
    'subtotalMinor',
  );
  @override
  late final GeneratedColumn<int> subtotalMinor = GeneratedColumn<int>(
    'subtotal_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDiscountMinorMeta = const VerificationMeta(
    'itemDiscountMinor',
  );
  @override
  late final GeneratedColumn<int> itemDiscountMinor = GeneratedColumn<int>(
    'item_discount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceDiscountMinorMeta =
      const VerificationMeta('invoiceDiscountMinor');
  @override
  late final GeneratedColumn<int> invoiceDiscountMinor = GeneratedColumn<int>(
    'invoice_discount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxableMinorMeta = const VerificationMeta(
    'taxableMinor',
  );
  @override
  late final GeneratedColumn<int> taxableMinor = GeneratedColumn<int>(
    'taxable_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxMinorMeta = const VerificationMeta(
    'taxMinor',
  );
  @override
  late final GeneratedColumn<int> taxMinor = GeneratedColumn<int>(
    'tax_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cgstMinorMeta = const VerificationMeta(
    'cgstMinor',
  );
  @override
  late final GeneratedColumn<int> cgstMinor = GeneratedColumn<int>(
    'cgst_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sgstMinorMeta = const VerificationMeta(
    'sgstMinor',
  );
  @override
  late final GeneratedColumn<int> sgstMinor = GeneratedColumn<int>(
    'sgst_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _igstMinorMeta = const VerificationMeta(
    'igstMinor',
  );
  @override
  late final GeneratedColumn<int> igstMinor = GeneratedColumn<int>(
    'igst_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chargesMinorMeta = const VerificationMeta(
    'chargesMinor',
  );
  @override
  late final GeneratedColumn<int> chargesMinor = GeneratedColumn<int>(
    'charges_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundOffMinorMeta = const VerificationMeta(
    'roundOffMinor',
  );
  @override
  late final GeneratedColumn<int> roundOffMinor = GeneratedColumn<int>(
    'round_off_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grandTotalMinorMeta = const VerificationMeta(
    'grandTotalMinor',
  );
  @override
  late final GeneratedColumn<int> grandTotalMinor = GeneratedColumn<int>(
    'grand_total_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMinorMeta = const VerificationMeta(
    'paidAmountMinor',
  );
  @override
  late final GeneratedColumn<int> paidAmountMinor = GeneratedColumn<int>(
    'paid_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMinorMeta = const VerificationMeta(
    'balanceMinor',
  );
  @override
  late final GeneratedColumn<int> balanceMinor = GeneratedColumn<int>(
    'balance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _termsMeta = const VerificationMeta('terms');
  @override
  late final GeneratedColumn<String> terms = GeneratedColumn<String>(
    'terms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceNumber,
    documentType,
    customerId,
    customerName,
    customerCompany,
    customerMobile,
    customerEmail,
    customerAddress,
    customerCity,
    customerState,
    customerPinCode,
    customerGstin,
    invoiceDate,
    dueDate,
    status,
    taxType,
    discountType,
    discountValue,
    subtotalMinor,
    itemDiscountMinor,
    invoiceDiscountMinor,
    taxableMinor,
    taxMinor,
    cgstMinor,
    sgstMinor,
    igstMinor,
    chargesMinor,
    roundOffMinor,
    grandTotalMinor,
    paidAmountMinor,
    balanceMinor,
    notes,
    terms,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Invoice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('document_type')) {
      context.handle(
        _documentTypeMeta,
        documentType.isAcceptableOrUnknown(
          data['document_type']!,
          _documentTypeMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('customer_company')) {
      context.handle(
        _customerCompanyMeta,
        customerCompany.isAcceptableOrUnknown(
          data['customer_company']!,
          _customerCompanyMeta,
        ),
      );
    }
    if (data.containsKey('customer_mobile')) {
      context.handle(
        _customerMobileMeta,
        customerMobile.isAcceptableOrUnknown(
          data['customer_mobile']!,
          _customerMobileMeta,
        ),
      );
    }
    if (data.containsKey('customer_email')) {
      context.handle(
        _customerEmailMeta,
        customerEmail.isAcceptableOrUnknown(
          data['customer_email']!,
          _customerEmailMeta,
        ),
      );
    }
    if (data.containsKey('customer_address')) {
      context.handle(
        _customerAddressMeta,
        customerAddress.isAcceptableOrUnknown(
          data['customer_address']!,
          _customerAddressMeta,
        ),
      );
    }
    if (data.containsKey('customer_city')) {
      context.handle(
        _customerCityMeta,
        customerCity.isAcceptableOrUnknown(
          data['customer_city']!,
          _customerCityMeta,
        ),
      );
    }
    if (data.containsKey('customer_state')) {
      context.handle(
        _customerStateMeta,
        customerState.isAcceptableOrUnknown(
          data['customer_state']!,
          _customerStateMeta,
        ),
      );
    }
    if (data.containsKey('customer_pin_code')) {
      context.handle(
        _customerPinCodeMeta,
        customerPinCode.isAcceptableOrUnknown(
          data['customer_pin_code']!,
          _customerPinCodeMeta,
        ),
      );
    }
    if (data.containsKey('customer_gstin')) {
      context.handle(
        _customerGstinMeta,
        customerGstin.isAcceptableOrUnknown(
          data['customer_gstin']!,
          _customerGstinMeta,
        ),
      );
    }
    if (data.containsKey('invoice_date')) {
      context.handle(
        _invoiceDateMeta,
        invoiceDate.isAcceptableOrUnknown(
          data['invoice_date']!,
          _invoiceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceDateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('tax_type')) {
      context.handle(
        _taxTypeMeta,
        taxType.isAcceptableOrUnknown(data['tax_type']!, _taxTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_taxTypeMeta);
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountTypeMeta);
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    }
    if (data.containsKey('subtotal_minor')) {
      context.handle(
        _subtotalMinorMeta,
        subtotalMinor.isAcceptableOrUnknown(
          data['subtotal_minor']!,
          _subtotalMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtotalMinorMeta);
    }
    if (data.containsKey('item_discount_minor')) {
      context.handle(
        _itemDiscountMinorMeta,
        itemDiscountMinor.isAcceptableOrUnknown(
          data['item_discount_minor']!,
          _itemDiscountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemDiscountMinorMeta);
    }
    if (data.containsKey('invoice_discount_minor')) {
      context.handle(
        _invoiceDiscountMinorMeta,
        invoiceDiscountMinor.isAcceptableOrUnknown(
          data['invoice_discount_minor']!,
          _invoiceDiscountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceDiscountMinorMeta);
    }
    if (data.containsKey('taxable_minor')) {
      context.handle(
        _taxableMinorMeta,
        taxableMinor.isAcceptableOrUnknown(
          data['taxable_minor']!,
          _taxableMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxableMinorMeta);
    }
    if (data.containsKey('tax_minor')) {
      context.handle(
        _taxMinorMeta,
        taxMinor.isAcceptableOrUnknown(data['tax_minor']!, _taxMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_taxMinorMeta);
    }
    if (data.containsKey('cgst_minor')) {
      context.handle(
        _cgstMinorMeta,
        cgstMinor.isAcceptableOrUnknown(data['cgst_minor']!, _cgstMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_cgstMinorMeta);
    }
    if (data.containsKey('sgst_minor')) {
      context.handle(
        _sgstMinorMeta,
        sgstMinor.isAcceptableOrUnknown(data['sgst_minor']!, _sgstMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_sgstMinorMeta);
    }
    if (data.containsKey('igst_minor')) {
      context.handle(
        _igstMinorMeta,
        igstMinor.isAcceptableOrUnknown(data['igst_minor']!, _igstMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_igstMinorMeta);
    }
    if (data.containsKey('charges_minor')) {
      context.handle(
        _chargesMinorMeta,
        chargesMinor.isAcceptableOrUnknown(
          data['charges_minor']!,
          _chargesMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chargesMinorMeta);
    }
    if (data.containsKey('round_off_minor')) {
      context.handle(
        _roundOffMinorMeta,
        roundOffMinor.isAcceptableOrUnknown(
          data['round_off_minor']!,
          _roundOffMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundOffMinorMeta);
    }
    if (data.containsKey('grand_total_minor')) {
      context.handle(
        _grandTotalMinorMeta,
        grandTotalMinor.isAcceptableOrUnknown(
          data['grand_total_minor']!,
          _grandTotalMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grandTotalMinorMeta);
    }
    if (data.containsKey('paid_amount_minor')) {
      context.handle(
        _paidAmountMinorMeta,
        paidAmountMinor.isAcceptableOrUnknown(
          data['paid_amount_minor']!,
          _paidAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paidAmountMinorMeta);
    }
    if (data.containsKey('balance_minor')) {
      context.handle(
        _balanceMinorMeta,
        balanceMinor.isAcceptableOrUnknown(
          data['balance_minor']!,
          _balanceMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceMinorMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('terms')) {
      context.handle(
        _termsMeta,
        terms.isAcceptableOrUnknown(data['terms']!, _termsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invoice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      )!,
      documentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_type'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}customer_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      customerCompany: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_company'],
      ),
      customerMobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_mobile'],
      ),
      customerEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_email'],
      ),
      customerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_address'],
      ),
      customerCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_city'],
      ),
      customerState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_state'],
      ),
      customerPinCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_pin_code'],
      ),
      customerGstin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_gstin'],
      ),
      invoiceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invoice_date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      taxType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_type'],
      )!,
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_value'],
      )!,
      subtotalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_minor'],
      )!,
      itemDiscountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_discount_minor'],
      )!,
      invoiceDiscountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invoice_discount_minor'],
      )!,
      taxableMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taxable_minor'],
      )!,
      taxMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_minor'],
      )!,
      cgstMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cgst_minor'],
      )!,
      sgstMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sgst_minor'],
      )!,
      igstMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}igst_minor'],
      )!,
      chargesMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}charges_minor'],
      )!,
      roundOffMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_off_minor'],
      )!,
      grandTotalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grand_total_minor'],
      )!,
      paidAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_amount_minor'],
      )!,
      balanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_minor'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      terms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terms'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class Invoice extends DataClass implements Insertable<Invoice> {
  final int id;
  final String invoiceNumber;
  final String documentType;
  final int? customerId;
  final String customerName;
  final String? customerCompany;
  final String? customerMobile;
  final String? customerEmail;
  final String? customerAddress;
  final String? customerCity;
  final String? customerState;
  final String? customerPinCode;
  final String? customerGstin;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String status;
  final String taxType;
  final String discountType;
  final int discountValue;
  final int subtotalMinor;
  final int itemDiscountMinor;
  final int invoiceDiscountMinor;
  final int taxableMinor;
  final int taxMinor;
  final int cgstMinor;
  final int sgstMinor;
  final int igstMinor;
  final int chargesMinor;
  final int roundOffMinor;
  final int grandTotalMinor;
  final int paidAmountMinor;
  final int balanceMinor;
  final String? notes;
  final String? terms;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.documentType,
    this.customerId,
    required this.customerName,
    this.customerCompany,
    this.customerMobile,
    this.customerEmail,
    this.customerAddress,
    this.customerCity,
    this.customerState,
    this.customerPinCode,
    this.customerGstin,
    required this.invoiceDate,
    this.dueDate,
    required this.status,
    required this.taxType,
    required this.discountType,
    required this.discountValue,
    required this.subtotalMinor,
    required this.itemDiscountMinor,
    required this.invoiceDiscountMinor,
    required this.taxableMinor,
    required this.taxMinor,
    required this.cgstMinor,
    required this.sgstMinor,
    required this.igstMinor,
    required this.chargesMinor,
    required this.roundOffMinor,
    required this.grandTotalMinor,
    required this.paidAmountMinor,
    required this.balanceMinor,
    this.notes,
    this.terms,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['document_type'] = Variable<String>(documentType);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    map['customer_name'] = Variable<String>(customerName);
    if (!nullToAbsent || customerCompany != null) {
      map['customer_company'] = Variable<String>(customerCompany);
    }
    if (!nullToAbsent || customerMobile != null) {
      map['customer_mobile'] = Variable<String>(customerMobile);
    }
    if (!nullToAbsent || customerEmail != null) {
      map['customer_email'] = Variable<String>(customerEmail);
    }
    if (!nullToAbsent || customerAddress != null) {
      map['customer_address'] = Variable<String>(customerAddress);
    }
    if (!nullToAbsent || customerCity != null) {
      map['customer_city'] = Variable<String>(customerCity);
    }
    if (!nullToAbsent || customerState != null) {
      map['customer_state'] = Variable<String>(customerState);
    }
    if (!nullToAbsent || customerPinCode != null) {
      map['customer_pin_code'] = Variable<String>(customerPinCode);
    }
    if (!nullToAbsent || customerGstin != null) {
      map['customer_gstin'] = Variable<String>(customerGstin);
    }
    map['invoice_date'] = Variable<DateTime>(invoiceDate);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['status'] = Variable<String>(status);
    map['tax_type'] = Variable<String>(taxType);
    map['discount_type'] = Variable<String>(discountType);
    map['discount_value'] = Variable<int>(discountValue);
    map['subtotal_minor'] = Variable<int>(subtotalMinor);
    map['item_discount_minor'] = Variable<int>(itemDiscountMinor);
    map['invoice_discount_minor'] = Variable<int>(invoiceDiscountMinor);
    map['taxable_minor'] = Variable<int>(taxableMinor);
    map['tax_minor'] = Variable<int>(taxMinor);
    map['cgst_minor'] = Variable<int>(cgstMinor);
    map['sgst_minor'] = Variable<int>(sgstMinor);
    map['igst_minor'] = Variable<int>(igstMinor);
    map['charges_minor'] = Variable<int>(chargesMinor);
    map['round_off_minor'] = Variable<int>(roundOffMinor);
    map['grand_total_minor'] = Variable<int>(grandTotalMinor);
    map['paid_amount_minor'] = Variable<int>(paidAmountMinor);
    map['balance_minor'] = Variable<int>(balanceMinor);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || terms != null) {
      map['terms'] = Variable<String>(terms);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      invoiceNumber: Value(invoiceNumber),
      documentType: Value(documentType),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: Value(customerName),
      customerCompany: customerCompany == null && nullToAbsent
          ? const Value.absent()
          : Value(customerCompany),
      customerMobile: customerMobile == null && nullToAbsent
          ? const Value.absent()
          : Value(customerMobile),
      customerEmail: customerEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(customerEmail),
      customerAddress: customerAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAddress),
      customerCity: customerCity == null && nullToAbsent
          ? const Value.absent()
          : Value(customerCity),
      customerState: customerState == null && nullToAbsent
          ? const Value.absent()
          : Value(customerState),
      customerPinCode: customerPinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPinCode),
      customerGstin: customerGstin == null && nullToAbsent
          ? const Value.absent()
          : Value(customerGstin),
      invoiceDate: Value(invoiceDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      status: Value(status),
      taxType: Value(taxType),
      discountType: Value(discountType),
      discountValue: Value(discountValue),
      subtotalMinor: Value(subtotalMinor),
      itemDiscountMinor: Value(itemDiscountMinor),
      invoiceDiscountMinor: Value(invoiceDiscountMinor),
      taxableMinor: Value(taxableMinor),
      taxMinor: Value(taxMinor),
      cgstMinor: Value(cgstMinor),
      sgstMinor: Value(sgstMinor),
      igstMinor: Value(igstMinor),
      chargesMinor: Value(chargesMinor),
      roundOffMinor: Value(roundOffMinor),
      grandTotalMinor: Value(grandTotalMinor),
      paidAmountMinor: Value(paidAmountMinor),
      balanceMinor: Value(balanceMinor),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      terms: terms == null && nullToAbsent
          ? const Value.absent()
          : Value(terms),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Invoice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invoice(
      id: serializer.fromJson<int>(json['id']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      documentType: serializer.fromJson<String>(json['documentType']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerCompany: serializer.fromJson<String?>(json['customerCompany']),
      customerMobile: serializer.fromJson<String?>(json['customerMobile']),
      customerEmail: serializer.fromJson<String?>(json['customerEmail']),
      customerAddress: serializer.fromJson<String?>(json['customerAddress']),
      customerCity: serializer.fromJson<String?>(json['customerCity']),
      customerState: serializer.fromJson<String?>(json['customerState']),
      customerPinCode: serializer.fromJson<String?>(json['customerPinCode']),
      customerGstin: serializer.fromJson<String?>(json['customerGstin']),
      invoiceDate: serializer.fromJson<DateTime>(json['invoiceDate']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      taxType: serializer.fromJson<String>(json['taxType']),
      discountType: serializer.fromJson<String>(json['discountType']),
      discountValue: serializer.fromJson<int>(json['discountValue']),
      subtotalMinor: serializer.fromJson<int>(json['subtotalMinor']),
      itemDiscountMinor: serializer.fromJson<int>(json['itemDiscountMinor']),
      invoiceDiscountMinor: serializer.fromJson<int>(
        json['invoiceDiscountMinor'],
      ),
      taxableMinor: serializer.fromJson<int>(json['taxableMinor']),
      taxMinor: serializer.fromJson<int>(json['taxMinor']),
      cgstMinor: serializer.fromJson<int>(json['cgstMinor']),
      sgstMinor: serializer.fromJson<int>(json['sgstMinor']),
      igstMinor: serializer.fromJson<int>(json['igstMinor']),
      chargesMinor: serializer.fromJson<int>(json['chargesMinor']),
      roundOffMinor: serializer.fromJson<int>(json['roundOffMinor']),
      grandTotalMinor: serializer.fromJson<int>(json['grandTotalMinor']),
      paidAmountMinor: serializer.fromJson<int>(json['paidAmountMinor']),
      balanceMinor: serializer.fromJson<int>(json['balanceMinor']),
      notes: serializer.fromJson<String?>(json['notes']),
      terms: serializer.fromJson<String?>(json['terms']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'documentType': serializer.toJson<String>(documentType),
      'customerId': serializer.toJson<int?>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'customerCompany': serializer.toJson<String?>(customerCompany),
      'customerMobile': serializer.toJson<String?>(customerMobile),
      'customerEmail': serializer.toJson<String?>(customerEmail),
      'customerAddress': serializer.toJson<String?>(customerAddress),
      'customerCity': serializer.toJson<String?>(customerCity),
      'customerState': serializer.toJson<String?>(customerState),
      'customerPinCode': serializer.toJson<String?>(customerPinCode),
      'customerGstin': serializer.toJson<String?>(customerGstin),
      'invoiceDate': serializer.toJson<DateTime>(invoiceDate),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'status': serializer.toJson<String>(status),
      'taxType': serializer.toJson<String>(taxType),
      'discountType': serializer.toJson<String>(discountType),
      'discountValue': serializer.toJson<int>(discountValue),
      'subtotalMinor': serializer.toJson<int>(subtotalMinor),
      'itemDiscountMinor': serializer.toJson<int>(itemDiscountMinor),
      'invoiceDiscountMinor': serializer.toJson<int>(invoiceDiscountMinor),
      'taxableMinor': serializer.toJson<int>(taxableMinor),
      'taxMinor': serializer.toJson<int>(taxMinor),
      'cgstMinor': serializer.toJson<int>(cgstMinor),
      'sgstMinor': serializer.toJson<int>(sgstMinor),
      'igstMinor': serializer.toJson<int>(igstMinor),
      'chargesMinor': serializer.toJson<int>(chargesMinor),
      'roundOffMinor': serializer.toJson<int>(roundOffMinor),
      'grandTotalMinor': serializer.toJson<int>(grandTotalMinor),
      'paidAmountMinor': serializer.toJson<int>(paidAmountMinor),
      'balanceMinor': serializer.toJson<int>(balanceMinor),
      'notes': serializer.toJson<String?>(notes),
      'terms': serializer.toJson<String?>(terms),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    String? documentType,
    Value<int?> customerId = const Value.absent(),
    String? customerName,
    Value<String?> customerCompany = const Value.absent(),
    Value<String?> customerMobile = const Value.absent(),
    Value<String?> customerEmail = const Value.absent(),
    Value<String?> customerAddress = const Value.absent(),
    Value<String?> customerCity = const Value.absent(),
    Value<String?> customerState = const Value.absent(),
    Value<String?> customerPinCode = const Value.absent(),
    Value<String?> customerGstin = const Value.absent(),
    DateTime? invoiceDate,
    Value<DateTime?> dueDate = const Value.absent(),
    String? status,
    String? taxType,
    String? discountType,
    int? discountValue,
    int? subtotalMinor,
    int? itemDiscountMinor,
    int? invoiceDiscountMinor,
    int? taxableMinor,
    int? taxMinor,
    int? cgstMinor,
    int? sgstMinor,
    int? igstMinor,
    int? chargesMinor,
    int? roundOffMinor,
    int? grandTotalMinor,
    int? paidAmountMinor,
    int? balanceMinor,
    Value<String?> notes = const Value.absent(),
    Value<String?> terms = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Invoice(
    id: id ?? this.id,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    documentType: documentType ?? this.documentType,
    customerId: customerId.present ? customerId.value : this.customerId,
    customerName: customerName ?? this.customerName,
    customerCompany: customerCompany.present
        ? customerCompany.value
        : this.customerCompany,
    customerMobile: customerMobile.present
        ? customerMobile.value
        : this.customerMobile,
    customerEmail: customerEmail.present
        ? customerEmail.value
        : this.customerEmail,
    customerAddress: customerAddress.present
        ? customerAddress.value
        : this.customerAddress,
    customerCity: customerCity.present ? customerCity.value : this.customerCity,
    customerState: customerState.present
        ? customerState.value
        : this.customerState,
    customerPinCode: customerPinCode.present
        ? customerPinCode.value
        : this.customerPinCode,
    customerGstin: customerGstin.present
        ? customerGstin.value
        : this.customerGstin,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    status: status ?? this.status,
    taxType: taxType ?? this.taxType,
    discountType: discountType ?? this.discountType,
    discountValue: discountValue ?? this.discountValue,
    subtotalMinor: subtotalMinor ?? this.subtotalMinor,
    itemDiscountMinor: itemDiscountMinor ?? this.itemDiscountMinor,
    invoiceDiscountMinor: invoiceDiscountMinor ?? this.invoiceDiscountMinor,
    taxableMinor: taxableMinor ?? this.taxableMinor,
    taxMinor: taxMinor ?? this.taxMinor,
    cgstMinor: cgstMinor ?? this.cgstMinor,
    sgstMinor: sgstMinor ?? this.sgstMinor,
    igstMinor: igstMinor ?? this.igstMinor,
    chargesMinor: chargesMinor ?? this.chargesMinor,
    roundOffMinor: roundOffMinor ?? this.roundOffMinor,
    grandTotalMinor: grandTotalMinor ?? this.grandTotalMinor,
    paidAmountMinor: paidAmountMinor ?? this.paidAmountMinor,
    balanceMinor: balanceMinor ?? this.balanceMinor,
    notes: notes.present ? notes.value : this.notes,
    terms: terms.present ? terms.value : this.terms,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Invoice copyWithCompanion(InvoicesCompanion data) {
    return Invoice(
      id: data.id.present ? data.id.value : this.id,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerCompany: data.customerCompany.present
          ? data.customerCompany.value
          : this.customerCompany,
      customerMobile: data.customerMobile.present
          ? data.customerMobile.value
          : this.customerMobile,
      customerEmail: data.customerEmail.present
          ? data.customerEmail.value
          : this.customerEmail,
      customerAddress: data.customerAddress.present
          ? data.customerAddress.value
          : this.customerAddress,
      customerCity: data.customerCity.present
          ? data.customerCity.value
          : this.customerCity,
      customerState: data.customerState.present
          ? data.customerState.value
          : this.customerState,
      customerPinCode: data.customerPinCode.present
          ? data.customerPinCode.value
          : this.customerPinCode,
      customerGstin: data.customerGstin.present
          ? data.customerGstin.value
          : this.customerGstin,
      invoiceDate: data.invoiceDate.present
          ? data.invoiceDate.value
          : this.invoiceDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      taxType: data.taxType.present ? data.taxType.value : this.taxType,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      subtotalMinor: data.subtotalMinor.present
          ? data.subtotalMinor.value
          : this.subtotalMinor,
      itemDiscountMinor: data.itemDiscountMinor.present
          ? data.itemDiscountMinor.value
          : this.itemDiscountMinor,
      invoiceDiscountMinor: data.invoiceDiscountMinor.present
          ? data.invoiceDiscountMinor.value
          : this.invoiceDiscountMinor,
      taxableMinor: data.taxableMinor.present
          ? data.taxableMinor.value
          : this.taxableMinor,
      taxMinor: data.taxMinor.present ? data.taxMinor.value : this.taxMinor,
      cgstMinor: data.cgstMinor.present ? data.cgstMinor.value : this.cgstMinor,
      sgstMinor: data.sgstMinor.present ? data.sgstMinor.value : this.sgstMinor,
      igstMinor: data.igstMinor.present ? data.igstMinor.value : this.igstMinor,
      chargesMinor: data.chargesMinor.present
          ? data.chargesMinor.value
          : this.chargesMinor,
      roundOffMinor: data.roundOffMinor.present
          ? data.roundOffMinor.value
          : this.roundOffMinor,
      grandTotalMinor: data.grandTotalMinor.present
          ? data.grandTotalMinor.value
          : this.grandTotalMinor,
      paidAmountMinor: data.paidAmountMinor.present
          ? data.paidAmountMinor.value
          : this.paidAmountMinor,
      balanceMinor: data.balanceMinor.present
          ? data.balanceMinor.value
          : this.balanceMinor,
      notes: data.notes.present ? data.notes.value : this.notes,
      terms: data.terms.present ? data.terms.value : this.terms,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invoice(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('documentType: $documentType, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerCompany: $customerCompany, ')
          ..write('customerMobile: $customerMobile, ')
          ..write('customerEmail: $customerEmail, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('customerCity: $customerCity, ')
          ..write('customerState: $customerState, ')
          ..write('customerPinCode: $customerPinCode, ')
          ..write('customerGstin: $customerGstin, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('taxType: $taxType, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('subtotalMinor: $subtotalMinor, ')
          ..write('itemDiscountMinor: $itemDiscountMinor, ')
          ..write('invoiceDiscountMinor: $invoiceDiscountMinor, ')
          ..write('taxableMinor: $taxableMinor, ')
          ..write('taxMinor: $taxMinor, ')
          ..write('cgstMinor: $cgstMinor, ')
          ..write('sgstMinor: $sgstMinor, ')
          ..write('igstMinor: $igstMinor, ')
          ..write('chargesMinor: $chargesMinor, ')
          ..write('roundOffMinor: $roundOffMinor, ')
          ..write('grandTotalMinor: $grandTotalMinor, ')
          ..write('paidAmountMinor: $paidAmountMinor, ')
          ..write('balanceMinor: $balanceMinor, ')
          ..write('notes: $notes, ')
          ..write('terms: $terms, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    invoiceNumber,
    documentType,
    customerId,
    customerName,
    customerCompany,
    customerMobile,
    customerEmail,
    customerAddress,
    customerCity,
    customerState,
    customerPinCode,
    customerGstin,
    invoiceDate,
    dueDate,
    status,
    taxType,
    discountType,
    discountValue,
    subtotalMinor,
    itemDiscountMinor,
    invoiceDiscountMinor,
    taxableMinor,
    taxMinor,
    cgstMinor,
    sgstMinor,
    igstMinor,
    chargesMinor,
    roundOffMinor,
    grandTotalMinor,
    paidAmountMinor,
    balanceMinor,
    notes,
    terms,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invoice &&
          other.id == this.id &&
          other.invoiceNumber == this.invoiceNumber &&
          other.documentType == this.documentType &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.customerCompany == this.customerCompany &&
          other.customerMobile == this.customerMobile &&
          other.customerEmail == this.customerEmail &&
          other.customerAddress == this.customerAddress &&
          other.customerCity == this.customerCity &&
          other.customerState == this.customerState &&
          other.customerPinCode == this.customerPinCode &&
          other.customerGstin == this.customerGstin &&
          other.invoiceDate == this.invoiceDate &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.taxType == this.taxType &&
          other.discountType == this.discountType &&
          other.discountValue == this.discountValue &&
          other.subtotalMinor == this.subtotalMinor &&
          other.itemDiscountMinor == this.itemDiscountMinor &&
          other.invoiceDiscountMinor == this.invoiceDiscountMinor &&
          other.taxableMinor == this.taxableMinor &&
          other.taxMinor == this.taxMinor &&
          other.cgstMinor == this.cgstMinor &&
          other.sgstMinor == this.sgstMinor &&
          other.igstMinor == this.igstMinor &&
          other.chargesMinor == this.chargesMinor &&
          other.roundOffMinor == this.roundOffMinor &&
          other.grandTotalMinor == this.grandTotalMinor &&
          other.paidAmountMinor == this.paidAmountMinor &&
          other.balanceMinor == this.balanceMinor &&
          other.notes == this.notes &&
          other.terms == this.terms &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InvoicesCompanion extends UpdateCompanion<Invoice> {
  final Value<int> id;
  final Value<String> invoiceNumber;
  final Value<String> documentType;
  final Value<int?> customerId;
  final Value<String> customerName;
  final Value<String?> customerCompany;
  final Value<String?> customerMobile;
  final Value<String?> customerEmail;
  final Value<String?> customerAddress;
  final Value<String?> customerCity;
  final Value<String?> customerState;
  final Value<String?> customerPinCode;
  final Value<String?> customerGstin;
  final Value<DateTime> invoiceDate;
  final Value<DateTime?> dueDate;
  final Value<String> status;
  final Value<String> taxType;
  final Value<String> discountType;
  final Value<int> discountValue;
  final Value<int> subtotalMinor;
  final Value<int> itemDiscountMinor;
  final Value<int> invoiceDiscountMinor;
  final Value<int> taxableMinor;
  final Value<int> taxMinor;
  final Value<int> cgstMinor;
  final Value<int> sgstMinor;
  final Value<int> igstMinor;
  final Value<int> chargesMinor;
  final Value<int> roundOffMinor;
  final Value<int> grandTotalMinor;
  final Value<int> paidAmountMinor;
  final Value<int> balanceMinor;
  final Value<String?> notes;
  final Value<String?> terms;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.documentType = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerCompany = const Value.absent(),
    this.customerMobile = const Value.absent(),
    this.customerEmail = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.customerCity = const Value.absent(),
    this.customerState = const Value.absent(),
    this.customerPinCode = const Value.absent(),
    this.customerGstin = const Value.absent(),
    this.invoiceDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.taxType = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.subtotalMinor = const Value.absent(),
    this.itemDiscountMinor = const Value.absent(),
    this.invoiceDiscountMinor = const Value.absent(),
    this.taxableMinor = const Value.absent(),
    this.taxMinor = const Value.absent(),
    this.cgstMinor = const Value.absent(),
    this.sgstMinor = const Value.absent(),
    this.igstMinor = const Value.absent(),
    this.chargesMinor = const Value.absent(),
    this.roundOffMinor = const Value.absent(),
    this.grandTotalMinor = const Value.absent(),
    this.paidAmountMinor = const Value.absent(),
    this.balanceMinor = const Value.absent(),
    this.notes = const Value.absent(),
    this.terms = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  InvoicesCompanion.insert({
    this.id = const Value.absent(),
    required String invoiceNumber,
    this.documentType = const Value.absent(),
    this.customerId = const Value.absent(),
    required String customerName,
    this.customerCompany = const Value.absent(),
    this.customerMobile = const Value.absent(),
    this.customerEmail = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.customerCity = const Value.absent(),
    this.customerState = const Value.absent(),
    this.customerPinCode = const Value.absent(),
    this.customerGstin = const Value.absent(),
    required DateTime invoiceDate,
    this.dueDate = const Value.absent(),
    required String status,
    required String taxType,
    required String discountType,
    this.discountValue = const Value.absent(),
    required int subtotalMinor,
    required int itemDiscountMinor,
    required int invoiceDiscountMinor,
    required int taxableMinor,
    required int taxMinor,
    required int cgstMinor,
    required int sgstMinor,
    required int igstMinor,
    required int chargesMinor,
    required int roundOffMinor,
    required int grandTotalMinor,
    required int paidAmountMinor,
    required int balanceMinor,
    this.notes = const Value.absent(),
    this.terms = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : invoiceNumber = Value(invoiceNumber),
       customerName = Value(customerName),
       invoiceDate = Value(invoiceDate),
       status = Value(status),
       taxType = Value(taxType),
       discountType = Value(discountType),
       subtotalMinor = Value(subtotalMinor),
       itemDiscountMinor = Value(itemDiscountMinor),
       invoiceDiscountMinor = Value(invoiceDiscountMinor),
       taxableMinor = Value(taxableMinor),
       taxMinor = Value(taxMinor),
       cgstMinor = Value(cgstMinor),
       sgstMinor = Value(sgstMinor),
       igstMinor = Value(igstMinor),
       chargesMinor = Value(chargesMinor),
       roundOffMinor = Value(roundOffMinor),
       grandTotalMinor = Value(grandTotalMinor),
       paidAmountMinor = Value(paidAmountMinor),
       balanceMinor = Value(balanceMinor);
  static Insertable<Invoice> custom({
    Expression<int>? id,
    Expression<String>? invoiceNumber,
    Expression<String>? documentType,
    Expression<int>? customerId,
    Expression<String>? customerName,
    Expression<String>? customerCompany,
    Expression<String>? customerMobile,
    Expression<String>? customerEmail,
    Expression<String>? customerAddress,
    Expression<String>? customerCity,
    Expression<String>? customerState,
    Expression<String>? customerPinCode,
    Expression<String>? customerGstin,
    Expression<DateTime>? invoiceDate,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<String>? taxType,
    Expression<String>? discountType,
    Expression<int>? discountValue,
    Expression<int>? subtotalMinor,
    Expression<int>? itemDiscountMinor,
    Expression<int>? invoiceDiscountMinor,
    Expression<int>? taxableMinor,
    Expression<int>? taxMinor,
    Expression<int>? cgstMinor,
    Expression<int>? sgstMinor,
    Expression<int>? igstMinor,
    Expression<int>? chargesMinor,
    Expression<int>? roundOffMinor,
    Expression<int>? grandTotalMinor,
    Expression<int>? paidAmountMinor,
    Expression<int>? balanceMinor,
    Expression<String>? notes,
    Expression<String>? terms,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (documentType != null) 'document_type': documentType,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerCompany != null) 'customer_company': customerCompany,
      if (customerMobile != null) 'customer_mobile': customerMobile,
      if (customerEmail != null) 'customer_email': customerEmail,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (customerCity != null) 'customer_city': customerCity,
      if (customerState != null) 'customer_state': customerState,
      if (customerPinCode != null) 'customer_pin_code': customerPinCode,
      if (customerGstin != null) 'customer_gstin': customerGstin,
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (taxType != null) 'tax_type': taxType,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (subtotalMinor != null) 'subtotal_minor': subtotalMinor,
      if (itemDiscountMinor != null) 'item_discount_minor': itemDiscountMinor,
      if (invoiceDiscountMinor != null)
        'invoice_discount_minor': invoiceDiscountMinor,
      if (taxableMinor != null) 'taxable_minor': taxableMinor,
      if (taxMinor != null) 'tax_minor': taxMinor,
      if (cgstMinor != null) 'cgst_minor': cgstMinor,
      if (sgstMinor != null) 'sgst_minor': sgstMinor,
      if (igstMinor != null) 'igst_minor': igstMinor,
      if (chargesMinor != null) 'charges_minor': chargesMinor,
      if (roundOffMinor != null) 'round_off_minor': roundOffMinor,
      if (grandTotalMinor != null) 'grand_total_minor': grandTotalMinor,
      if (paidAmountMinor != null) 'paid_amount_minor': paidAmountMinor,
      if (balanceMinor != null) 'balance_minor': balanceMinor,
      if (notes != null) 'notes': notes,
      if (terms != null) 'terms': terms,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  InvoicesCompanion copyWith({
    Value<int>? id,
    Value<String>? invoiceNumber,
    Value<String>? documentType,
    Value<int?>? customerId,
    Value<String>? customerName,
    Value<String?>? customerCompany,
    Value<String?>? customerMobile,
    Value<String?>? customerEmail,
    Value<String?>? customerAddress,
    Value<String?>? customerCity,
    Value<String?>? customerState,
    Value<String?>? customerPinCode,
    Value<String?>? customerGstin,
    Value<DateTime>? invoiceDate,
    Value<DateTime?>? dueDate,
    Value<String>? status,
    Value<String>? taxType,
    Value<String>? discountType,
    Value<int>? discountValue,
    Value<int>? subtotalMinor,
    Value<int>? itemDiscountMinor,
    Value<int>? invoiceDiscountMinor,
    Value<int>? taxableMinor,
    Value<int>? taxMinor,
    Value<int>? cgstMinor,
    Value<int>? sgstMinor,
    Value<int>? igstMinor,
    Value<int>? chargesMinor,
    Value<int>? roundOffMinor,
    Value<int>? grandTotalMinor,
    Value<int>? paidAmountMinor,
    Value<int>? balanceMinor,
    Value<String?>? notes,
    Value<String?>? terms,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return InvoicesCompanion(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      documentType: documentType ?? this.documentType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerCompany: customerCompany ?? this.customerCompany,
      customerMobile: customerMobile ?? this.customerMobile,
      customerEmail: customerEmail ?? this.customerEmail,
      customerAddress: customerAddress ?? this.customerAddress,
      customerCity: customerCity ?? this.customerCity,
      customerState: customerState ?? this.customerState,
      customerPinCode: customerPinCode ?? this.customerPinCode,
      customerGstin: customerGstin ?? this.customerGstin,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      taxType: taxType ?? this.taxType,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      itemDiscountMinor: itemDiscountMinor ?? this.itemDiscountMinor,
      invoiceDiscountMinor: invoiceDiscountMinor ?? this.invoiceDiscountMinor,
      taxableMinor: taxableMinor ?? this.taxableMinor,
      taxMinor: taxMinor ?? this.taxMinor,
      cgstMinor: cgstMinor ?? this.cgstMinor,
      sgstMinor: sgstMinor ?? this.sgstMinor,
      igstMinor: igstMinor ?? this.igstMinor,
      chargesMinor: chargesMinor ?? this.chargesMinor,
      roundOffMinor: roundOffMinor ?? this.roundOffMinor,
      grandTotalMinor: grandTotalMinor ?? this.grandTotalMinor,
      paidAmountMinor: paidAmountMinor ?? this.paidAmountMinor,
      balanceMinor: balanceMinor ?? this.balanceMinor,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerCompany.present) {
      map['customer_company'] = Variable<String>(customerCompany.value);
    }
    if (customerMobile.present) {
      map['customer_mobile'] = Variable<String>(customerMobile.value);
    }
    if (customerEmail.present) {
      map['customer_email'] = Variable<String>(customerEmail.value);
    }
    if (customerAddress.present) {
      map['customer_address'] = Variable<String>(customerAddress.value);
    }
    if (customerCity.present) {
      map['customer_city'] = Variable<String>(customerCity.value);
    }
    if (customerState.present) {
      map['customer_state'] = Variable<String>(customerState.value);
    }
    if (customerPinCode.present) {
      map['customer_pin_code'] = Variable<String>(customerPinCode.value);
    }
    if (customerGstin.present) {
      map['customer_gstin'] = Variable<String>(customerGstin.value);
    }
    if (invoiceDate.present) {
      map['invoice_date'] = Variable<DateTime>(invoiceDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (taxType.present) {
      map['tax_type'] = Variable<String>(taxType.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<int>(discountValue.value);
    }
    if (subtotalMinor.present) {
      map['subtotal_minor'] = Variable<int>(subtotalMinor.value);
    }
    if (itemDiscountMinor.present) {
      map['item_discount_minor'] = Variable<int>(itemDiscountMinor.value);
    }
    if (invoiceDiscountMinor.present) {
      map['invoice_discount_minor'] = Variable<int>(invoiceDiscountMinor.value);
    }
    if (taxableMinor.present) {
      map['taxable_minor'] = Variable<int>(taxableMinor.value);
    }
    if (taxMinor.present) {
      map['tax_minor'] = Variable<int>(taxMinor.value);
    }
    if (cgstMinor.present) {
      map['cgst_minor'] = Variable<int>(cgstMinor.value);
    }
    if (sgstMinor.present) {
      map['sgst_minor'] = Variable<int>(sgstMinor.value);
    }
    if (igstMinor.present) {
      map['igst_minor'] = Variable<int>(igstMinor.value);
    }
    if (chargesMinor.present) {
      map['charges_minor'] = Variable<int>(chargesMinor.value);
    }
    if (roundOffMinor.present) {
      map['round_off_minor'] = Variable<int>(roundOffMinor.value);
    }
    if (grandTotalMinor.present) {
      map['grand_total_minor'] = Variable<int>(grandTotalMinor.value);
    }
    if (paidAmountMinor.present) {
      map['paid_amount_minor'] = Variable<int>(paidAmountMinor.value);
    }
    if (balanceMinor.present) {
      map['balance_minor'] = Variable<int>(balanceMinor.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (terms.present) {
      map['terms'] = Variable<String>(terms.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('documentType: $documentType, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerCompany: $customerCompany, ')
          ..write('customerMobile: $customerMobile, ')
          ..write('customerEmail: $customerEmail, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('customerCity: $customerCity, ')
          ..write('customerState: $customerState, ')
          ..write('customerPinCode: $customerPinCode, ')
          ..write('customerGstin: $customerGstin, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('taxType: $taxType, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('subtotalMinor: $subtotalMinor, ')
          ..write('itemDiscountMinor: $itemDiscountMinor, ')
          ..write('invoiceDiscountMinor: $invoiceDiscountMinor, ')
          ..write('taxableMinor: $taxableMinor, ')
          ..write('taxMinor: $taxMinor, ')
          ..write('cgstMinor: $cgstMinor, ')
          ..write('sgstMinor: $sgstMinor, ')
          ..write('igstMinor: $igstMinor, ')
          ..write('chargesMinor: $chargesMinor, ')
          ..write('roundOffMinor: $roundOffMinor, ')
          ..write('grandTotalMinor: $grandTotalMinor, ')
          ..write('paidAmountMinor: $paidAmountMinor, ')
          ..write('balanceMinor: $balanceMinor, ')
          ..write('notes: $notes, ')
          ..write('terms: $terms, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $InvoiceItemsTable extends InvoiceItems
    with TableInfo<$InvoiceItemsTable, InvoiceItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<int> invoiceId = GeneratedColumn<int>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityScaledMeta = const VerificationMeta(
    'quantityScaled',
  );
  @override
  late final GeneratedColumn<int> quantityScaled = GeneratedColumn<int>(
    'quantity_scaled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMinorMeta = const VerificationMeta(
    'rateMinor',
  );
  @override
  late final GeneratedColumn<int> rateMinor = GeneratedColumn<int>(
    'rate_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hsnSacMeta = const VerificationMeta('hsnSac');
  @override
  late final GeneratedColumn<String> hsnSac = GeneratedColumn<String>(
    'hsn_sac',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxRateBasisPointsMeta =
      const VerificationMeta('taxRateBasisPoints');
  @override
  late final GeneratedColumn<int> taxRateBasisPoints = GeneratedColumn<int>(
    'tax_rate_basis_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<int> discountValue = GeneratedColumn<int>(
    'discount_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseAmountMinorMeta = const VerificationMeta(
    'baseAmountMinor',
  );
  @override
  late final GeneratedColumn<int> baseAmountMinor = GeneratedColumn<int>(
    'base_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountMinorMeta =
      const VerificationMeta('discountAmountMinor');
  @override
  late final GeneratedColumn<int> discountAmountMinor = GeneratedColumn<int>(
    'discount_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxableAmountMinorMeta =
      const VerificationMeta('taxableAmountMinor');
  @override
  late final GeneratedColumn<int> taxableAmountMinor = GeneratedColumn<int>(
    'taxable_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxAmountMinorMeta = const VerificationMeta(
    'taxAmountMinor',
  );
  @override
  late final GeneratedColumn<int> taxAmountMinor = GeneratedColumn<int>(
    'tax_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMinorMeta = const VerificationMeta(
    'totalMinor',
  );
  @override
  late final GeneratedColumn<int> totalMinor = GeneratedColumn<int>(
    'total_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    productId,
    name,
    description,
    quantityScaled,
    unit,
    rateMinor,
    hsnSac,
    taxRateBasisPoints,
    discountType,
    discountValue,
    baseAmountMinor,
    discountAmountMinor,
    taxableAmountMinor,
    taxAmountMinor,
    totalMinor,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('quantity_scaled')) {
      context.handle(
        _quantityScaledMeta,
        quantityScaled.isAcceptableOrUnknown(
          data['quantity_scaled']!,
          _quantityScaledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityScaledMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('rate_minor')) {
      context.handle(
        _rateMinorMeta,
        rateMinor.isAcceptableOrUnknown(data['rate_minor']!, _rateMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMinorMeta);
    }
    if (data.containsKey('hsn_sac')) {
      context.handle(
        _hsnSacMeta,
        hsnSac.isAcceptableOrUnknown(data['hsn_sac']!, _hsnSacMeta),
      );
    }
    if (data.containsKey('tax_rate_basis_points')) {
      context.handle(
        _taxRateBasisPointsMeta,
        taxRateBasisPoints.isAcceptableOrUnknown(
          data['tax_rate_basis_points']!,
          _taxRateBasisPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxRateBasisPointsMeta);
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountTypeMeta);
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    }
    if (data.containsKey('base_amount_minor')) {
      context.handle(
        _baseAmountMinorMeta,
        baseAmountMinor.isAcceptableOrUnknown(
          data['base_amount_minor']!,
          _baseAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseAmountMinorMeta);
    }
    if (data.containsKey('discount_amount_minor')) {
      context.handle(
        _discountAmountMinorMeta,
        discountAmountMinor.isAcceptableOrUnknown(
          data['discount_amount_minor']!,
          _discountAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountAmountMinorMeta);
    }
    if (data.containsKey('taxable_amount_minor')) {
      context.handle(
        _taxableAmountMinorMeta,
        taxableAmountMinor.isAcceptableOrUnknown(
          data['taxable_amount_minor']!,
          _taxableAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxableAmountMinorMeta);
    }
    if (data.containsKey('tax_amount_minor')) {
      context.handle(
        _taxAmountMinorMeta,
        taxAmountMinor.isAcceptableOrUnknown(
          data['tax_amount_minor']!,
          _taxAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxAmountMinorMeta);
    }
    if (data.containsKey('total_minor')) {
      context.handle(
        _totalMinorMeta,
        totalMinor.isAcceptableOrUnknown(data['total_minor']!, _totalMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMinorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invoice_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      quantityScaled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_scaled'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      rateMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_minor'],
      )!,
      hsnSac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hsn_sac'],
      ),
      taxRateBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_basis_points'],
      )!,
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_value'],
      )!,
      baseAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_amount_minor'],
      )!,
      discountAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_amount_minor'],
      )!,
      taxableAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taxable_amount_minor'],
      )!,
      taxAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_amount_minor'],
      )!,
      totalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minor'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $InvoiceItemsTable createAlias(String alias) {
    return $InvoiceItemsTable(attachedDatabase, alias);
  }
}

class InvoiceItem extends DataClass implements Insertable<InvoiceItem> {
  final int id;
  final int invoiceId;
  final int? productId;
  final String name;
  final String? description;
  final int quantityScaled;
  final String unit;
  final int rateMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;
  final String discountType;
  final int discountValue;
  final int baseAmountMinor;
  final int discountAmountMinor;
  final int taxableAmountMinor;
  final int taxAmountMinor;
  final int totalMinor;
  final int sortOrder;
  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    this.productId,
    required this.name,
    this.description,
    required this.quantityScaled,
    required this.unit,
    required this.rateMinor,
    this.hsnSac,
    required this.taxRateBasisPoints,
    required this.discountType,
    required this.discountValue,
    required this.baseAmountMinor,
    required this.discountAmountMinor,
    required this.taxableAmountMinor,
    required this.taxAmountMinor,
    required this.totalMinor,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<int>(invoiceId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['quantity_scaled'] = Variable<int>(quantityScaled);
    map['unit'] = Variable<String>(unit);
    map['rate_minor'] = Variable<int>(rateMinor);
    if (!nullToAbsent || hsnSac != null) {
      map['hsn_sac'] = Variable<String>(hsnSac);
    }
    map['tax_rate_basis_points'] = Variable<int>(taxRateBasisPoints);
    map['discount_type'] = Variable<String>(discountType);
    map['discount_value'] = Variable<int>(discountValue);
    map['base_amount_minor'] = Variable<int>(baseAmountMinor);
    map['discount_amount_minor'] = Variable<int>(discountAmountMinor);
    map['taxable_amount_minor'] = Variable<int>(taxableAmountMinor);
    map['tax_amount_minor'] = Variable<int>(taxAmountMinor);
    map['total_minor'] = Variable<int>(totalMinor);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  InvoiceItemsCompanion toCompanion(bool nullToAbsent) {
    return InvoiceItemsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      quantityScaled: Value(quantityScaled),
      unit: Value(unit),
      rateMinor: Value(rateMinor),
      hsnSac: hsnSac == null && nullToAbsent
          ? const Value.absent()
          : Value(hsnSac),
      taxRateBasisPoints: Value(taxRateBasisPoints),
      discountType: Value(discountType),
      discountValue: Value(discountValue),
      baseAmountMinor: Value(baseAmountMinor),
      discountAmountMinor: Value(discountAmountMinor),
      taxableAmountMinor: Value(taxableAmountMinor),
      taxAmountMinor: Value(taxAmountMinor),
      totalMinor: Value(totalMinor),
      sortOrder: Value(sortOrder),
    );
  }

  factory InvoiceItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceItem(
      id: serializer.fromJson<int>(json['id']),
      invoiceId: serializer.fromJson<int>(json['invoiceId']),
      productId: serializer.fromJson<int?>(json['productId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      quantityScaled: serializer.fromJson<int>(json['quantityScaled']),
      unit: serializer.fromJson<String>(json['unit']),
      rateMinor: serializer.fromJson<int>(json['rateMinor']),
      hsnSac: serializer.fromJson<String?>(json['hsnSac']),
      taxRateBasisPoints: serializer.fromJson<int>(json['taxRateBasisPoints']),
      discountType: serializer.fromJson<String>(json['discountType']),
      discountValue: serializer.fromJson<int>(json['discountValue']),
      baseAmountMinor: serializer.fromJson<int>(json['baseAmountMinor']),
      discountAmountMinor: serializer.fromJson<int>(
        json['discountAmountMinor'],
      ),
      taxableAmountMinor: serializer.fromJson<int>(json['taxableAmountMinor']),
      taxAmountMinor: serializer.fromJson<int>(json['taxAmountMinor']),
      totalMinor: serializer.fromJson<int>(json['totalMinor']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceId': serializer.toJson<int>(invoiceId),
      'productId': serializer.toJson<int?>(productId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'quantityScaled': serializer.toJson<int>(quantityScaled),
      'unit': serializer.toJson<String>(unit),
      'rateMinor': serializer.toJson<int>(rateMinor),
      'hsnSac': serializer.toJson<String?>(hsnSac),
      'taxRateBasisPoints': serializer.toJson<int>(taxRateBasisPoints),
      'discountType': serializer.toJson<String>(discountType),
      'discountValue': serializer.toJson<int>(discountValue),
      'baseAmountMinor': serializer.toJson<int>(baseAmountMinor),
      'discountAmountMinor': serializer.toJson<int>(discountAmountMinor),
      'taxableAmountMinor': serializer.toJson<int>(taxableAmountMinor),
      'taxAmountMinor': serializer.toJson<int>(taxAmountMinor),
      'totalMinor': serializer.toJson<int>(totalMinor),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    Value<int?> productId = const Value.absent(),
    String? name,
    Value<String?> description = const Value.absent(),
    int? quantityScaled,
    String? unit,
    int? rateMinor,
    Value<String?> hsnSac = const Value.absent(),
    int? taxRateBasisPoints,
    String? discountType,
    int? discountValue,
    int? baseAmountMinor,
    int? discountAmountMinor,
    int? taxableAmountMinor,
    int? taxAmountMinor,
    int? totalMinor,
    int? sortOrder,
  }) => InvoiceItem(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    productId: productId.present ? productId.value : this.productId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    quantityScaled: quantityScaled ?? this.quantityScaled,
    unit: unit ?? this.unit,
    rateMinor: rateMinor ?? this.rateMinor,
    hsnSac: hsnSac.present ? hsnSac.value : this.hsnSac,
    taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
    discountType: discountType ?? this.discountType,
    discountValue: discountValue ?? this.discountValue,
    baseAmountMinor: baseAmountMinor ?? this.baseAmountMinor,
    discountAmountMinor: discountAmountMinor ?? this.discountAmountMinor,
    taxableAmountMinor: taxableAmountMinor ?? this.taxableAmountMinor,
    taxAmountMinor: taxAmountMinor ?? this.taxAmountMinor,
    totalMinor: totalMinor ?? this.totalMinor,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  InvoiceItem copyWithCompanion(InvoiceItemsCompanion data) {
    return InvoiceItem(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      productId: data.productId.present ? data.productId.value : this.productId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      quantityScaled: data.quantityScaled.present
          ? data.quantityScaled.value
          : this.quantityScaled,
      unit: data.unit.present ? data.unit.value : this.unit,
      rateMinor: data.rateMinor.present ? data.rateMinor.value : this.rateMinor,
      hsnSac: data.hsnSac.present ? data.hsnSac.value : this.hsnSac,
      taxRateBasisPoints: data.taxRateBasisPoints.present
          ? data.taxRateBasisPoints.value
          : this.taxRateBasisPoints,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      baseAmountMinor: data.baseAmountMinor.present
          ? data.baseAmountMinor.value
          : this.baseAmountMinor,
      discountAmountMinor: data.discountAmountMinor.present
          ? data.discountAmountMinor.value
          : this.discountAmountMinor,
      taxableAmountMinor: data.taxableAmountMinor.present
          ? data.taxableAmountMinor.value
          : this.taxableAmountMinor,
      taxAmountMinor: data.taxAmountMinor.present
          ? data.taxAmountMinor.value
          : this.taxAmountMinor,
      totalMinor: data.totalMinor.present
          ? data.totalMinor.value
          : this.totalMinor,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItem(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('quantityScaled: $quantityScaled, ')
          ..write('unit: $unit, ')
          ..write('rateMinor: $rateMinor, ')
          ..write('hsnSac: $hsnSac, ')
          ..write('taxRateBasisPoints: $taxRateBasisPoints, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('baseAmountMinor: $baseAmountMinor, ')
          ..write('discountAmountMinor: $discountAmountMinor, ')
          ..write('taxableAmountMinor: $taxableAmountMinor, ')
          ..write('taxAmountMinor: $taxAmountMinor, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invoiceId,
    productId,
    name,
    description,
    quantityScaled,
    unit,
    rateMinor,
    hsnSac,
    taxRateBasisPoints,
    discountType,
    discountValue,
    baseAmountMinor,
    discountAmountMinor,
    taxableAmountMinor,
    taxAmountMinor,
    totalMinor,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceItem &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.productId == this.productId &&
          other.name == this.name &&
          other.description == this.description &&
          other.quantityScaled == this.quantityScaled &&
          other.unit == this.unit &&
          other.rateMinor == this.rateMinor &&
          other.hsnSac == this.hsnSac &&
          other.taxRateBasisPoints == this.taxRateBasisPoints &&
          other.discountType == this.discountType &&
          other.discountValue == this.discountValue &&
          other.baseAmountMinor == this.baseAmountMinor &&
          other.discountAmountMinor == this.discountAmountMinor &&
          other.taxableAmountMinor == this.taxableAmountMinor &&
          other.taxAmountMinor == this.taxAmountMinor &&
          other.totalMinor == this.totalMinor &&
          other.sortOrder == this.sortOrder);
}

class InvoiceItemsCompanion extends UpdateCompanion<InvoiceItem> {
  final Value<int> id;
  final Value<int> invoiceId;
  final Value<int?> productId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> quantityScaled;
  final Value<String> unit;
  final Value<int> rateMinor;
  final Value<String?> hsnSac;
  final Value<int> taxRateBasisPoints;
  final Value<String> discountType;
  final Value<int> discountValue;
  final Value<int> baseAmountMinor;
  final Value<int> discountAmountMinor;
  final Value<int> taxableAmountMinor;
  final Value<int> taxAmountMinor;
  final Value<int> totalMinor;
  final Value<int> sortOrder;
  const InvoiceItemsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.quantityScaled = const Value.absent(),
    this.unit = const Value.absent(),
    this.rateMinor = const Value.absent(),
    this.hsnSac = const Value.absent(),
    this.taxRateBasisPoints = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.baseAmountMinor = const Value.absent(),
    this.discountAmountMinor = const Value.absent(),
    this.taxableAmountMinor = const Value.absent(),
    this.taxAmountMinor = const Value.absent(),
    this.totalMinor = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  InvoiceItemsCompanion.insert({
    this.id = const Value.absent(),
    required int invoiceId,
    this.productId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required int quantityScaled,
    required String unit,
    required int rateMinor,
    this.hsnSac = const Value.absent(),
    required int taxRateBasisPoints,
    required String discountType,
    this.discountValue = const Value.absent(),
    required int baseAmountMinor,
    required int discountAmountMinor,
    required int taxableAmountMinor,
    required int taxAmountMinor,
    required int totalMinor,
    required int sortOrder,
  }) : invoiceId = Value(invoiceId),
       name = Value(name),
       quantityScaled = Value(quantityScaled),
       unit = Value(unit),
       rateMinor = Value(rateMinor),
       taxRateBasisPoints = Value(taxRateBasisPoints),
       discountType = Value(discountType),
       baseAmountMinor = Value(baseAmountMinor),
       discountAmountMinor = Value(discountAmountMinor),
       taxableAmountMinor = Value(taxableAmountMinor),
       taxAmountMinor = Value(taxAmountMinor),
       totalMinor = Value(totalMinor),
       sortOrder = Value(sortOrder);
  static Insertable<InvoiceItem> custom({
    Expression<int>? id,
    Expression<int>? invoiceId,
    Expression<int>? productId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? quantityScaled,
    Expression<String>? unit,
    Expression<int>? rateMinor,
    Expression<String>? hsnSac,
    Expression<int>? taxRateBasisPoints,
    Expression<String>? discountType,
    Expression<int>? discountValue,
    Expression<int>? baseAmountMinor,
    Expression<int>? discountAmountMinor,
    Expression<int>? taxableAmountMinor,
    Expression<int>? taxAmountMinor,
    Expression<int>? totalMinor,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productId != null) 'product_id': productId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (quantityScaled != null) 'quantity_scaled': quantityScaled,
      if (unit != null) 'unit': unit,
      if (rateMinor != null) 'rate_minor': rateMinor,
      if (hsnSac != null) 'hsn_sac': hsnSac,
      if (taxRateBasisPoints != null)
        'tax_rate_basis_points': taxRateBasisPoints,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (baseAmountMinor != null) 'base_amount_minor': baseAmountMinor,
      if (discountAmountMinor != null)
        'discount_amount_minor': discountAmountMinor,
      if (taxableAmountMinor != null)
        'taxable_amount_minor': taxableAmountMinor,
      if (taxAmountMinor != null) 'tax_amount_minor': taxAmountMinor,
      if (totalMinor != null) 'total_minor': totalMinor,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  InvoiceItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? invoiceId,
    Value<int?>? productId,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? quantityScaled,
    Value<String>? unit,
    Value<int>? rateMinor,
    Value<String?>? hsnSac,
    Value<int>? taxRateBasisPoints,
    Value<String>? discountType,
    Value<int>? discountValue,
    Value<int>? baseAmountMinor,
    Value<int>? discountAmountMinor,
    Value<int>? taxableAmountMinor,
    Value<int>? taxAmountMinor,
    Value<int>? totalMinor,
    Value<int>? sortOrder,
  }) {
    return InvoiceItemsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantityScaled: quantityScaled ?? this.quantityScaled,
      unit: unit ?? this.unit,
      rateMinor: rateMinor ?? this.rateMinor,
      hsnSac: hsnSac ?? this.hsnSac,
      taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      baseAmountMinor: baseAmountMinor ?? this.baseAmountMinor,
      discountAmountMinor: discountAmountMinor ?? this.discountAmountMinor,
      taxableAmountMinor: taxableAmountMinor ?? this.taxableAmountMinor,
      taxAmountMinor: taxAmountMinor ?? this.taxAmountMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<int>(invoiceId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (quantityScaled.present) {
      map['quantity_scaled'] = Variable<int>(quantityScaled.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (rateMinor.present) {
      map['rate_minor'] = Variable<int>(rateMinor.value);
    }
    if (hsnSac.present) {
      map['hsn_sac'] = Variable<String>(hsnSac.value);
    }
    if (taxRateBasisPoints.present) {
      map['tax_rate_basis_points'] = Variable<int>(taxRateBasisPoints.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<int>(discountValue.value);
    }
    if (baseAmountMinor.present) {
      map['base_amount_minor'] = Variable<int>(baseAmountMinor.value);
    }
    if (discountAmountMinor.present) {
      map['discount_amount_minor'] = Variable<int>(discountAmountMinor.value);
    }
    if (taxableAmountMinor.present) {
      map['taxable_amount_minor'] = Variable<int>(taxableAmountMinor.value);
    }
    if (taxAmountMinor.present) {
      map['tax_amount_minor'] = Variable<int>(taxAmountMinor.value);
    }
    if (totalMinor.present) {
      map['total_minor'] = Variable<int>(totalMinor.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('quantityScaled: $quantityScaled, ')
          ..write('unit: $unit, ')
          ..write('rateMinor: $rateMinor, ')
          ..write('hsnSac: $hsnSac, ')
          ..write('taxRateBasisPoints: $taxRateBasisPoints, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('baseAmountMinor: $baseAmountMinor, ')
          ..write('discountAmountMinor: $discountAmountMinor, ')
          ..write('taxableAmountMinor: $taxableAmountMinor, ')
          ..write('taxAmountMinor: $taxAmountMinor, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $InvoiceChargesTable extends InvoiceCharges
    with TableInfo<$InvoiceChargesTable, InvoiceCharge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceChargesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<int> invoiceId = GeneratedColumn<int>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    title,
    amountMinor,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_charges';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceCharge> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceCharge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceCharge(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invoice_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $InvoiceChargesTable createAlias(String alias) {
    return $InvoiceChargesTable(attachedDatabase, alias);
  }
}

class InvoiceCharge extends DataClass implements Insertable<InvoiceCharge> {
  final int id;
  final int invoiceId;
  final String title;
  final int amountMinor;
  final int sortOrder;
  const InvoiceCharge({
    required this.id,
    required this.invoiceId,
    required this.title,
    required this.amountMinor,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<int>(invoiceId);
    map['title'] = Variable<String>(title);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  InvoiceChargesCompanion toCompanion(bool nullToAbsent) {
    return InvoiceChargesCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      title: Value(title),
      amountMinor: Value(amountMinor),
      sortOrder: Value(sortOrder),
    );
  }

  factory InvoiceCharge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceCharge(
      id: serializer.fromJson<int>(json['id']),
      invoiceId: serializer.fromJson<int>(json['invoiceId']),
      title: serializer.fromJson<String>(json['title']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceId': serializer.toJson<int>(invoiceId),
      'title': serializer.toJson<String>(title),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  InvoiceCharge copyWith({
    int? id,
    int? invoiceId,
    String? title,
    int? amountMinor,
    int? sortOrder,
  }) => InvoiceCharge(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    title: title ?? this.title,
    amountMinor: amountMinor ?? this.amountMinor,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  InvoiceCharge copyWithCompanion(InvoiceChargesCompanion data) {
    return InvoiceCharge(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      title: data.title.present ? data.title.value : this.title,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceCharge(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('title: $title, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, invoiceId, title, amountMinor, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceCharge &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.title == this.title &&
          other.amountMinor == this.amountMinor &&
          other.sortOrder == this.sortOrder);
}

class InvoiceChargesCompanion extends UpdateCompanion<InvoiceCharge> {
  final Value<int> id;
  final Value<int> invoiceId;
  final Value<String> title;
  final Value<int> amountMinor;
  final Value<int> sortOrder;
  const InvoiceChargesCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.title = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  InvoiceChargesCompanion.insert({
    this.id = const Value.absent(),
    required int invoiceId,
    required String title,
    required int amountMinor,
    required int sortOrder,
  }) : invoiceId = Value(invoiceId),
       title = Value(title),
       amountMinor = Value(amountMinor),
       sortOrder = Value(sortOrder);
  static Insertable<InvoiceCharge> custom({
    Expression<int>? id,
    Expression<int>? invoiceId,
    Expression<String>? title,
    Expression<int>? amountMinor,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (title != null) 'title': title,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  InvoiceChargesCompanion copyWith({
    Value<int>? id,
    Value<int>? invoiceId,
    Value<String>? title,
    Value<int>? amountMinor,
    Value<int>? sortOrder,
  }) {
    return InvoiceChargesCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      title: title ?? this.title,
      amountMinor: amountMinor ?? this.amountMinor,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<int>(invoiceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceChargesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('title: $title, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DatabaseMetadataTable databaseMetadata = $DatabaseMetadataTable(
    this,
  );
  late final $BusinessProfilesTable businessProfiles = $BusinessProfilesTable(
    this,
  );
  late final $CustomersTable customers = $CustomersTable(this);
  late final $ProductServicesTable productServices = $ProductServicesTable(
    this,
  );
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceItemsTable invoiceItems = $InvoiceItemsTable(this);
  late final $InvoiceChargesTable invoiceCharges = $InvoiceChargesTable(this);
  late final Index customersName = Index(
    'customers_name',
    'CREATE INDEX customers_name ON customers (name)',
  );
  late final Index customersMobile = Index(
    'customers_mobile',
    'CREATE INDEX customers_mobile ON customers (mobile)',
  );
  late final Index customersGstin = Index(
    'customers_gstin',
    'CREATE INDEX customers_gstin ON customers (gstin)',
  );
  late final Index productsName = Index(
    'products_name',
    'CREATE INDEX products_name ON product_services (name)',
  );
  late final Index productsType = Index(
    'products_type',
    'CREATE INDEX products_type ON product_services (type)',
  );
  late final Index invoicesNumber = Index(
    'invoices_number',
    'CREATE UNIQUE INDEX invoices_number ON invoices (invoice_number)',
  );
  late final Index invoicesStatus = Index(
    'invoices_status',
    'CREATE INDEX invoices_status ON invoices (status)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    databaseMetadata,
    businessProfiles,
    customers,
    productServices,
    invoices,
    invoiceItems,
    invoiceCharges,
    customersName,
    customersMobile,
    customersGstin,
    productsName,
    productsType,
    invoicesNumber,
    invoicesStatus,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invoice_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invoice_charges', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DatabaseMetadataTableCreateCompanionBuilder =
    DatabaseMetadataCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DatabaseMetadataTableUpdateCompanionBuilder =
    DatabaseMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DatabaseMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $DatabaseMetadataTable> {
  $$DatabaseMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DatabaseMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $DatabaseMetadataTable> {
  $$DatabaseMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DatabaseMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatabaseMetadataTable> {
  $$DatabaseMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DatabaseMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DatabaseMetadataTable,
          DatabaseMetadataData,
          $$DatabaseMetadataTableFilterComposer,
          $$DatabaseMetadataTableOrderingComposer,
          $$DatabaseMetadataTableAnnotationComposer,
          $$DatabaseMetadataTableCreateCompanionBuilder,
          $$DatabaseMetadataTableUpdateCompanionBuilder,
          (
            DatabaseMetadataData,
            BaseReferences<
              _$AppDatabase,
              $DatabaseMetadataTable,
              DatabaseMetadataData
            >,
          ),
          DatabaseMetadataData,
          PrefetchHooks Function()
        > {
  $$DatabaseMetadataTableTableManager(
    _$AppDatabase db,
    $DatabaseMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatabaseMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatabaseMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatabaseMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DatabaseMetadataCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DatabaseMetadataCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DatabaseMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DatabaseMetadataTable,
      DatabaseMetadataData,
      $$DatabaseMetadataTableFilterComposer,
      $$DatabaseMetadataTableOrderingComposer,
      $$DatabaseMetadataTableAnnotationComposer,
      $$DatabaseMetadataTableCreateCompanionBuilder,
      $$DatabaseMetadataTableUpdateCompanionBuilder,
      (
        DatabaseMetadataData,
        BaseReferences<
          _$AppDatabase,
          $DatabaseMetadataTable,
          DatabaseMetadataData
        >,
      ),
      DatabaseMetadataData,
      PrefetchHooks Function()
    >;
typedef $$BusinessProfilesTableCreateCompanionBuilder =
    BusinessProfilesCompanion Function({
      Value<int> id,
      required String businessName,
      Value<String?> ownerName,
      Value<String?> logoPath,
      Value<String?> mobile,
      Value<String?> email,
      Value<String?> address,
      Value<String?> city,
      Value<String?> state,
      Value<String?> pinCode,
      Value<bool> gstRegistered,
      Value<String?> gstin,
      Value<String?> pan,
      Value<String> invoicePrefix,
      Value<int> startingInvoiceNumber,
      Value<String> currencyCode,
      Value<String> currencySymbol,
      Value<String?> bankName,
      Value<String?> accountHolderName,
      Value<String?> accountNumber,
      Value<String?> ifsc,
      Value<String?> upiId,
      Value<String?> paymentQrPath,
      Value<String?> signaturePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BusinessProfilesTableUpdateCompanionBuilder =
    BusinessProfilesCompanion Function({
      Value<int> id,
      Value<String> businessName,
      Value<String?> ownerName,
      Value<String?> logoPath,
      Value<String?> mobile,
      Value<String?> email,
      Value<String?> address,
      Value<String?> city,
      Value<String?> state,
      Value<String?> pinCode,
      Value<bool> gstRegistered,
      Value<String?> gstin,
      Value<String?> pan,
      Value<String> invoicePrefix,
      Value<int> startingInvoiceNumber,
      Value<String> currencyCode,
      Value<String> currencySymbol,
      Value<String?> bankName,
      Value<String?> accountHolderName,
      Value<String?> accountNumber,
      Value<String?> ifsc,
      Value<String?> upiId,
      Value<String?> paymentQrPath,
      Value<String?> signaturePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$BusinessProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gstRegistered => $composableBuilder(
    column: $table.gstRegistered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pan => $composableBuilder(
    column: $table.pan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startingInvoiceNumber => $composableBuilder(
    column: $table.startingInvoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountHolderName => $composableBuilder(
    column: $table.accountHolderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ifsc => $composableBuilder(
    column: $table.ifsc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get upiId => $composableBuilder(
    column: $table.upiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentQrPath => $composableBuilder(
    column: $table.paymentQrPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signaturePath => $composableBuilder(
    column: $table.signaturePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gstRegistered => $composableBuilder(
    column: $table.gstRegistered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pan => $composableBuilder(
    column: $table.pan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startingInvoiceNumber => $composableBuilder(
    column: $table.startingInvoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountHolderName => $composableBuilder(
    column: $table.accountHolderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ifsc => $composableBuilder(
    column: $table.ifsc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get upiId => $composableBuilder(
    column: $table.upiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentQrPath => $composableBuilder(
    column: $table.paymentQrPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signaturePath => $composableBuilder(
    column: $table.signaturePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get pinCode =>
      $composableBuilder(column: $table.pinCode, builder: (column) => column);

  GeneratedColumn<bool> get gstRegistered => $composableBuilder(
    column: $table.gstRegistered,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gstin =>
      $composableBuilder(column: $table.gstin, builder: (column) => column);

  GeneratedColumn<String> get pan =>
      $composableBuilder(column: $table.pan, builder: (column) => column);

  GeneratedColumn<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startingInvoiceNumber => $composableBuilder(
    column: $table.startingInvoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get accountHolderName => $composableBuilder(
    column: $table.accountHolderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ifsc =>
      $composableBuilder(column: $table.ifsc, builder: (column) => column);

  GeneratedColumn<String> get upiId =>
      $composableBuilder(column: $table.upiId, builder: (column) => column);

  GeneratedColumn<String> get paymentQrPath => $composableBuilder(
    column: $table.paymentQrPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signaturePath => $composableBuilder(
    column: $table.signaturePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BusinessProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessProfilesTable,
          BusinessProfile,
          $$BusinessProfilesTableFilterComposer,
          $$BusinessProfilesTableOrderingComposer,
          $$BusinessProfilesTableAnnotationComposer,
          $$BusinessProfilesTableCreateCompanionBuilder,
          $$BusinessProfilesTableUpdateCompanionBuilder,
          (
            BusinessProfile,
            BaseReferences<
              _$AppDatabase,
              $BusinessProfilesTable,
              BusinessProfile
            >,
          ),
          BusinessProfile,
          PrefetchHooks Function()
        > {
  $$BusinessProfilesTableTableManager(
    _$AppDatabase db,
    $BusinessProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String?> ownerName = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<bool> gstRegistered = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<String?> pan = const Value.absent(),
                Value<String> invoicePrefix = const Value.absent(),
                Value<int> startingInvoiceNumber = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> accountHolderName = const Value.absent(),
                Value<String?> accountNumber = const Value.absent(),
                Value<String?> ifsc = const Value.absent(),
                Value<String?> upiId = const Value.absent(),
                Value<String?> paymentQrPath = const Value.absent(),
                Value<String?> signaturePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BusinessProfilesCompanion(
                id: id,
                businessName: businessName,
                ownerName: ownerName,
                logoPath: logoPath,
                mobile: mobile,
                email: email,
                address: address,
                city: city,
                state: state,
                pinCode: pinCode,
                gstRegistered: gstRegistered,
                gstin: gstin,
                pan: pan,
                invoicePrefix: invoicePrefix,
                startingInvoiceNumber: startingInvoiceNumber,
                currencyCode: currencyCode,
                currencySymbol: currencySymbol,
                bankName: bankName,
                accountHolderName: accountHolderName,
                accountNumber: accountNumber,
                ifsc: ifsc,
                upiId: upiId,
                paymentQrPath: paymentQrPath,
                signaturePath: signaturePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String businessName,
                Value<String?> ownerName = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<bool> gstRegistered = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<String?> pan = const Value.absent(),
                Value<String> invoicePrefix = const Value.absent(),
                Value<int> startingInvoiceNumber = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> accountHolderName = const Value.absent(),
                Value<String?> accountNumber = const Value.absent(),
                Value<String?> ifsc = const Value.absent(),
                Value<String?> upiId = const Value.absent(),
                Value<String?> paymentQrPath = const Value.absent(),
                Value<String?> signaturePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BusinessProfilesCompanion.insert(
                id: id,
                businessName: businessName,
                ownerName: ownerName,
                logoPath: logoPath,
                mobile: mobile,
                email: email,
                address: address,
                city: city,
                state: state,
                pinCode: pinCode,
                gstRegistered: gstRegistered,
                gstin: gstin,
                pan: pan,
                invoicePrefix: invoicePrefix,
                startingInvoiceNumber: startingInvoiceNumber,
                currencyCode: currencyCode,
                currencySymbol: currencySymbol,
                bankName: bankName,
                accountHolderName: accountHolderName,
                accountNumber: accountNumber,
                ifsc: ifsc,
                upiId: upiId,
                paymentQrPath: paymentQrPath,
                signaturePath: signaturePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessProfilesTable,
      BusinessProfile,
      $$BusinessProfilesTableFilterComposer,
      $$BusinessProfilesTableOrderingComposer,
      $$BusinessProfilesTableAnnotationComposer,
      $$BusinessProfilesTableCreateCompanionBuilder,
      $$BusinessProfilesTableUpdateCompanionBuilder,
      (
        BusinessProfile,
        BaseReferences<_$AppDatabase, $BusinessProfilesTable, BusinessProfile>,
      ),
      BusinessProfile,
      PrefetchHooks Function()
    >;
typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> companyName,
      Value<String?> mobile,
      Value<String?> email,
      Value<String?> address,
      Value<String?> city,
      Value<String?> state,
      Value<String?> pinCode,
      Value<String?> gstin,
      Value<String?> notes,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> companyName,
      Value<String?> mobile,
      Value<String?> email,
      Value<String?> address,
      Value<String?> city,
      Value<String?> state,
      Value<String?> pinCode,
      Value<String?> gstin,
      Value<String?> notes,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get pinCode =>
      $composableBuilder(column: $table.pinCode, builder: (column) => column);

  GeneratedColumn<String> get gstin =>
      $composableBuilder(column: $table.gstin, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          Customer,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
          Customer,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                name: name,
                companyName: companyName,
                mobile: mobile,
                email: email,
                address: address,
                city: city,
                state: state,
                pinCode: pinCode,
                gstin: gstin,
                notes: notes,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> companyName = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                name: name,
                companyName: companyName,
                mobile: mobile,
                email: email,
                address: address,
                city: city,
                state: state,
                pinCode: pinCode,
                gstin: gstin,
                notes: notes,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      Customer,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
      Customer,
      PrefetchHooks Function()
    >;
typedef $$ProductServicesTableCreateCompanionBuilder =
    ProductServicesCompanion Function({
      Value<int> id,
      required String name,
      required String type,
      Value<String?> description,
      required String unit,
      required int salePriceMinor,
      Value<String?> hsnSac,
      Value<int> taxRateBasisPoints,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ProductServicesTableUpdateCompanionBuilder =
    ProductServicesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> type,
      Value<String?> description,
      Value<String> unit,
      Value<int> salePriceMinor,
      Value<String?> hsnSac,
      Value<int> taxRateBasisPoints,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ProductServicesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductServicesTable> {
  $$ProductServicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get salePriceMinor => $composableBuilder(
    column: $table.salePriceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hsnSac => $composableBuilder(
    column: $table.hsnSac,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductServicesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductServicesTable> {
  $$ProductServicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salePriceMinor => $composableBuilder(
    column: $table.salePriceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hsnSac => $composableBuilder(
    column: $table.hsnSac,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductServicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductServicesTable> {
  $$ProductServicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get salePriceMinor => $composableBuilder(
    column: $table.salePriceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hsnSac =>
      $composableBuilder(column: $table.hsnSac, builder: (column) => column);

  GeneratedColumn<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductServicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductServicesTable,
          ProductService,
          $$ProductServicesTableFilterComposer,
          $$ProductServicesTableOrderingComposer,
          $$ProductServicesTableAnnotationComposer,
          $$ProductServicesTableCreateCompanionBuilder,
          $$ProductServicesTableUpdateCompanionBuilder,
          (
            ProductService,
            BaseReferences<
              _$AppDatabase,
              $ProductServicesTable,
              ProductService
            >,
          ),
          ProductService,
          PrefetchHooks Function()
        > {
  $$ProductServicesTableTableManager(
    _$AppDatabase db,
    $ProductServicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductServicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductServicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductServicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> salePriceMinor = const Value.absent(),
                Value<String?> hsnSac = const Value.absent(),
                Value<int> taxRateBasisPoints = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductServicesCompanion(
                id: id,
                name: name,
                type: type,
                description: description,
                unit: unit,
                salePriceMinor: salePriceMinor,
                hsnSac: hsnSac,
                taxRateBasisPoints: taxRateBasisPoints,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String type,
                Value<String?> description = const Value.absent(),
                required String unit,
                required int salePriceMinor,
                Value<String?> hsnSac = const Value.absent(),
                Value<int> taxRateBasisPoints = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductServicesCompanion.insert(
                id: id,
                name: name,
                type: type,
                description: description,
                unit: unit,
                salePriceMinor: salePriceMinor,
                hsnSac: hsnSac,
                taxRateBasisPoints: taxRateBasisPoints,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductServicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductServicesTable,
      ProductService,
      $$ProductServicesTableFilterComposer,
      $$ProductServicesTableOrderingComposer,
      $$ProductServicesTableAnnotationComposer,
      $$ProductServicesTableCreateCompanionBuilder,
      $$ProductServicesTableUpdateCompanionBuilder,
      (
        ProductService,
        BaseReferences<_$AppDatabase, $ProductServicesTable, ProductService>,
      ),
      ProductService,
      PrefetchHooks Function()
    >;
typedef $$InvoicesTableCreateCompanionBuilder =
    InvoicesCompanion Function({
      Value<int> id,
      required String invoiceNumber,
      Value<String> documentType,
      Value<int?> customerId,
      required String customerName,
      Value<String?> customerCompany,
      Value<String?> customerMobile,
      Value<String?> customerEmail,
      Value<String?> customerAddress,
      Value<String?> customerCity,
      Value<String?> customerState,
      Value<String?> customerPinCode,
      Value<String?> customerGstin,
      required DateTime invoiceDate,
      Value<DateTime?> dueDate,
      required String status,
      required String taxType,
      required String discountType,
      Value<int> discountValue,
      required int subtotalMinor,
      required int itemDiscountMinor,
      required int invoiceDiscountMinor,
      required int taxableMinor,
      required int taxMinor,
      required int cgstMinor,
      required int sgstMinor,
      required int igstMinor,
      required int chargesMinor,
      required int roundOffMinor,
      required int grandTotalMinor,
      required int paidAmountMinor,
      required int balanceMinor,
      Value<String?> notes,
      Value<String?> terms,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$InvoicesTableUpdateCompanionBuilder =
    InvoicesCompanion Function({
      Value<int> id,
      Value<String> invoiceNumber,
      Value<String> documentType,
      Value<int?> customerId,
      Value<String> customerName,
      Value<String?> customerCompany,
      Value<String?> customerMobile,
      Value<String?> customerEmail,
      Value<String?> customerAddress,
      Value<String?> customerCity,
      Value<String?> customerState,
      Value<String?> customerPinCode,
      Value<String?> customerGstin,
      Value<DateTime> invoiceDate,
      Value<DateTime?> dueDate,
      Value<String> status,
      Value<String> taxType,
      Value<String> discountType,
      Value<int> discountValue,
      Value<int> subtotalMinor,
      Value<int> itemDiscountMinor,
      Value<int> invoiceDiscountMinor,
      Value<int> taxableMinor,
      Value<int> taxMinor,
      Value<int> cgstMinor,
      Value<int> sgstMinor,
      Value<int> igstMinor,
      Value<int> chargesMinor,
      Value<int> roundOffMinor,
      Value<int> grandTotalMinor,
      Value<int> paidAmountMinor,
      Value<int> balanceMinor,
      Value<String?> notes,
      Value<String?> terms,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$InvoicesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoicesTable, Invoice> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItem>>
  _invoiceItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoiceItems,
    aliasName: 'invoices__id__invoice_items__invoice_id',
  );

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager(
      $_db,
      $_db.invoiceItems,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InvoiceChargesTable, List<InvoiceCharge>>
  _invoiceChargesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoiceCharges,
    aliasName: 'invoices__id__invoice_charges__invoice_id',
  );

  $$InvoiceChargesTableProcessedTableManager get invoiceChargesRefs {
    final manager = $$InvoiceChargesTableTableManager(
      $_db,
      $_db.invoiceCharges,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceChargesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerCompany => $composableBuilder(
    column: $table.customerCompany,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerMobile => $composableBuilder(
    column: $table.customerMobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerEmail => $composableBuilder(
    column: $table.customerEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerCity => $composableBuilder(
    column: $table.customerCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerState => $composableBuilder(
    column: $table.customerState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPinCode => $composableBuilder(
    column: $table.customerPinCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerGstin => $composableBuilder(
    column: $table.customerGstin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxType => $composableBuilder(
    column: $table.taxType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalMinor => $composableBuilder(
    column: $table.subtotalMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemDiscountMinor => $composableBuilder(
    column: $table.itemDiscountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get invoiceDiscountMinor => $composableBuilder(
    column: $table.invoiceDiscountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxableMinor => $composableBuilder(
    column: $table.taxableMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxMinor => $composableBuilder(
    column: $table.taxMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cgstMinor => $composableBuilder(
    column: $table.cgstMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sgstMinor => $composableBuilder(
    column: $table.sgstMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get igstMinor => $composableBuilder(
    column: $table.igstMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chargesMinor => $composableBuilder(
    column: $table.chargesMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundOffMinor => $composableBuilder(
    column: $table.roundOffMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grandTotalMinor => $composableBuilder(
    column: $table.grandTotalMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAmountMinor => $composableBuilder(
    column: $table.paidAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terms => $composableBuilder(
    column: $table.terms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> invoiceItemsRefs(
    Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f,
  ) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableFilterComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> invoiceChargesRefs(
    Expression<bool> Function($$InvoiceChargesTableFilterComposer f) f,
  ) {
    final $$InvoiceChargesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceCharges,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceChargesTableFilterComposer(
            $db: $db,
            $table: $db.invoiceCharges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerCompany => $composableBuilder(
    column: $table.customerCompany,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerMobile => $composableBuilder(
    column: $table.customerMobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerEmail => $composableBuilder(
    column: $table.customerEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerCity => $composableBuilder(
    column: $table.customerCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerState => $composableBuilder(
    column: $table.customerState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPinCode => $composableBuilder(
    column: $table.customerPinCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerGstin => $composableBuilder(
    column: $table.customerGstin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxType => $composableBuilder(
    column: $table.taxType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalMinor => $composableBuilder(
    column: $table.subtotalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemDiscountMinor => $composableBuilder(
    column: $table.itemDiscountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get invoiceDiscountMinor => $composableBuilder(
    column: $table.invoiceDiscountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxableMinor => $composableBuilder(
    column: $table.taxableMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxMinor => $composableBuilder(
    column: $table.taxMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cgstMinor => $composableBuilder(
    column: $table.cgstMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sgstMinor => $composableBuilder(
    column: $table.sgstMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get igstMinor => $composableBuilder(
    column: $table.igstMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chargesMinor => $composableBuilder(
    column: $table.chargesMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundOffMinor => $composableBuilder(
    column: $table.roundOffMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grandTotalMinor => $composableBuilder(
    column: $table.grandTotalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAmountMinor => $composableBuilder(
    column: $table.paidAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terms => $composableBuilder(
    column: $table.terms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerCompany => $composableBuilder(
    column: $table.customerCompany,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerMobile => $composableBuilder(
    column: $table.customerMobile,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerEmail => $composableBuilder(
    column: $table.customerEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerCity => $composableBuilder(
    column: $table.customerCity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerState => $composableBuilder(
    column: $table.customerState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPinCode => $composableBuilder(
    column: $table.customerPinCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerGstin => $composableBuilder(
    column: $table.customerGstin,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get taxType =>
      $composableBuilder(column: $table.taxType, builder: (column) => column);

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotalMinor => $composableBuilder(
    column: $table.subtotalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemDiscountMinor => $composableBuilder(
    column: $table.itemDiscountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get invoiceDiscountMinor => $composableBuilder(
    column: $table.invoiceDiscountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxableMinor => $composableBuilder(
    column: $table.taxableMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxMinor =>
      $composableBuilder(column: $table.taxMinor, builder: (column) => column);

  GeneratedColumn<int> get cgstMinor =>
      $composableBuilder(column: $table.cgstMinor, builder: (column) => column);

  GeneratedColumn<int> get sgstMinor =>
      $composableBuilder(column: $table.sgstMinor, builder: (column) => column);

  GeneratedColumn<int> get igstMinor =>
      $composableBuilder(column: $table.igstMinor, builder: (column) => column);

  GeneratedColumn<int> get chargesMinor => $composableBuilder(
    column: $table.chargesMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundOffMinor => $composableBuilder(
    column: $table.roundOffMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grandTotalMinor => $composableBuilder(
    column: $table.grandTotalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidAmountMinor => $composableBuilder(
    column: $table.paidAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get terms =>
      $composableBuilder(column: $table.terms, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> invoiceItemsRefs<T extends Object>(
    Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f,
  ) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> invoiceChargesRefs<T extends Object>(
    Expression<T> Function($$InvoiceChargesTableAnnotationComposer a) f,
  ) {
    final $$InvoiceChargesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceCharges,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceChargesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceCharges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoicesTable,
          Invoice,
          $$InvoicesTableFilterComposer,
          $$InvoicesTableOrderingComposer,
          $$InvoicesTableAnnotationComposer,
          $$InvoicesTableCreateCompanionBuilder,
          $$InvoicesTableUpdateCompanionBuilder,
          (Invoice, $$InvoicesTableReferences),
          Invoice,
          PrefetchHooks Function({
            bool invoiceItemsRefs,
            bool invoiceChargesRefs,
          })
        > {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> invoiceNumber = const Value.absent(),
                Value<String> documentType = const Value.absent(),
                Value<int?> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String?> customerCompany = const Value.absent(),
                Value<String?> customerMobile = const Value.absent(),
                Value<String?> customerEmail = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<String?> customerCity = const Value.absent(),
                Value<String?> customerState = const Value.absent(),
                Value<String?> customerPinCode = const Value.absent(),
                Value<String?> customerGstin = const Value.absent(),
                Value<DateTime> invoiceDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> taxType = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                Value<int> discountValue = const Value.absent(),
                Value<int> subtotalMinor = const Value.absent(),
                Value<int> itemDiscountMinor = const Value.absent(),
                Value<int> invoiceDiscountMinor = const Value.absent(),
                Value<int> taxableMinor = const Value.absent(),
                Value<int> taxMinor = const Value.absent(),
                Value<int> cgstMinor = const Value.absent(),
                Value<int> sgstMinor = const Value.absent(),
                Value<int> igstMinor = const Value.absent(),
                Value<int> chargesMinor = const Value.absent(),
                Value<int> roundOffMinor = const Value.absent(),
                Value<int> grandTotalMinor = const Value.absent(),
                Value<int> paidAmountMinor = const Value.absent(),
                Value<int> balanceMinor = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> terms = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InvoicesCompanion(
                id: id,
                invoiceNumber: invoiceNumber,
                documentType: documentType,
                customerId: customerId,
                customerName: customerName,
                customerCompany: customerCompany,
                customerMobile: customerMobile,
                customerEmail: customerEmail,
                customerAddress: customerAddress,
                customerCity: customerCity,
                customerState: customerState,
                customerPinCode: customerPinCode,
                customerGstin: customerGstin,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                status: status,
                taxType: taxType,
                discountType: discountType,
                discountValue: discountValue,
                subtotalMinor: subtotalMinor,
                itemDiscountMinor: itemDiscountMinor,
                invoiceDiscountMinor: invoiceDiscountMinor,
                taxableMinor: taxableMinor,
                taxMinor: taxMinor,
                cgstMinor: cgstMinor,
                sgstMinor: sgstMinor,
                igstMinor: igstMinor,
                chargesMinor: chargesMinor,
                roundOffMinor: roundOffMinor,
                grandTotalMinor: grandTotalMinor,
                paidAmountMinor: paidAmountMinor,
                balanceMinor: balanceMinor,
                notes: notes,
                terms: terms,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String invoiceNumber,
                Value<String> documentType = const Value.absent(),
                Value<int?> customerId = const Value.absent(),
                required String customerName,
                Value<String?> customerCompany = const Value.absent(),
                Value<String?> customerMobile = const Value.absent(),
                Value<String?> customerEmail = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<String?> customerCity = const Value.absent(),
                Value<String?> customerState = const Value.absent(),
                Value<String?> customerPinCode = const Value.absent(),
                Value<String?> customerGstin = const Value.absent(),
                required DateTime invoiceDate,
                Value<DateTime?> dueDate = const Value.absent(),
                required String status,
                required String taxType,
                required String discountType,
                Value<int> discountValue = const Value.absent(),
                required int subtotalMinor,
                required int itemDiscountMinor,
                required int invoiceDiscountMinor,
                required int taxableMinor,
                required int taxMinor,
                required int cgstMinor,
                required int sgstMinor,
                required int igstMinor,
                required int chargesMinor,
                required int roundOffMinor,
                required int grandTotalMinor,
                required int paidAmountMinor,
                required int balanceMinor,
                Value<String?> notes = const Value.absent(),
                Value<String?> terms = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InvoicesCompanion.insert(
                id: id,
                invoiceNumber: invoiceNumber,
                documentType: documentType,
                customerId: customerId,
                customerName: customerName,
                customerCompany: customerCompany,
                customerMobile: customerMobile,
                customerEmail: customerEmail,
                customerAddress: customerAddress,
                customerCity: customerCity,
                customerState: customerState,
                customerPinCode: customerPinCode,
                customerGstin: customerGstin,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                status: status,
                taxType: taxType,
                discountType: discountType,
                discountValue: discountValue,
                subtotalMinor: subtotalMinor,
                itemDiscountMinor: itemDiscountMinor,
                invoiceDiscountMinor: invoiceDiscountMinor,
                taxableMinor: taxableMinor,
                taxMinor: taxMinor,
                cgstMinor: cgstMinor,
                sgstMinor: sgstMinor,
                igstMinor: igstMinor,
                chargesMinor: chargesMinor,
                roundOffMinor: roundOffMinor,
                grandTotalMinor: grandTotalMinor,
                paidAmountMinor: paidAmountMinor,
                balanceMinor: balanceMinor,
                notes: notes,
                terms: terms,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({invoiceItemsRefs = false, invoiceChargesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (invoiceItemsRefs) db.invoiceItems,
                    if (invoiceChargesRefs) db.invoiceCharges,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (invoiceItemsRefs)
                        await $_getPrefetchedData<
                          Invoice,
                          $InvoicesTable,
                          InvoiceItem
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
                              ._invoiceItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).invoiceItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.invoiceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (invoiceChargesRefs)
                        await $_getPrefetchedData<
                          Invoice,
                          $InvoicesTable,
                          InvoiceCharge
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
                              ._invoiceChargesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).invoiceChargesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.invoiceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InvoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoicesTable,
      Invoice,
      $$InvoicesTableFilterComposer,
      $$InvoicesTableOrderingComposer,
      $$InvoicesTableAnnotationComposer,
      $$InvoicesTableCreateCompanionBuilder,
      $$InvoicesTableUpdateCompanionBuilder,
      (Invoice, $$InvoicesTableReferences),
      Invoice,
      PrefetchHooks Function({bool invoiceItemsRefs, bool invoiceChargesRefs})
    >;
typedef $$InvoiceItemsTableCreateCompanionBuilder =
    InvoiceItemsCompanion Function({
      Value<int> id,
      required int invoiceId,
      Value<int?> productId,
      required String name,
      Value<String?> description,
      required int quantityScaled,
      required String unit,
      required int rateMinor,
      Value<String?> hsnSac,
      required int taxRateBasisPoints,
      required String discountType,
      Value<int> discountValue,
      required int baseAmountMinor,
      required int discountAmountMinor,
      required int taxableAmountMinor,
      required int taxAmountMinor,
      required int totalMinor,
      required int sortOrder,
    });
typedef $$InvoiceItemsTableUpdateCompanionBuilder =
    InvoiceItemsCompanion Function({
      Value<int> id,
      Value<int> invoiceId,
      Value<int?> productId,
      Value<String> name,
      Value<String?> description,
      Value<int> quantityScaled,
      Value<String> unit,
      Value<int> rateMinor,
      Value<String?> hsnSac,
      Value<int> taxRateBasisPoints,
      Value<String> discountType,
      Value<int> discountValue,
      Value<int> baseAmountMinor,
      Value<int> discountAmountMinor,
      Value<int> taxableAmountMinor,
      Value<int> taxAmountMinor,
      Value<int> totalMinor,
      Value<int> sortOrder,
    });

final class $$InvoiceItemsTableReferences
    extends BaseReferences<_$AppDatabase, $InvoiceItemsTable, InvoiceItem> {
  $$InvoiceItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('invoice_items__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<int>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvoiceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityScaled => $composableBuilder(
    column: $table.quantityScaled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateMinor => $composableBuilder(
    column: $table.rateMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hsnSac => $composableBuilder(
    column: $table.hsnSac,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseAmountMinor => $composableBuilder(
    column: $table.baseAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountAmountMinor => $composableBuilder(
    column: $table.discountAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxableAmountMinor => $composableBuilder(
    column: $table.taxableAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxAmountMinor => $composableBuilder(
    column: $table.taxAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityScaled => $composableBuilder(
    column: $table.quantityScaled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateMinor => $composableBuilder(
    column: $table.rateMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hsnSac => $composableBuilder(
    column: $table.hsnSac,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseAmountMinor => $composableBuilder(
    column: $table.baseAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountAmountMinor => $composableBuilder(
    column: $table.discountAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxableAmountMinor => $composableBuilder(
    column: $table.taxableAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxAmountMinor => $composableBuilder(
    column: $table.taxAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityScaled => $composableBuilder(
    column: $table.quantityScaled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get rateMinor =>
      $composableBuilder(column: $table.rateMinor, builder: (column) => column);

  GeneratedColumn<String> get hsnSac =>
      $composableBuilder(column: $table.hsnSac, builder: (column) => column);

  GeneratedColumn<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseAmountMinor => $composableBuilder(
    column: $table.baseAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountAmountMinor => $composableBuilder(
    column: $table.discountAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxableAmountMinor => $composableBuilder(
    column: $table.taxableAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxAmountMinor => $composableBuilder(
    column: $table.taxAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceItemsTable,
          InvoiceItem,
          $$InvoiceItemsTableFilterComposer,
          $$InvoiceItemsTableOrderingComposer,
          $$InvoiceItemsTableAnnotationComposer,
          $$InvoiceItemsTableCreateCompanionBuilder,
          $$InvoiceItemsTableUpdateCompanionBuilder,
          (InvoiceItem, $$InvoiceItemsTableReferences),
          InvoiceItem,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$InvoiceItemsTableTableManager(_$AppDatabase db, $InvoiceItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> invoiceId = const Value.absent(),
                Value<int?> productId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> quantityScaled = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> rateMinor = const Value.absent(),
                Value<String?> hsnSac = const Value.absent(),
                Value<int> taxRateBasisPoints = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                Value<int> discountValue = const Value.absent(),
                Value<int> baseAmountMinor = const Value.absent(),
                Value<int> discountAmountMinor = const Value.absent(),
                Value<int> taxableAmountMinor = const Value.absent(),
                Value<int> taxAmountMinor = const Value.absent(),
                Value<int> totalMinor = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => InvoiceItemsCompanion(
                id: id,
                invoiceId: invoiceId,
                productId: productId,
                name: name,
                description: description,
                quantityScaled: quantityScaled,
                unit: unit,
                rateMinor: rateMinor,
                hsnSac: hsnSac,
                taxRateBasisPoints: taxRateBasisPoints,
                discountType: discountType,
                discountValue: discountValue,
                baseAmountMinor: baseAmountMinor,
                discountAmountMinor: discountAmountMinor,
                taxableAmountMinor: taxableAmountMinor,
                taxAmountMinor: taxAmountMinor,
                totalMinor: totalMinor,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int invoiceId,
                Value<int?> productId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required int quantityScaled,
                required String unit,
                required int rateMinor,
                Value<String?> hsnSac = const Value.absent(),
                required int taxRateBasisPoints,
                required String discountType,
                Value<int> discountValue = const Value.absent(),
                required int baseAmountMinor,
                required int discountAmountMinor,
                required int taxableAmountMinor,
                required int taxAmountMinor,
                required int totalMinor,
                required int sortOrder,
              }) => InvoiceItemsCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                productId: productId,
                name: name,
                description: description,
                quantityScaled: quantityScaled,
                unit: unit,
                rateMinor: rateMinor,
                hsnSac: hsnSac,
                taxRateBasisPoints: taxRateBasisPoints,
                discountType: discountType,
                discountValue: discountValue,
                baseAmountMinor: baseAmountMinor,
                discountAmountMinor: discountAmountMinor,
                taxableAmountMinor: taxableAmountMinor,
                taxAmountMinor: taxAmountMinor,
                totalMinor: totalMinor,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoiceItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.invoiceId,
                                referencedTable: $$InvoiceItemsTableReferences
                                    ._invoiceIdTable(db),
                                referencedColumn: $$InvoiceItemsTableReferences
                                    ._invoiceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvoiceItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceItemsTable,
      InvoiceItem,
      $$InvoiceItemsTableFilterComposer,
      $$InvoiceItemsTableOrderingComposer,
      $$InvoiceItemsTableAnnotationComposer,
      $$InvoiceItemsTableCreateCompanionBuilder,
      $$InvoiceItemsTableUpdateCompanionBuilder,
      (InvoiceItem, $$InvoiceItemsTableReferences),
      InvoiceItem,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$InvoiceChargesTableCreateCompanionBuilder =
    InvoiceChargesCompanion Function({
      Value<int> id,
      required int invoiceId,
      required String title,
      required int amountMinor,
      required int sortOrder,
    });
typedef $$InvoiceChargesTableUpdateCompanionBuilder =
    InvoiceChargesCompanion Function({
      Value<int> id,
      Value<int> invoiceId,
      Value<String> title,
      Value<int> amountMinor,
      Value<int> sortOrder,
    });

final class $$InvoiceChargesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoiceChargesTable, InvoiceCharge> {
  $$InvoiceChargesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('invoice_charges__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<int>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvoiceChargesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceChargesTable> {
  $$InvoiceChargesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceChargesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceChargesTable> {
  $$InvoiceChargesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceChargesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceChargesTable> {
  $$InvoiceChargesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceChargesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceChargesTable,
          InvoiceCharge,
          $$InvoiceChargesTableFilterComposer,
          $$InvoiceChargesTableOrderingComposer,
          $$InvoiceChargesTableAnnotationComposer,
          $$InvoiceChargesTableCreateCompanionBuilder,
          $$InvoiceChargesTableUpdateCompanionBuilder,
          (InvoiceCharge, $$InvoiceChargesTableReferences),
          InvoiceCharge,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$InvoiceChargesTableTableManager(
    _$AppDatabase db,
    $InvoiceChargesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceChargesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceChargesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceChargesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> invoiceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => InvoiceChargesCompanion(
                id: id,
                invoiceId: invoiceId,
                title: title,
                amountMinor: amountMinor,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int invoiceId,
                required String title,
                required int amountMinor,
                required int sortOrder,
              }) => InvoiceChargesCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                title: title,
                amountMinor: amountMinor,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoiceChargesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.invoiceId,
                                referencedTable: $$InvoiceChargesTableReferences
                                    ._invoiceIdTable(db),
                                referencedColumn:
                                    $$InvoiceChargesTableReferences
                                        ._invoiceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvoiceChargesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceChargesTable,
      InvoiceCharge,
      $$InvoiceChargesTableFilterComposer,
      $$InvoiceChargesTableOrderingComposer,
      $$InvoiceChargesTableAnnotationComposer,
      $$InvoiceChargesTableCreateCompanionBuilder,
      $$InvoiceChargesTableUpdateCompanionBuilder,
      (InvoiceCharge, $$InvoiceChargesTableReferences),
      InvoiceCharge,
      PrefetchHooks Function({bool invoiceId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DatabaseMetadataTableTableManager get databaseMetadata =>
      $$DatabaseMetadataTableTableManager(_db, _db.databaseMetadata);
  $$BusinessProfilesTableTableManager get businessProfiles =>
      $$BusinessProfilesTableTableManager(_db, _db.businessProfiles);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$ProductServicesTableTableManager get productServices =>
      $$ProductServicesTableTableManager(_db, _db.productServices);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db, _db.invoiceItems);
  $$InvoiceChargesTableTableManager get invoiceCharges =>
      $$InvoiceChargesTableTableManager(_db, _db.invoiceCharges);
}
