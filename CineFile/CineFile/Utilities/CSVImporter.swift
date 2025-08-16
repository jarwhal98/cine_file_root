import Foundation

struct CSVRowNYT: Decodable {
    let rank: Int
    let title: String
    let year: Int
}

struct CSVRowAFI: Decodable {
    let rank: Int
    let title: String
    let year: Int
}

enum CSVImporterError: Error { case fileNotFound, invalidData }

enum CSVImporter {
    static func loadNYT21(fileName: String, in bundle: Bundle = .main) throws -> [CSVRowNYT] {
        guard let url = bundle.url(forResource: fileName, withExtension: "csv") else { throw CSVImporterError.fileNotFound }
        let data = try Data(contentsOf: url)
        guard let string = String(data: data, encoding: .utf8) else { throw CSVImporterError.invalidData }
        return parseRowsNYT(csv: string)
    }

    static func loadAFI(fileName: String, in bundle: Bundle = .main) throws -> [CSVRowAFI] {
        guard let url = bundle.url(forResource: fileName, withExtension: "csv") else { throw CSVImporterError.fileNotFound }
        let data = try Data(contentsOf: url)
        guard let string = String(data: data, encoding: .utf8) else { throw CSVImporterError.invalidData }
        return parseRowsAFI(csv: string)
    }

    private static func parseRowsNYT(csv: String) -> [CSVRowNYT] {
        var rows: [CSVRowNYT] = []
        let lines = csv.split(whereSeparator: { $0.isNewline })
        guard !lines.isEmpty else { return [] }
        for (idx, line) in lines.enumerated() {
            if idx == 0 { continue } // skip header
            let fields = splitCSV(line: String(line))
            guard fields.count >= 3, let rank = Int(fields[0]), let year = Int(fields[2]) else { continue }
            rows.append(CSVRowNYT(rank: rank, title: fields[1], year: year))
        }
        return rows
    }

    private static func parseRowsAFI(csv: String) -> [CSVRowAFI] {
        var rows: [CSVRowAFI] = []
        let lines = csv.split(whereSeparator: { $0.isNewline })
        guard !lines.isEmpty else { return [] }
        for (idx, line) in lines.enumerated() {
            if idx == 0 { continue } // skip header
            let fields = splitCSV(line: String(line))
            guard fields.count >= 4, let rank = Int(fields[1]), let year = Int(fields[3]) else { continue }
            rows.append(CSVRowAFI(rank: rank, title: fields[2], year: year))
        }
        return rows
    }

    // Very small CSV splitter handling quoted fields
    private static func splitCSV(line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()
        while let c = iterator.next() {
            if c == "\"" { inQuotes.toggle(); continue }
            if c == "," && !inQuotes { result.append(current); current = ""; continue }
            current.append(c)
        }
        result.append(current)
        return result.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
