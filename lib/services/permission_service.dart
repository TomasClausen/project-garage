enum AppPermission { camera, photos }

enum AppPermissionState {
  notRequested,
  granted,
  limited,
  denied,
  permanentlyDenied,
}

abstract interface class PermissionGateway {
  Future<AppPermissionState> request(AppPermission permission);
  Future<void> openSettings();
}

class PermissionService {
  const PermissionService(this.gateway);
  final PermissionGateway gateway;

  Future<AppPermissionState> requestInContext(AppPermission permission) =>
      gateway.request(permission);

  bool canContinue(AppPermissionState state) => true;
  bool shouldOfferSettings(AppPermissionState state) =>
      state == AppPermissionState.permanentlyDenied;
}
