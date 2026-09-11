import SiteRecordCore
import SwiftUI

/// 看板の内容を編集するシート。入力は基本 1 度きりなので項目を絞っている。
struct BoardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: SiteBoard

    private let onSave: (SiteBoard) -> Void

    init(board: SiteBoard, onSave: @escaping (SiteBoard) -> Void) {
        _draft = State(initialValue: board)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("看板の内容") {
                    LabeledContent("工事名") {
                        TextField("〇〇橋下部工事", text: $draft.projectName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("工種") {
                        TextField("配筋検査", text: $draft.workType)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("施工箇所") {
                        TextField("A1 橋台", text: $draft.location)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("施工者") {
                        TextField("〇〇建設", text: $draft.contractor)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("備考") {
                        TextField("任意", text: $draft.note)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("プレビュー") {
                    ZStack {
                        Color.gray.opacity(0.5)
                        BoardCard(board: draft.trimmed(), timestamp: "2026/09/11 09:41:07")
                            .frame(width: BoardCard.baseWidth)
                            .padding(.vertical, 12)
                    }
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    Button("内容をすべて消す", role: .destructive) {
                        draft = .empty
                    }
                    .disabled(draft.trimmed().isEmpty)
                }
            }
            .navigationTitle("看板の設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(draft.trimmed())
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    BoardEditorView(board: SiteBoard(projectName: "〇〇橋下部工事", workType: "配筋検査")) { _ in }
}
