class TaughtCommand {
  const TaughtCommand({this.id, required this.phrase, required this.response});

  final int? id;
  final String phrase;
  final String response;

  TaughtCommand copyWith({String? phrase, String? response}) => TaughtCommand(
        id: id,
        phrase: phrase ?? this.phrase,
        response: response ?? this.response,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'phrase': phrase,
        'response': response,
      };

  static TaughtCommand fromMap(Map<String, Object?> m) => TaughtCommand(
        id: m['id'] as int?,
        phrase: m['phrase'] as String,
        response: m['response'] as String,
      );
}
