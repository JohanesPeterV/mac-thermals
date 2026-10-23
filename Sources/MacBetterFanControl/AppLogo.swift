import AppKit
import OSLog

@MainActor
enum AppLogo {
    static let image: NSImage = {
        guard let image = Bundle.main.image(forResource: "Logo") else {
            Logger(subsystem: "local.mac-better-fan-control", category: "resources")
                .error("The bundled app logo could not be loaded.")
            return NSImage()
        }

        image.size = NSSize(width: 22, height: 22)
        return image
    }()
}
