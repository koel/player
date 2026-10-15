import Foundation

struct IndexedSection<Item>: Identifiable {
    let letter: String
    var items: [Item]

    var id: String { letter }
}

/// Groups name-sorted lists by first letter for the list's side index, as Flutter's alphabet scrollbar did.
enum SectionIndex {
    static let minimumItemCount = 100

    static func isShown(itemCount: Int, isSortedByName: Bool) -> Bool {
        isSortedByName && itemCount >= minimumItemCount
    }

    /// "A" to "Z" for names starting with a Latin letter, "#" for anything else.
    static func letter(for name: String) -> String {
        guard let first = name.first, first.isASCII, first.isLetter else { return "#" }
        return first.uppercased()
    }

    /// Keeps the list's order: each letter's section sits where its first item appeared.
    static func sections<Item>(_ items: [Item], name: (Item) -> String) -> [IndexedSection<Item>] {
        var sections: [IndexedSection<Item>] = []
        var positions: [String: Int] = [:]

        for item in items {
            let letter = letter(for: name(item))
            if let position = positions[letter] {
                sections[position].items.append(item)
            } else {
                positions[letter] = sections.count
                sections.append(IndexedSection(letter: letter, items: [item]))
            }
        }

        return sections
    }
}
