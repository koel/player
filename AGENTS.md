# koel/player agent rules

## Share and Reuse UI Components
- Before writing any UI, look for an existing shared component (iOS: `ios/KoelPlayer/UI/Components`, `UI/Screens/*/Support`; Android: `android/.../ui/components`) and use it. Never copy a block from another screen.
- When the same UI appears on two or more screens (a button row, a row layout, a header, an empty/loading/failed state, a sheet, a menu, a toolbar item, a load-more or sort setup), extract it into one shared component and make every screen use it. Do this in the same change, not later.
- Spacing, sizes, fonts and wording for the same purpose come from one shared constant or component, never from per-screen numbers or strings. Two screens showing the same thing must look and behave the same.
- When you touch a screen and find a hand-rolled copy of a shared component, replace it.
- iOS and Android mirror each other: a component shared on one platform has a shared counterpart on the other.
