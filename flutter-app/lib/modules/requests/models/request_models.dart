import 'package:flutter/foundation.dart';

enum RequestStatus {
  draft('Draft'),
  submitted('Submitted'),
  aiAnalysis('AI Analysis'),
  proposalReady('Proposal Ready'),
  awaitingApproval('Awaiting Approval'),
  approved('Approved'),
  designerAssigned('Designer Assigned'),
  inProgress('In Progress'),
  completed('Completed'),
  rejected('Rejected'),
  cancelled('Cancelled');

  final String label;
  const RequestStatus(this.label);

  static RequestStatus fromJson(String value) {
    return values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => draft,
    );
  }
  String toJson() => name;
}

enum RoomType {
  livingRoom('Living Room'),
  kitchen('Kitchen'),
  bedroom('Bedroom'),
  bathroom('Bathroom'),
  diningRoom('Dining Room');

  final String label;
  const RoomType(this.label);

  static RoomType fromJson(String value) {
    return values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => livingRoom,
    );
  }
  String toJson() => name;
}

@immutable
class PaletteColour {
  final String hexValue;
  final int position;

  const PaletteColour({
    required this.hexValue,
    required this.position,
  });

  factory PaletteColour.fromJson(Map<String, dynamic> json) {
    return PaletteColour(
      hexValue: (json['hexValue'] ?? json['hex'] ?? json['Hex']) as String? ?? '',
      position: (json['position'] ?? json['Position']) as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'hexValue': hexValue,
    'position': position,
  };
}

@immutable
class MoodboardImage {
  final String id;
  final String url;
  final int sortOrder;

  const MoodboardImage({
    required this.id,
    required this.url,
    required this.sortOrder,
  });

  factory MoodboardImage.fromJson(Map<String, dynamic> json) {
    return MoodboardImage(
      id: (json['id'] ?? json['Id']) as String? ?? '',
      url: (json['url'] ?? json['Url']) as String? ?? '',
      sortOrder: (json['sortOrder'] ?? json['SortOrder']) as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'sortOrder': sortOrder,
  };
}

DateTime _parseUtcDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  final str = value.toString().trim();
  if (str.isEmpty) return DateTime.now();
  try {
    DateTime dt;
    if (!str.endsWith('Z') && !str.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(str)) {
      dt = DateTime.parse('${str}Z');
    } else {
      dt = DateTime.parse(str);
    }
    return dt.toLocal();
  } catch (_) {
    return DateTime.tryParse(str)?.toLocal() ?? DateTime.now();
  }
}

@immutable
class RequestSummary {
  final String id;
  final String referenceNumber;
  final RoomType roomType;
  final double budget;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailUrl;
  final String? clientDisplayName;
  final bool isFlagged;

  const RequestSummary({
    required this.id,
    required this.referenceNumber,
    required this.roomType,
    required this.budget,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    this.clientDisplayName,
    this.isFlagged = false,
  });

  factory RequestSummary.fromJson(Map<String, dynamic> json) {
    return RequestSummary(
      id: json['id'] as String? ?? '',
      referenceNumber: json['referenceNumber'] as String? ?? '',
      roomType: RoomType.fromJson(json['roomType'] as String? ?? ''),
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      status: RequestStatus.fromJson(json['status'] as String? ?? ''),
      createdAt: _parseUtcDateTime(json['createdAt']),
      updatedAt: _parseUtcDateTime(json['updatedAt']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      clientDisplayName: json['clientDisplayName'] as String?,
      isFlagged: json['isFlagged'] as bool? ?? false,
    );
  }
}

@immutable
class RequestDetail {
  final String id;
  final String referenceNumber;
  final String clientId;
  final String? clientDisplayName;
  final RoomType? roomType;
  final double? budget;
  final double? roomSizeSqM;
  final String? description;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final String? cancelReason;
  final bool isFlagged;
  final String? flagReason;
  final String? roomPhotoUrl;
  final String? paletteMode;
  final String? palettePresetId;
  final String? paletteBaseHex;
  final List<String> requestedStyleTags;
  final List<PaletteColour> palette;
  final List<MoodboardImage> moodboard;
  final List<StatusHistoryEntry> statusHistory;

  const RequestDetail({
    required this.id,
    required this.referenceNumber,
    required this.clientId,
    this.clientDisplayName,
    this.roomType,
    this.budget,
    this.roomSizeSqM,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.cancelReason,
    required this.isFlagged,
    this.flagReason,
    this.roomPhotoUrl,
    this.paletteMode,
    this.palettePresetId,
    this.paletteBaseHex,
    this.requestedStyleTags = const [],
    required this.palette,
    required this.moodboard,
    required this.statusHistory,
  });

