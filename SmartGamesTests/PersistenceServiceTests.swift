import XCTest
@testable import SmartGames

final class PersistenceServiceTests: XCTestCase {
    var sut: PersistenceService!
    let testKey = "test.key.persistence"

    override func setUp() {
        super.setUp()
        sut = PersistenceService()
        sut.delete(key: testKey)
    }

    override func tearDown() {
        sut.delete(key: testKey)
        super.tearDown()
    }

    func testSaveAndLoad_String() {
        sut.save("hello", key: testKey)
        let result = sut.load(String.self, key: testKey)
        XCTAssertEqual(result, "hello")
    }

    func testSaveAndLoad_Struct() {
        struct TestModel: Codable, Equatable { let value: Int }
        sut.save(TestModel(value: 42), key: testKey)
        let result = sut.load(TestModel.self, key: testKey)
        XCTAssertEqual(result, TestModel(value: 42))
    }

    func testLoad_MissingKey_ReturnsNil() {
        let result = sut.load(String.self, key: "nonexistent.key.xyz")
        XCTAssertNil(result)
    }

    func testDelete_RemovesValue() {
        sut.save("to-delete", key: testKey)
        sut.delete(key: testKey)
        let result = sut.load(String.self, key: testKey)
        XCTAssertNil(result)
    }

    func testExists() {
        XCTAssertFalse(sut.exists(key: testKey))
        sut.save("x", key: testKey)
        XCTAssertTrue(sut.exists(key: testKey))
    }
}
