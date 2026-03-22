import Foundation

final class FileWatcher {

    let watchedURL: URL
    var debounceInterval: TimeInterval = 2.0
    var onChange: (() -> Void)?

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let queue = DispatchQueue(label: "com.claudewatch.filewatcher", qos: .utility)
    private var debounceWork: DispatchWorkItem?

    init(url: URL? = nil) {
        self.watchedURL = url ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude", isDirectory: true)
    }

    deinit { stop() }

    func start() {
        guard source == nil else { return }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: watchedURL.path, isDirectory: &isDir),
              isDir.boolValue else {
            print("[FileWatcher] Directory not found: \(watchedURL.path)")
            return
        }

        let fd = open(watchedURL.path, O_EVTONLY)
        guard fd >= 0 else {
            print("[FileWatcher] Failed to open fd — errno \(errno)")
            return
        }
        fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .extend],
            queue: queue
        )

        src.setEventHandler { [weak self] in self?.scheduleDebounce() }
        src.setCancelHandler { [weak self] in
            guard let self else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }

        source = src
        src.resume()
    }

    func stop() {
        debounceWork?.cancel()
        debounceWork = nil
        source?.cancel()
        source = nil
    }

    private func scheduleDebounce() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async { self?.onChange?() }
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }
}
