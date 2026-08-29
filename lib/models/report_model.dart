class ReportModel {
  final int? id;
  final String userId;

  final String title;
  final String? hospital;
  final String type;
  final String? description;

  /// First / primary file.
  final String? filePath;

  /// Every file belonging to this report.
  ///
  /// Example:
  /// image report:
  ///   [image.jpg]
  ///
  /// multi-page scan:
  ///   [page1.jpg, page2.jpg, page3.jpg]
  ///
  /// pdf:
  ///   [report.pdf]
  final List<String> filePaths;

  final String? fileType;

  final String reportDate;
  final String createdAt;

  const ReportModel({
    this.id,
    required this.userId,
    required this.title,
    this.hospital,
    required this.type,
    this.description,
    this.filePath,
    this.filePaths = const [],
    this.fileType,
    required this.reportDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final paths = filePaths.isNotEmpty
        ? filePaths
        : (filePath != null && filePath!.isNotEmpty
        ? [filePath!]
        : <String>[]);

    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'hospital': hospital,
      'type': type,
      'description': description,
      'file_path': paths.isNotEmpty ? paths.first : null,
      'file_paths': paths.join('|'),
      'file_type': fileType,
      'report_date': reportDate,
      'created_at': createdAt,
    };
  }

  factory ReportModel.fromMap(
      Map<String, dynamic> map,
      ) {
    final rawPaths =
        map['file_paths']?.toString() ?? '';

    final paths = rawPaths.isEmpty
        ? <String>[]
        : rawPaths
        .split('|')
        .where(
          (path) => path.trim().isNotEmpty,
    )
        .toList();

    final singlePath =
    map['file_path']?.toString();

    if (paths.isEmpty &&
        singlePath != null &&
        singlePath.isNotEmpty) {
      paths.add(singlePath);
    }

    return ReportModel(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(
        map['id']?.toString() ?? '',
      ),

      userId:
      map['user_id']?.toString() ?? '',

      title:
      map['title']?.toString() ??
          'Medical Report',

      hospital:
      map['hospital']?.toString(),

      type:
      map['type']?.toString() ??
          'Other',

      description:
      map['description']?.toString(),

      filePath:
      singlePath != null &&
          singlePath.isNotEmpty
          ? singlePath
          : paths.isNotEmpty
          ? paths.first
          : null,

      filePaths: paths,

      fileType:
      map['file_type']?.toString(),

      reportDate:
      map['report_date']?.toString() ?? '',

      createdAt:
      map['created_at']?.toString() ?? '',
    );
  }
}