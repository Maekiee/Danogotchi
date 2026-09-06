import Foundation

final class ImageFileStorage {
    private let directoryName: String
    private let fileManager: FileManager

    init(directoryName: String, fileManager: FileManager = .default) {
        self.directoryName = directoryName
        self.fileManager = fileManager
    }

    /// 디렉토리를 만든 뒤 파일을 쓰고 저장된 URL을 돌려준다.
    @discardableResult
    func save(_ data: Data, fileName: String) throws -> URL {
        let directory = try makeDirectoryIfNeeded()
        var fileURL = directory.appendingPathComponent(fileName)

        try data.write(to: fileURL, options: .atomic)

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? fileURL.setResourceValues(values)

        return fileURL
    }

    /// 파일이 실제로 존재할 때만 URL을 돌려준다.
    func existingFileURL(fileName: String) -> URL? {
        guard let directory = try? makeDirectoryIfNeeded() else { return nil }
        let fileURL = directory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    /// 지정한 파일만 남기고 전부 지운다.
    func removeAllExcept(fileName: String) {
        guard let directory = try? makeDirectoryIfNeeded(),
              let contents = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
              ) else { return }

        for fileURL in contents where fileURL.lastPathComponent != fileName {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    private func makeDirectoryIfNeeded() throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent(directoryName, isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
