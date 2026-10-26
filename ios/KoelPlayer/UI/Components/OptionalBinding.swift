extension Optional {
    /// Drives a sheet, alert or dialog from an optional item: dismissing it sets the item to nil.
    var isPresent: Bool {
        get { self != nil }
        set { if !newValue { self = nil } }
    }
}
