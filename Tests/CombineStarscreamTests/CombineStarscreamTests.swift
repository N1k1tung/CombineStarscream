import XCTest
import Starscream
import Combine
@testable import CombineStarscream

extension WebSocketEvent: Equatable { }

public func ==(lhs: WebSocketEvent, rhs: WebSocketEvent) -> Bool {
    switch (lhs, rhs) {
    case (.connected, .connected):
        return true
    case (.disconnected(let lhsError), .disconnected(let rhsError)):
        return lhsError?.localizedDescription == rhsError?.localizedDescription
    case (.message(let lhsMsg), .message(let rhsMsg)):
        return lhsMsg == rhsMsg
    case (.data(let lhsData), .data(let rhsData)):
        return lhsData == rhsData
    case (.pong, .pong):
        return true
    default:
        return false
    }
}

final class CombineStarscreamTests: XCTestCase {

    private var cancellables: Set<AnyCancellable>!
    private var socket: WebSocket!

    override func setUp() {
        super.setUp()

        socket = WebSocket(url: URL(string: "wss://demo.piesocket.com/v3/channel_123?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV")!)
        cancellables = []
        continueAfterFailure = false
    }

    func testConnection() {
        let expectation = self.expectation(description: #function)

        var events = [Bool]()
        socket.cb.connected
            .sink { _ in
                expectation.fulfill()
            } receiveValue: { [weak self] in
                events.append($0)
                if $0 {
                    self?.socket.disconnect()
                }
                else {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        XCTAssertTrue(socket.delegate != nil, "delegate should be set")

        socket.delegate!.websocketDidConnect(socket: socket)
        socket.delegate!.websocketDidDisconnect(socket: socket, error: nil)

        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0], true)
        XCTAssertEqual(events[1], false)
    }

    func testPongMessage() {
        let expectation = self.expectation(description: #function)

        var events = [WebSocketEvent]()
        socket.cb.response
            .sink { _ in
                expectation.fulfill()
            } receiveValue: {
                events.append($0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        XCTAssertTrue(socket.pongDelegate != nil, "pongDelegate should be set")

        socket.cb.write(ping: Data())
            .sink {}
            .store(in: &cancellables)

        socket.pongDelegate!.websocketDidReceivePong(socket: socket, data: Data())

        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0], WebSocketEvent.pong)
    }

    func testMessageResponse() {
        let expectation = self.expectation(description: #function)

        var events = [WebSocketEvent]()
        let sentMessage = "Hello"

        socket.cb.response
            .sink { _ in
                expectation.fulfill()
            } receiveValue: {
                events.append($0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        XCTAssertTrue(socket.delegate != nil, "delegate should be set")

        socket.cb.write(string: sentMessage)
            .sink {}
            .store(in: &cancellables)

        socket.delegate!.websocketDidReceiveMessage(socket: socket, text: sentMessage)

        wait(for: [expectation], timeout: 10)


        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(WebSocketEvent.message(sentMessage), events[0])
    }
}
