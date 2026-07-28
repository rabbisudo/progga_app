// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionPlanModelImpl _$$SubscriptionPlanModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SubscriptionPlanModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      billingCycle: json['billingCycle'] as String,
      features:
          (json['features'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$SubscriptionPlanModelImplToJson(
        _$SubscriptionPlanModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'billingCycle': instance.billingCycle,
      'features': instance.features,
    };

_$UserSubscriptionModelImpl _$$UserSubscriptionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserSubscriptionModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String,
      planId: json['planId'] as String,
      startedAt: json['startedAt'] as String,
      expiresAt: json['expiresAt'] as String,
      transactionId: json['transactionId'] as String?,
    );

Map<String, dynamic> _$$UserSubscriptionModelImplToJson(
        _$UserSubscriptionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'status': instance.status,
      'planId': instance.planId,
      'startedAt': instance.startedAt,
      'expiresAt': instance.expiresAt,
      'transactionId': instance.transactionId,
    };
