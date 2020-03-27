// Copyright 2020 Itty Bitty Apps Pty Ltd

import Foundation
import Combine
import SwiftyTextTable
import Yams
import AppStoreConnect_Swift_SDK

protocol Renderer {
    associatedtype Input

    func render(_ input: Input)
}

enum Renderers {
    struct CompletionRenderer: Renderer {
        func render(_ input: Subscribers.Completion<Error>) {
            switch input {
                case .finished:
                    break
                case .failure(let error):
                    print("Completed with error: \(error)")
            }
        }
    }

    struct ResultRenderer<T: ResultRenderable>: Renderer {
        typealias Input = T

        let format: OutputFormat?

        func render(_ input: T) {
            switch format ?? .table {
            case .json:
                print(input.renderAsJSON())
            case .yaml:
                print(input.renderAsYAML())
            case .table:
                print(input.renderAsTable())
            }
        }

    }
}

protocol ResultRenderable: Codable {
    /// Renders the receiver as a JSON string.
    func renderAsJSON() -> String

    /// Renders the receiver as a YAML string.
    func renderAsYAML() -> String

    /// Renders the receiver as a SwiftyTable string.
    func renderAsTable() -> String
}

extension ResultRenderable {
    func renderAsJSON() -> String {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = try! jsonEncoder.encode(self)
        return String(data: json, encoding: .utf8)!
    }

    func renderAsYAML() -> String  {
        let yamlEncoder = YAMLEncoder()
        let yaml = try! yamlEncoder.encode(self)
        return yaml
    }
}

/// Provides the necessary info to be able to render a table with SwiftyTable
protocol TableInfoProvider {

    /// Array of columns, with their headers, for display
    static func tableColumns() -> [TextTableColumn]

    /// A single row of table info, in the same order as `Self.tableColumns()`
    var tableRow: [CustomStringConvertible] { get }

}

extension Array: ResultRenderable where Element: TableInfoProvider & Codable {
    func renderAsTable() -> String {
        var table = TextTable(columns: Element.tableColumns())
        table.addRows(values: self.map(\.tableRow))
        return table.render()
    }
}

extension ResultRenderable where Self: TableInfoProvider {
    func renderAsTable() -> String {
        var table = TextTable(columns: Self.tableColumns())
        table.addRow(values: self.tableRow)
        return table.render()
    }
}
