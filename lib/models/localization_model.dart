class LocalizationResponse {
  final LocalizationData? result;
  final dynamic errors;

  LocalizationResponse({
    this.result,
    this.errors,
  });

  factory LocalizationResponse.fromJson(Map<String, dynamic> json) {
    return LocalizationResponse(
      result: json['result'] != null 
          ? LocalizationData.fromJson(json['result']) 
          : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.toJson(),
      'errors': errors,
    };
  }
}

class LocalizationData {
  final String? countryPhoneCodes;
  final String? language;
  final String? startTime;
  final String? endTime;
  final Country? country;
  final LocalizationCurrency? currency;
  final int? organizationId;
  final List<int>? weekends;
  final List<String>? holidays;
  final String? timezone;

  LocalizationData({
    this.countryPhoneCodes,
    this.language,
    this.startTime,
    this.endTime,
    this.country,
    this.currency,
    this.organizationId,
    this.weekends,
    this.holidays,
    this.timezone,
  });

  factory LocalizationData.fromJson(Map<String, dynamic> json) {
    return LocalizationData(
      countryPhoneCodes: json['country_phone_codes']?.toString(),
      language: json['language']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      country: json['country'] != null 
          ? Country.fromJson(json['country']) 
          : null,
      currency: json['currency'] != null
          ? LocalizationCurrency.fromJson(json['currency'])
          : null,
      organizationId: json['organization_id'],
      weekends: json['weekends'] != null 
          ? List<int>.from(json['weekends']) 
          : null,
      holidays: json['holidays'] != null 
          ? List<String>.from(json['holidays']) 
          : null,
      timezone: json['timezone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country_phone_codes': countryPhoneCodes,
      'language': language,
      'start_time': startTime,
      'end_time': endTime,
      'country': country?.toJson(),
      'currency': currency?.toJson(),
      'organization_id': organizationId,
      'weekends': weekends,
      'holidays': holidays,
      'timezone': timezone,
    };
  }
}

class LocalizationCurrency {
  final int? id;
  final String? name;
  final int? digitalCode;
  final String? symbolCode;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;

  LocalizationCurrency({
    this.id,
    this.name,
    this.digitalCode,
    this.symbolCode,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory LocalizationCurrency.fromJson(Map<String, dynamic> json) {
    return LocalizationCurrency(
      id: json['id'],
      name: json['name']?.toString(),
      digitalCode: json['digital_code'],
      symbolCode: json['symbol_code']?.toString(),
      organizationId: json['organization_id'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'digital_code': digitalCode,
      'symbol_code': symbolCode,
      'organization_id': organizationId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Country {
  final int? id;
  final String? name;
  final String? countryCode;
  final String? phoneCode;
  final String? createdAt;
  final String? updatedAt;

  Country({
    this.id,
    this.name,
    this.countryCode,
    this.phoneCode,
    this.createdAt,
    this.updatedAt,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'],
      name: json['name']?.toString(),
      countryCode: json['country_code']?.toString(),
      phoneCode: json['phone_code']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_code': countryCode,
      'phone_code': phoneCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
