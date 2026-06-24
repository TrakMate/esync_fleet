class CanDataDownloadModel {
  final Map<String, dynamic> data;

  CanDataDownloadModel({required this.data});

  factory CanDataDownloadModel.fromList(
    List<String> headers,
    List<String> values,
  ) {
    Map<String, dynamic> map = {};

    for (int i = 0; i < headers.length; i++) {
      String key = headers[i].trim();
      String value = i < values.length ? values[i].trim() : "";

      map[key] = value;
    }

    return CanDataDownloadModel(data: map);
  }
}
