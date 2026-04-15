import 'shared_models.dart';

class PaymentLinkModel {
  final String paymentLink;
  final String externalRef; // e.g., job ID or funding ID
  final String intentId; // e.g., 'JOB', 'FUNDING'
  final String? provider; // 'stripe', 'paystack', etc.
  final int? amount; // Minor units
  final String? currency;

  PaymentLinkModel({
    required this.paymentLink,
    required this.externalRef,
    required this.intentId,
    this.provider,
    this.amount,
     this.currency,
  });

  factory PaymentLinkModel.fromMap(Map<String, dynamic> map) {
    final data = map['data'] as Map<String, dynamic>? ?? map;
    print('Parsing PaymentLinkModel from map: $data');
    return PaymentLinkModel(
      paymentLink: data['paymentLink'] as String,
      externalRef: data['externalRef'] as String,
      intentId: data['intentId'] as String,
      provider: data['provider'] as String?,
      amount: data['amount'] != null ? int.parse(data['amount'].toString()) : null,
      currency: data['currency'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentLink': paymentLink,
      'externalRef': externalRef,
      'intentId': intentId,
      if (provider != null) 'provider': provider,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
    };
  }
}


class TransactionModel extends BaseModel {
  final int amountMinor;
  final String currency;
  final String status;
  final String? idempotencyKey;
  final String referenceType;
  final String referenceId;
  final List<String> tags;
  final Map<String, dynamic> context;
  final Map<String, dynamic> metadata;
  final String? baseCurrency;
  final int? baseAmountMinor;
  final double? exchangeRate;
  final String? reversalOf;

  const TransactionModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    required this.amountMinor,
    required this.currency,
    required this.status,
    this.idempotencyKey,
    required this.referenceType,
    required this.referenceId,
    this.tags = const [],
    this.context = const {},
    this.metadata = const {},
    this.baseCurrency,
    this.baseAmountMinor,
    this.exchangeRate,
    this.reversalOf,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> rawMap) {
    final map = rawMap['data'] as Map<String, dynamic>? ?? rawMap;
    final createdAt = DateTime.parse(map['createdAt'] as String);

    return TransactionModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: createdAt,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : createdAt,
      amountMinor: int.parse(map['amountMinor'].toString()),
      currency: map['currency'] as String,
      status: map['status'] as String,
      idempotencyKey: map['idempotencyKey'] as String?,
      referenceType: map['referenceType'] as String,
      referenceId: map['referenceId'] as String,
      tags: (map['tags'] as List? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      context: Map<String, dynamic>.from(
        map['context'] as Map? ?? const <String, dynamic>{},
      ),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const <String, dynamic>{},
      ),
      baseCurrency: map['baseCurrency'] as String?,
      baseAmountMinor: map['baseAmountMinor'] != null
          ? int.tryParse(map['baseAmountMinor'].toString())
          : null,
      exchangeRate: map['exchangeRate'] != null
          ? double.tryParse(map['exchangeRate'].toString())
          : null,
      reversalOf: map['reversalOf'] as String?,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'amountMinor': amountMinor,
      'currency': currency,
      'status': status,
      'idempotencyKey': idempotencyKey,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'tags': tags,
      'context': context,
      'metadata': metadata,
      'baseCurrency': baseCurrency,
      'baseAmountMinor': baseAmountMinor,
      'exchangeRate': exchangeRate,
      'reversalOf': reversalOf,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  TransactionModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? amountMinor,
    String? currency,
    String? status,
    String? idempotencyKey,
    String? referenceType,
    String? referenceId,
    List<String>? tags,
    Map<String, dynamic>? context,
    Map<String, dynamic>? metadata,
    String? baseCurrency,
    int? baseAmountMinor,
    double? exchangeRate,
    String? reversalOf,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      tags: tags ?? this.tags,
      context: context ?? this.context,
      metadata: metadata ?? this.metadata,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      baseAmountMinor: baseAmountMinor ?? this.baseAmountMinor,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      reversalOf: reversalOf ?? this.reversalOf,
    );
  }
}

