/// Resposta paginada do DRF (PageNumberPagination):
/// {"count": 12, "next": "...?page=2", "previous": null, "results": [...]}
class Paginated<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const Paginated({required this.count, required this.results, this.next, this.previous});

  bool get temProxima => next != null;

  factory Paginated.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) item) {
    final lista = (json['results'] as List? ?? const [])
        .map((e) => item(e as Map<String, dynamic>))
        .toList();
    return Paginated(
      count: json['count'] as int? ?? lista.length,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: lista,
    );
  }
}
