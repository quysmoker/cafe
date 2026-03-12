class TableModel {
  final int id;
  final String name;
  final String note;
  final String status; // empty | using

  TableModel({
    required this.id,
    required this.name,
    required this.note,
    required this.status,
  });

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'],
      name: map['name'],
      note: map['note'] ?? '',
      status: map['status'],
    );
  }
}