class PaymentIntentModel extends BaseModel {
  final String provider; // 'stripe', 'paystack', etc.
  final String? externalRef;
  final int amount; // Minor units
  final String currency;
  final PaymentStatus status;
  final PaymentMode paymentMode;
  final String referenceType; // e.g., 'JOB', 'FUNDING'
  final String referenceId;
  final String? userId;
  final String? guestSessionId;
  final String? paymentLink; // URL to redirect the user to for checkout


  const PaymentIntentModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    required this.provider,
    this.externalRef,
    required this.amount,
    required this.currency,
    this.status = PaymentStatus.initialized,
    required this.paymentMode,
    required this.referenceType,
    required this.referenceId,
    this.userId,
    this.guestSessionId,
    this.paymentLink,
  });


  factory PaymentIntentModel.fromMap(Map<String, dynamic> rawMap) {
    print('Parsing PaymentIntentModel from map: $rawMap');
    final map = rawMap['data'] as Map<String, dynamic>? ?? rawMap;
    return PaymentIntentModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      provider: map['provider'] as String,
      externalRef: map['externalRef'] as String?,
      amount: int.parse(map['amount'].toString()),
      currency: map['currency'] as String,
      status: map['status'] != null
          ? PaymentStatusExtension.fromString(map['status'] as String)
          : PaymentStatus.initialized,
      paymentMode: PaymentModeExtension.fromString(
        map['paymentMode'] as String,
      ),
      referenceType: map['referenceType'] as String,
      referenceId: map['referenceId'] as String,
      userId: map['userId'] as String?,
      guestSessionId: map['guestSessionId'] as String?,
      paymentLink: map['paymentLink'] as String?,
    );

  }

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) =>
      PaymentIntentModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'provider': provider,
      'externalRef': externalRef,
      'amount': amount,
      'currency': currency,
      'status': status.name.toUpperCase(),
      'paymentMode': paymentMode.name,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'userId': userId,
      'guestSessionId': guestSessionId,
      'paymentLink': paymentLink,
    };

  }

  Map<String, dynamic> toJson() => toMap();

  PaymentIntentModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? provider,
    String? externalRef,
    int? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMode? paymentMode,
    String? referenceType,
    String? referenceId,
    String? userId,
    String? guestSessionId,
  }) {
    return PaymentIntentModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      provider: provider ?? this.provider,
      externalRef: externalRef ?? this.externalRef,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      userId: userId ?? this.userId,
      guestSessionId: guestSessionId ?? this.guestSessionId,
      paymentLink: paymentLink ?? this.paymentLink,
    );

  }
}

class PricingRuleModel extends BaseModel {
  final String ruleName;
  final int baseFare; // Minor units
  final int perKmRate; // Minor units
  final int perMinuteRate; // Minor units
  final double surgeMultiplier;
  final String currency;
  final bool isActive;

  const PricingRuleModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    this.ruleName = 'default',
    this.baseFare = 500,
    this.perKmRate = 120,
    this.perMinuteRate = 20,
    this.surgeMultiplier = 1.0,
    this.currency = 'USD',
    this.isActive = true,
  });

  factory PricingRuleModel.fromMap(Map<String, dynamic> map) {
    return PricingRuleModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      ruleName: map['ruleName'] as String? ?? 'default',
      baseFare: int.parse(map['baseFare']?.toString() ?? '500'),
      perKmRate: int.parse(map['perKmRate']?.toString() ?? '120'),
      perMinuteRate: int.parse(map['perMinuteRate']?.toString() ?? '20'),
      surgeMultiplier:
          double.tryParse(map['surgeMultiplier']?.toString() ?? '1.0') ?? 1.0,
      currency: map['currency'] as String? ?? 'USD',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory PricingRuleModel.fromJson(Map<String, dynamic> json) =>
      PricingRuleModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'ruleName': ruleName,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'perMinuteRate': perMinuteRate,
      'surgeMultiplier': surgeMultiplier,
      'currency': currency,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  PricingRuleModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ruleName,
    int? baseFare,
    int? perKmRate,
    int? perMinuteRate,
    double? surgeMultiplier,
    String? currency,
    bool? isActive,
  }) {
    return PricingRuleModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ruleName: ruleName ?? this.ruleName,
      baseFare: baseFare ?? this.baseFare,
      perKmRate: perKmRate ?? this.perKmRate,
      perMinuteRate: perMinuteRate ?? this.perMinuteRate,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
    );
  }
}
