import XCTest
@testable import PenguinCSV

final class CSVProcessorTests: XCTestCase {

    func testSimpleMultipleRows() throws {
        let contents = """
        a,b,c,d
        1,2,3,4
        5,6,7,8
        """
        let processor = try CSVProcessor(contents: contents)
        let expected = [
            ["1", "2", "3", "4"],
            ["5", "6", "7", "8"],
        ]
        XCTAssertEqual(try! processor.readAll(), expected)
        let metadata = processor.metadata
        XCTAssert(metadata.hasHeaderRow)
        XCTAssertEqual(",", metadata.separator)
        XCTAssertEqual(4, metadata.columns.count)
        XCTAssertEqual("a", metadata.columns[0].name)
        XCTAssertEqual(.int, metadata.columns[0].type)
        XCTAssertEqual("b", metadata.columns[1].name)
        XCTAssertEqual(.int, metadata.columns[1].type)
        XCTAssertEqual("c", metadata.columns[2].name)
        XCTAssertEqual(.int, metadata.columns[2].type)
        XCTAssertEqual("d", metadata.columns[3].name)
        XCTAssertEqual(.int, metadata.columns[3].type)
    }

    func testQuotedCell() throws {
        let contents = """
        a,b,c,d
        1,2,"three of c's",4
        """
        let processor = try CSVProcessor(contents: contents, bufferSize: 1000)
        let expected = [
            ["1", "2", "three of c's", "4"],
        ]
        XCTAssertEqual(try! processor.readAll(), expected)
        let metadata = processor.metadata
        XCTAssert(metadata.hasHeaderRow)
        XCTAssertEqual(",", metadata.separator)
        XCTAssertEqual(4, metadata.columns.count)
        XCTAssertEqual("a", metadata.columns[0].name)
        XCTAssertEqual(.int, metadata.columns[0].type)
        XCTAssertEqual("b", metadata.columns[1].name)
        XCTAssertEqual(.int, metadata.columns[1].type)
        XCTAssertEqual("c", metadata.columns[2].name)
        XCTAssertEqual(.string, metadata.columns[2].type)
        XCTAssertEqual("d", metadata.columns[3].name)
        XCTAssertEqual(.int, metadata.columns[3].type)
    }

    func testQuotedCellAtEndOfLine() throws {
        let contents = """
        a,b,c
        1,2,"three of c's"
        4,5,6
        """
        let processor = try CSVProcessor(contents: contents)
        let expected = [
            ["1", "2", "three of c's"],
            ["4", "5", "6"],
        ]
        XCTAssertEqual(try! processor.readAll(), expected)
        let metadata = processor.metadata
        XCTAssert(metadata.hasHeaderRow)
        XCTAssertEqual(",", metadata.separator)
        XCTAssertEqual(3, metadata.columns.count)
        XCTAssertEqual("a", metadata.columns[0].name)
        XCTAssertEqual(.int, metadata.columns[0].type)
        XCTAssertEqual("b", metadata.columns[1].name)
        XCTAssertEqual(.int, metadata.columns[1].type)
        XCTAssertEqual("c", metadata.columns[2].name)
        XCTAssertEqual(.string, metadata.columns[2].type)

    }

    func testEmptyAtEnd() throws {
        let contents = """
        a,b,c
        1,2,
        """
        let processor = try CSVProcessor(contents: contents)
        let expected = [
            ["1", "2", ""],
        ]
        XCTAssertEqual(try! processor.readAll(), expected)
        let metadata = processor.metadata
        XCTAssert(metadata.hasHeaderRow)
        XCTAssertEqual(",", metadata.separator)
        XCTAssertEqual(3, metadata.columns.count)
        XCTAssertEqual("a", metadata.columns[0].name)
        XCTAssertEqual(.int, metadata.columns[0].type)
        XCTAssertEqual("b", metadata.columns[1].name)
        XCTAssertEqual(.int, metadata.columns[1].type)
        XCTAssertEqual("c", metadata.columns[2].name)
        XCTAssertEqual(.int, metadata.columns[2].type)

    }

    func testEmptyAtEndAfterQuote() throws {
        let contents = """
        a,b,c
        1,"2",
        """
        let processor = try CSVProcessor(contents: contents)
        let expected = [
            ["1", "2", ""],
        ]
        XCTAssertEqual(try! processor.readAll(), expected)
        let metadata = processor.metadata
        XCTAssert(metadata.hasHeaderRow)
        XCTAssertEqual(",", metadata.separator)
        XCTAssertEqual(3, metadata.columns.count)
        XCTAssertEqual("a", metadata.columns[0].name)
        XCTAssertEqual(.int, metadata.columns[0].type)
        XCTAssertEqual("b", metadata.columns[1].name)
        // XCTAssertEqual(.string, metadata.columns[1].type)  // TODO: fix me?
        XCTAssertEqual("c", metadata.columns[2].name)
        XCTAssertEqual(.int, metadata.columns[2].type)

    }

    func testUnevenLines() throws {
        let contents = """
        a,b,c,d
        1,2,
        5,6,7,8
        """
        let processor = try CSVProcessor(contents: contents)
        let expected = [
            ["1", "2", ""],
            ["5", "6", "7", "8"],
        ]
        XCTAssertEqual(try! processor.readAll(), expected)
        let metadata = processor.metadata
        XCTAssert(metadata.hasHeaderRow)
        XCTAssertEqual(",", metadata.separator)
        XCTAssertEqual(4, metadata.columns.count)
        XCTAssertEqual("a", metadata.columns[0].name)
        XCTAssertEqual(.int, metadata.columns[0].type)
        XCTAssertEqual("b", metadata.columns[1].name)
        XCTAssertEqual(.int, metadata.columns[1].type)
        XCTAssertEqual("c", metadata.columns[2].name)
        XCTAssertEqual(.int, metadata.columns[2].type)
        XCTAssertEqual("d", metadata.columns[3].name)
        XCTAssertEqual(.int, metadata.columns[3].type)

    }

    func testEmbeddedNewline() throws {
        let contents = """
        a,b,c
        1,"two\nwith a newline",3
        """
        let processor = try CSVProcessor(contents: contents)
        let expected = [
            ["1", "two\nwith a newline", "3"],
        ]
        XCTAssertEqual(try! processor.readAll(), expected)
    }

    func testEscaping() throws {
        let contents = """
        a,b,c
        1,"two, aka \\"super cool\\"",3
        """
        let processor = try CSVProcessor(contents: contents)
        let expected = [
            ["1", "two, aka \"super cool\"", "3"],
        ]
        XCTAssertEqual(try! processor.readAll(), expected)
    }

    static var allTests = [
        ("testSimpleMultipleRows", testSimpleMultipleRows),
        ("testQuotedCell", testQuotedCell),
        ("testQuotedCellAtEndOfLine", testQuotedCellAtEndOfLine),
        ("testEmptyAtEnd", testEmptyAtEnd),
        ("testEmptyAtEndAfterQuote", testEmptyAtEndAfterQuote),
        ("testUnevenLines", testUnevenLines),
        ("testEmbeddedNewline", testEmbeddedNewline),
        ("testEscaping", testEscaping),
    ]
}

fileprivate enum TestError: Error {
    case missingMetadata
}