import SwiftUI
import TheMoneyPitCore

struct FilterBarView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack {
            Picker("Category", selection: Binding(
                get: { store.filter.category ?? "" },
                set: { store.filter.category = $0.isEmpty ? nil : $0 }
            )) {
                Text("All Categories").tag("")
                ForEach(store.availableCategories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
            .frame(maxWidth: 220)

            Picker("Status", selection: Binding(
                get: { store.filter.status },
                set: { store.filter.status = $0 }
            )) {
                Text("All Statuses").tag(Status?.none)
                ForEach(Status.allCases, id: \.self) { status in
                    Text(status.rawValue.capitalized).tag(Status?.some(status))
                }
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
            .frame(maxWidth: 200)

            Spacer()
        }
    }
}
