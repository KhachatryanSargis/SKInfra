import Testing
import SwiftUI
@testable import SKNavigation

@Suite("PresentationStyle")
struct PresentationStyleTests {

    // MARK: - SheetConfiguration Defaults

    @Test("Default configuration has large detent and automatic drag indicator")
    func defaultConfiguration() {
        let config = SheetConfiguration.default

        #expect(config.detents == [.large])
        #expect(config.dragIndicatorVisibility == .automatic)
        #expect(config.isDismissDisabled == false)
        #expect(config.cornerRadius == nil)
    }

    @Test("Bottom sheet configuration has medium + large detents with visible indicator")
    func bottomSheetConfiguration() {
        let config = SheetConfiguration.bottomSheet

        #expect(config.detents == [.medium, .large])
        #expect(config.dragIndicatorVisibility == .visible)
        #expect(config.isDismissDisabled == false)
        #expect(config.cornerRadius == nil)
    }

    // MARK: - SheetConfiguration Custom Init

    @Test("Custom configuration stores all properties")
    func customConfiguration() {
        let config = SheetConfiguration(
            detents: [.medium],
            dragIndicatorVisibility: .hidden,
            isDismissDisabled: true,
            cornerRadius: 16
        )

        #expect(config.detents == [.medium])
        #expect(config.dragIndicatorVisibility == .hidden)
        #expect(config.isDismissDisabled == true)
        #expect(config.cornerRadius == 16)
    }

    @Test("Partial defaults fill in remaining properties")
    func partialDefaults() {
        let config = SheetConfiguration(detents: [.medium, .large])

        #expect(config.detents == [.medium, .large])
        #expect(config.dragIndicatorVisibility == .automatic)
        #expect(config.isDismissDisabled == false)
        #expect(config.cornerRadius == nil)
    }

    // MARK: - SheetConfiguration Equatable

    @Test("Equal configurations are equal")
    func configurationEquality() {
        let a = SheetConfiguration(detents: [.large], isDismissDisabled: true)
        let b = SheetConfiguration(detents: [.large], isDismissDisabled: true)
        #expect(a == b)
    }

    @Test("Different configurations are not equal")
    func configurationInequality() {
        #expect(SheetConfiguration.default != SheetConfiguration.bottomSheet)
    }

    // MARK: - PresentationStyle Equatable

    @Test("Push styles are equal")
    func pushEquality() {
        #expect(PresentationStyle.push == .push)
    }

    @Test("FullScreenCover styles are equal")
    func fullScreenCoverEquality() {
        #expect(PresentationStyle.fullScreenCover == .fullScreenCover)
    }

    @Test("Sheet styles with same config are equal")
    func sheetEqualityWithSameConfig() {
        #expect(PresentationStyle.sheet(.bottomSheet) == PresentationStyle.sheet(.bottomSheet))
    }

    @Test("Sheet styles with different config are not equal")
    func sheetInequalityWithDifferentConfig() {
        #expect(PresentationStyle.sheet(.default) != PresentationStyle.sheet(.bottomSheet))
    }

    @Test("Different presentation styles are not equal")
    func differentStylesAreNotEqual() {
        #expect(PresentationStyle.push != .fullScreenCover)
        #expect(PresentationStyle.push != .sheet())
        #expect(PresentationStyle.fullScreenCover != .sheet())
    }
}
