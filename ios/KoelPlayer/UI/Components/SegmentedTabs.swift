import SwiftUI

/// Koel's segmented control: rounded corners rather than iOS's pill, the selected segment in the cover's color.
struct SegmentedTabs<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    @Environment(\.brandColor) private var brandColor
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    Text(title(option))
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(brandColor)
                                    .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Color(uiColor: .tertiarySystemFill), in: .rect(cornerRadius: 9, style: .continuous))
    }
}
