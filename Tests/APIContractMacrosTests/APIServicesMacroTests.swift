import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(APIContractMacros)
import APIContractMacros
#endif

final class APIServicesMacroTests: XCTestCase {

    // MARK: - Basic Expansion Tests

    func testAPIServicesGeneratesRegisterAll() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIServices
            struct AppServices {
                let users: UsersService
                let messages: MessagesService
            }
            """,
            expandedSource: """
            struct AppServices {
                let users: UsersService
                let messages: MessagesService

                public func registerAll<R: Routes>(_ routes: R) {
                        UsersService.Group.registerAll(routes.mount(users))
                        MessagesService.Group.registerAll(routes.mount(messages))
                    }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAPIServicesExcludesComputedProperties() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIServices
            struct AppServices {
                let users: UsersService
                var description: String {
                    "AppServices"
                }
            }
            """,
            expandedSource: """
            struct AppServices {
                let users: UsersService
                var description: String {
                    "AppServices"
                }

                public func registerAll<R: Routes>(_ routes: R) {
                        UsersService.Group.registerAll(routes.mount(users))
                    }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Diagnostics Tests

    func testAPIServicesOnNonStruct() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIServices
            class NotAStruct {
                let users: UsersService
            }
            """,
            expandedSource: """
            class NotAStruct {
                let users: UsersService
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@APIServices can only be applied to structs", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAPIServicesOnEnum() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIServices
            enum NotAStruct {
            }
            """,
            expandedSource: """
            enum NotAStruct {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@APIServices can only be applied to structs", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAPIServicesWithoutStoredProperties() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIServices
            struct EmptyServices {
            }
            """,
            expandedSource: """
            struct EmptyServices {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@APIServices requires at least one stored property", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAPIServicesWithOnlyComputedProperties() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIServices
            struct ComputedOnlyServices {
                var description: String {
                    "ComputedOnlyServices"
                }
            }
            """,
            expandedSource: """
            struct ComputedOnlyServices {
                var description: String {
                    "ComputedOnlyServices"
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@APIServices requires at least one stored property", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
