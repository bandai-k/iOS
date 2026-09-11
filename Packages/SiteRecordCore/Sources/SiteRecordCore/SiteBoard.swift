import Foundation

/// 写真に写し込む看板（electronic blackboard）の内容。
///
/// 現場では 1 日に何十枚も撮るので、入力は 1 度だけ済ませて使い回す前提。
/// 空欄の項目は看板に行ごと表示しない。
public struct SiteBoard: Codable, Equatable, Sendable {
    public var projectName: String
    public var workType: String
    public var location: String
    public var contractor: String
    public var note: String

    public init(
        projectName: String = "",
        workType: String = "",
        location: String = "",
        contractor: String = "",
        note: String = ""
    ) {
        self.projectName = projectName
        self.workType = workType
        self.location = location
        self.contractor = contractor
        self.note = note
    }

    public static let empty = SiteBoard()

    /// 看板に表示する行。値が空の項目は落とす。
    public var rows: [BoardRow] {
        [
            BoardRow(label: "工事名", value: projectName),
            BoardRow(label: "工種", value: workType),
            BoardRow(label: "施工箇所", value: location),
            BoardRow(label: "施工者", value: contractor),
            BoardRow(label: "備考", value: note)
        ]
        .filter { !$0.value.isEmpty }
    }

    /// 1 項目も入力されていない状態。
    public var isEmpty: Bool { rows.isEmpty }

    /// 前後の空白を落とした写し。保存前に通す。
    public func trimmed() -> SiteBoard {
        SiteBoard(
            projectName: Self.trim(projectName),
            workType: Self.trim(workType),
            location: Self.trim(location),
            contractor: Self.trim(contractor),
            note: Self.trim(note)
        )
    }

    private static func trim(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// 看板の 1 行分（項目名と値）。
public struct BoardRow: Identifiable, Equatable, Sendable {
    public var id: String { label }
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}