  factory RequestDetail.fromJson(Map<String, dynamic> json) {
    return RequestDetail(
      id: json['id'] as String? ?? '',
      referenceNumber: json['referenceNumber'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      clientDisplayName: json['clientDisplayName'] as String?,
      roomType: json['roomType'] != null ? RoomType.fromJson(json['roomType'] as String) : null,
      budget: (json['budget'] as num?)?.toDouble(),
      roomSizeSqM: ((json['roomSizeSqM'] ?? json['roomSizeSqFt'] ?? json['RoomSizeSqFt']) as num?)?.toDouble(),
      description: json['description'] as String?,
      status: RequestStatus.fromJson(json['status'] as String? ?? ''),
      createdAt: _parseUtcDateTime(json['createdAt']),
      updatedAt: _parseUtcDateTime(json['updatedAt']),
      submittedAt: json['submittedAt'] != null ? _parseUtcDateTime(json['submittedAt']) : null,
      cancelReason: json['cancelReason'] as String?,
      isFlagged: json['isFlagged'] as bool? ?? false,
      flagReason: json['flagReason'] as String?,
      roomPhotoUrl: json['roomPhotoUrl'] as String?,
      paletteMode: json['paletteMode'] as String?,
      palettePresetId: json['palettePresetId'] as String?,
      paletteBaseHex: json['paletteBaseHex'] as String?,
      requestedStyleTags: ((json['requestedStyleTags'] ?? json['RequestedStyleTags']) as List?)?.map((e) => e.toString()).toList() ?? [],
      palette: ((json['palettes'] ?? json['palette']) as List?)?.map((e) => PaletteColour.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      moodboard: ((json['moodboards'] ?? json['moodboard']) as List?)?.map((e) => MoodboardImage.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      statusHistory: ((json['statusHistories'] ?? json['statusHistory']) as List?)?.map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

@immutable
class StatusHistoryEntry {
  final RequestStatus status;
  final DateTime timestamp;
  final String note;

  const StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    required this.note,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      status: RequestStatus.fromJson(json['status'] as String? ?? ''),
      timestamp: _parseUtcDateTime(json['timestamp']),
      note: json['note'] as String? ?? '',
    );
  }
}

@immutable
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedResult.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PagedResult(
      items: (json['items'] as List?)?.map((e) => fromJsonT(e)).toList() ?? [],
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

@immutable
class ApiProblem {
  final String title;
  final int status;
  final String? detail;
  final List<ApiFieldError> errors;

  const ApiProblem({
    required this.title,
    required this.status,
    this.detail,
    this.errors = const [],
  });

  factory ApiProblem.fromJson(Map<String, dynamic> json) {
    var errorsList = <ApiFieldError>[];
    if (json['errors'] != null) {
      if (json['errors'] is Map) {
        final errMap = json['errors'] as Map<String, dynamic>;
        errMap.forEach((key, value) {
          if (value is List) {
            for (var msg in value) {
              errorsList.add(ApiFieldError(field: key, message: msg.toString()));
            }
          }
        });
      } else if (json['errors'] is List) {
        errorsList = (json['errors'] as List).map((e) => ApiFieldError.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    
    final msg = json['title'] as String? ?? json['message'] as String? ?? json['error'] as String? ?? 'An error occurred';
    final det = json['detail'] as String? ?? json['message'] as String?;
    return ApiProblem(
      title: msg,
      status: json['status'] as int? ?? 400,
      detail: det,
      errors: errorsList,
    );
  }

  @override
  String toString() {
    if (errors.isNotEmpty) {
      return errors.map((e) => e.message).join('\n');
    }
    return detail ?? title;
  }
}

@immutable
class ApiFieldError {
  final String field;
  final String message;
  final String? code;

  const ApiFieldError({
    required this.field,
    required this.message,
    this.code,
  });

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
      code: json['code'] as String?,
    );
  }
}

enum PaletteMode {
  preset('Preset'),
  generated('Generated');

  final String label;
  const PaletteMode(this.label);

  static PaletteMode? fromJson(String? value) {
    if (value == null) return null;
    return values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => preset,
    );
  }
  String toJson() => label;
}

@immutable
class PalettePreset {
  final String id;
  final String name;
  final String mood;
  final List<PaletteColour> colours;

  const PalettePreset({
    required this.id,
    required this.name,
    required this.mood,
    required this.colours,
  });

  factory PalettePreset.fromJson(Map<String, dynamic> json) {
    final rawColours = json['colours'] ?? json['Colours'];
    final List<PaletteColour> coloursList = [];
    if (rawColours is List) {
      for (var i = 0; i < rawColours.length; i++) {
        final item = rawColours[i];
        if (item is String) {
          coloursList.add(PaletteColour(hexValue: item, position: i));
        } else if (item is Map<String, dynamic>) {
          coloursList.add(PaletteColour.fromJson(item));
        }
      }
    }
    return PalettePreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      colours: coloursList,
    );
  }
}

@immutable
class PaletteSelection {
  final PaletteMode mode;
  final String? presetId;
  final String? baseColour;

  const PaletteSelection({
    required this.mode,
    this.presetId,
    this.baseColour,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'mode': mode.toJson(),
    };
    if (presetId != null) data['presetId'] = presetId;
    if (baseColour != null) data['baseColour'] = baseColour;
    return data;
  }
}
