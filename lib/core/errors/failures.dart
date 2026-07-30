/// Typed error surface returned from the data layer.
///
/// Anything the network layer might throw is caught at the repository
/// boundary and mapped to one of these values. Callers can pattern-match on
/// the specific subclass (Dart 3 sealed classes) — the presentation layer
/// never sees a raw `DioException` or `SocketException`.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
