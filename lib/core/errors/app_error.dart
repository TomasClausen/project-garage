enum AppErrorCode {
  backup,
  restore,
  report,
  image,
  thumbnail,
  storage,
  financeReceipt,
  database,
  validation,
  unknown,
}

class AppError implements Exception {
  const AppError(this.code, this.message, {this.cause});
  final AppErrorCode code;
  final String message;
  final Object? cause;
  @override
  String toString() =>
      'AppError($code): $message${cause == null ? '' : ' [${cause.runtimeType}]'}';
}

class AppFailure {
  const AppFailure(this.code, this.userMessage);
  final AppErrorCode code;
  final String userMessage;

  factory AppFailure.fromError(AppError error) =>
      AppFailure(error.code, switch (error.code) {
        AppErrorCode.backup => 'No se pudo crear el backup.',
        AppErrorCode.restore => 'No se pudo restaurar el backup.',
        AppErrorCode.report => 'No se pudo generar el informe.',
        AppErrorCode.image => 'No se pudo procesar la imagen.',
        AppErrorCode.thumbnail => 'No se pudo generar la miniatura.',
        AppErrorCode.storage => 'No se pudo completar el diagnóstico.',
        AppErrorCode.financeReceipt => 'No se pudo procesar el comprobante.',
        AppErrorCode.database => 'No se pudo acceder a los datos locales.',
        AppErrorCode.validation => error.message,
        AppErrorCode.unknown => 'Ocurrió un error inesperado.',
      });
}

sealed class AppResult<T> {
  const AppResult();
}

class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);
  final T value;
}

class AppFailureResult<T> extends AppResult<T> {
  const AppFailureResult(this.failure, {this.error});
  final AppFailure failure;
  final AppError? error;
}
