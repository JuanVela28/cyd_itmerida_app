
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceCategory {
  final String id;
  final String name;

  const ServiceCategory({
    required this.id,
    required this.name,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
    );
  }
}

class ServiceOption {
  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final bool requiresDimensions;
  final bool requiresQuantity;

  const ServiceOption({
    required this.id,
    required this.categoryId,
    this.categoryName = '',
    required this.name,
    required this.requiresDimensions,
    required this.requiresQuantity,
  });

  factory ServiceOption.fromJson(
    Map<String, dynamic> json, {
    String categoryName = '',
  }) {
    return ServiceOption(
      id: json['id'].toString(),
      categoryId: json['category_id'].toString(),
      categoryName: categoryName,
      name: json['name'] as String,
      requiresDimensions:
          json['requires_dimensions'] as bool? ?? false,
      requiresQuantity:
          json['requires_quantity'] as bool? ?? false,
    );
  }
}

class ServiceCatalog {
  final List<ServiceCategory> categories;
  final List<ServiceOption> services;

  const ServiceCatalog({
    required this.categories,
    required this.services,
  });
}

class ServiceCatalogService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ServiceCatalog> fetchCatalog() async {
    if (_client.auth.currentUser == null) {
      throw StateError('No authenticated user');
    }

    final categoryRows = await _client
        .from('service_categories')
        .select('id, name')
        .order('name');

    final serviceRows = await _client
        .from('services')
        .select(
          'id, category_id, name, '
          'requires_dimensions, requires_quantity',
        )
        .order('name');

    final categories = categoryRows
        .map((row) => ServiceCategory.fromJson(row))
        .toList();

    final categoryNames = {
      for (final category in categories)
        category.id: category.name,
    };

    final services = serviceRows.map((row) {
      final categoryId = row['category_id'].toString();

      return ServiceOption.fromJson(
        row,
        categoryName: categoryNames[categoryId] ?? '',
      );
    }).toList();

    return ServiceCatalog(
      categories: categories,
      services: services,
    );
  }
}
