part of 'chat_cubit.dart';

class ChatState extends Equatable {
  const ChatState({
    this.connection = ChatConnectionStatus.connecting,
    this.messages = const [],
    this.isPeerTyping = false,
    this.isPeerOnline = false,
    this.historyLoaded = false,
    this.errorMessage,
  });

  final ChatConnectionStatus connection;
  final List<ChatMessage> messages;
  final bool isPeerTyping;
  final bool isPeerOnline;
  final bool historyLoaded;
  final String? errorMessage;

  bool get isConnected => connection == ChatConnectionStatus.connected;
  bool get isConnecting => connection == ChatConnectionStatus.connecting;
  bool get hasFatalError =>
      connection == ChatConnectionStatus.error && !historyLoaded;

  ChatState copyWith({
    ChatConnectionStatus? connection,
    List<ChatMessage>? messages,
    bool? isPeerTyping,
    bool? isPeerOnline,
    bool? historyLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      connection: connection ?? this.connection,
      messages: messages ?? this.messages,
      isPeerTyping: isPeerTyping ?? this.isPeerTyping,
      isPeerOnline: isPeerOnline ?? this.isPeerOnline,
      historyLoaded: historyLoaded ?? this.historyLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        connection,
        messages,
        isPeerTyping,
        isPeerOnline,
        historyLoaded,
        errorMessage,
      ];
}
