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

struct CSVRowTSPDT: Decodable {
    let rank: Int
    let title: String
    let director: String
    let year: Int
    let minutes: Int
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

    static func loadTSPDT(fileName: String, in bundle: Bundle = .main) throws -> [CSVRowTSPDT] {
        guard let url = bundle.url(forResource: fileName, withExtension: "csv") else { throw CSVImporterError.fileNotFound }
        let data = try Data(contentsOf: url)
        guard let string = String(data: data, encoding: .utf8) else { throw CSVImporterError.invalidData }
        return parseRowsTSPDT(csv: string)
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

    private static func parseRowsTSPDT(csv: String) -> [CSVRowTSPDT] {
        var rows: [CSVRowTSPDT] = []
        let lines = csv.split(whereSeparator: { $0.isNewline })
        guard !lines.isEmpty else { return [] }

        // Determine column indexes from header to support variants like:
        // - Pos,2024,Title,Director,Year,Country,Mins
        // - Pos,Year,Title,Director,2024,Country,Mins (Sundance-like)
        let header = String(lines[0])
        let headerFields = splitCSV(line: header)
        func index(of name: String, fallback: Int) -> Int {
            if let idx = headerFields.firstIndex(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
                return idx
            }
            return fallback
        }

        let posIdx = index(of: "Pos", fallback: 0)
        let titleIdx = index(of: "Title", fallback: 2)
        let directorIdx = index(of: "Director", fallback: 3)
        let yearIdx = index(of: "Year", fallback: 4)
        let minsIdx = index(of: "Mins", fallback: 6)

        for (idx, line) in lines.enumerated() {
            if idx == 0 { continue }
            let fields = splitCSV(line: String(line))
            // Ensure we have enough columns
            guard fields.count > max(posIdx, titleIdx, directorIdx, yearIdx, minsIdx) else { continue }
            guard let rank = Int(fields[posIdx]), let year = Int(fields[yearIdx]) else { continue }
            let title = fields[titleIdx]
            let director = fields[directorIdx]
            let minutes = Int(fields[minsIdx]) ?? 0
            rows.append(CSVRowTSPDT(rank: rank, title: title, director: director, year: year, minutes: minutes))
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
