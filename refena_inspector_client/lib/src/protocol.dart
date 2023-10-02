enum InspectorClientMessageType {
  /// The client sends to the server general metadata about the client
  /// like the map of actions.
  /// The server will use this information to build the inspector.
  hello,
}

enum InspectorServerMessageType {
  /// The server sends to the client an action.
  /// The client will execute the action.
  action,
}
