import SwiftUI

/// Central navigation router. Add cases here as new screens are added.
@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
