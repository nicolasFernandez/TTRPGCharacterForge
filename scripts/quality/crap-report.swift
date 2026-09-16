import Foundation

private let usage = """
Usage:
  crap-report.swift <swift-complexity.json> <xccov.json> [threshold]
  crap-report.swift self-test
"""

private enum ReportError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let value): value
        }
    }
}

private struct ComplexityFunction: Decodable {
    struct Location: Decodable {
        let line: Int
    }

    let name: String
    let signature: String
    let cyclomaticComplexity: Int
    let location: Location
}

private struct ComplexityFile: Decodable {
    let filePath: String
    let functions: [ComplexityFunction]
}

private struct ComplexityReport: Decodable {
    let files: [ComplexityFile]
}

private struct CoverageFunction: Decodable {
    let name: String
    let lineCoverage: Double
    let lineNumber: Int
}

private struct CoverageFile: Decodable {
    let path: String
    let functions: [CoverageFunction]
}

private struct CoverageTarget: Decodable {
    let files: [CoverageFile]
}

private struct CoverageReport: Decodable {
    let targets: [CoverageTarget]
}

private struct Result {
    let file: String
    let function: String
    let line: Int
    let complexity: Int
    let coverage: Double
    let crap: Double
}

private func normalizedPath(_ path: String) -> String {
    let cleaned = path.replacingOccurrences(of: "\\", with: "/")
    if cleaned.hasPrefix("/") {
        return URL(fileURLWithPath: cleaned).standardizedFileURL.path
    }
    return cleaned.split(separator: "/").filter { $0 != "." }.joined(separator: "/")
}

private func pathsMatch(complexityPath: String, coveragePath: String) -> Bool {
    let complexity = normalizedPath(complexityPath)
    let coverage = normalizedPath(coveragePath)
    return coverage == complexity || coverage.hasSuffix("/" + complexity.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
}

private func calculate(
    complexity: ComplexityReport,
    coverage: CoverageReport
) throws -> [Result] {
    let coverageFiles = coverage.targets.flatMap(\.files)
    var output: [Result] = []

    for file in complexity.files {
        let matchingFiles = coverageFiles.filter {
            pathsMatch(complexityPath: file.filePath, coveragePath: $0.path)
        }

        guard matchingFiles.count == 1, let coverageFile = matchingFiles.first else {
            throw ReportError.message(
                "Expected exactly one coverage file for \(file.filePath), found \(matchingFiles.count)."
            )
        }

        for function in file.functions {
            let candidates = coverageFile.functions.filter { $0.lineNumber == function.location.line }
            guard candidates.count == 1, let coveredFunction = candidates.first else {
                throw ReportError.message(
                    "Expected exactly one coverage function at \(file.filePath):\(function.location.line) " +
                    "for \(function.signature), found \(candidates.count)."
                )
            }

            let boundedCoverage = min(max(coveredFunction.lineCoverage, 0), 1)
            let complexityValue = Double(function.cyclomaticComplexity)
            let uncovered = 1 - boundedCoverage
            let crap = complexityValue * complexityValue * pow(uncovered, 3) + complexityValue

            output.append(
                Result(
                    file: file.filePath,
                    function: function.name,
                    line: function.location.line,
                    complexity: function.cyclomaticComplexity,
                    coverage: boundedCoverage,
                    crap: crap
                )
            )
        }
    }

    return output.sorted {
        if $0.crap == $1.crap {
            return ($0.file, $0.line) < ($1.file, $1.line)
        }
        return $0.crap > $1.crap
    }
}

private func render(_ results: [Result], threshold: Double) {
    print("# CRAP report")
    print("")
    print("Threshold: \(String(format: "%.2f", threshold))")
    print("")
    print("| Status | File:line | Function | Complexity | Coverage | CRAP |")
    print("| --- | --- | --- | ---: | ---: | ---: |")

    for result in results {
        let status = result.crap <= threshold ? "PASS" : "FAIL"
        let coverage = String(format: "%.2f%%", result.coverage * 100)
        let score = String(format: "%.2f", result.crap)
        print("| \(status) | \(result.file):\(result.line) | `\(result.function)` | \(result.complexity) | \(coverage) | \(score) |")
    }

    let failures = results.filter { $0.crap > threshold }.count
    print("")
    print("Measured methods: \(results.count); failures: \(failures).")
}

private func decode<T: Decodable>(_ type: T.Type, from path: String) throws -> T {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return try JSONDecoder().decode(type, from: data)
}

private func selfTest() throws {
    let complexityJSON = """
    {"files":[{"filePath":"Sources/Example.swift","functions":[
      {"name":"simple()","signature":"func simple()","cyclomaticComplexity":1,"cognitiveComplexity":0,"location":{"line":10,"column":1}},
      {"name":"branching()","signature":"func branching()","cyclomaticComplexity":4,"cognitiveComplexity":4,"location":{"line":20,"column":1}}
    ],"summary":{"totalFunctions":2,"averageCyclomaticComplexity":2.5,"averageCognitiveComplexity":2,"maxCyclomaticComplexity":4,"maxCognitiveComplexity":4,"totalCyclomaticComplexity":5,"totalCognitiveComplexity":4}}]}
    """
    let coverageJSON = """
    {"targets":[{"files":[{"path":"/tmp/project/Sources/Example.swift","functions":[
      {"name":"Example.simple()","lineCoverage":0,"lineNumber":10},
      {"name":"Example.branching()","lineCoverage":1,"lineNumber":20}
    ]}]}]}
    """

    let decoder = JSONDecoder()
    let complexity = try decoder.decode(ComplexityReport.self, from: Data(complexityJSON.utf8))
    let coverage = try decoder.decode(CoverageReport.self, from: Data(coverageJSON.utf8))
    let results = try calculate(complexity: complexity, coverage: coverage)

    guard results.count == 2,
          results.contains(where: { $0.function == "simple()" && abs($0.crap - 2) < 0.0001 }),
          results.contains(where: { $0.function == "branching()" && abs($0.crap - 4) < 0.0001 }) else {
        throw ReportError.message("Self-test produced unexpected CRAP values.")
    }

    print("crap-report self-test passed")
}

do {
    let arguments = Array(CommandLine.arguments.dropFirst())

    if arguments == ["self-test"] {
        try selfTest()
        exit(0)
    }

    guard arguments.count == 2 || arguments.count == 3 else {
        throw ReportError.message(usage)
    }

    let threshold = arguments.count == 3 ? Double(arguments[2]) : 4
    guard let threshold, threshold >= 0 else {
        throw ReportError.message("Threshold must be a non-negative number.")
    }

    let complexity = try decode(ComplexityReport.self, from: arguments[0])
    let coverage = try decode(CoverageReport.self, from: arguments[1])
    let results = try calculate(complexity: complexity, coverage: coverage)
    render(results, threshold: threshold)

    if results.contains(where: { $0.crap > threshold }) {
        exit(1)
    }
} catch {
    fputs("crap-report: \(error)\n", stderr)
    exit(2)
}
