import Foundation
import Combine
import Starscream

public enum WebSocketEvent {
    case connected
    case disconnected(Error?)
    case message(String)
    case data(Data)
    case pong
}

private final class WebSocketDelegateProxy<Client: WebSocketClient>: DelegateProxy, WebSocketDelegate, WebSocketPongDelegate {

    fileprivate let subject = PassthroughSubject<WebSocketEvent, Never>()

    fileprivate required init() {}

    static func proxy(for client: Client) -> Self {
        let proxy = delegateProxy(for: client)
        client.delegate = proxy
        client.pongDelegate = proxy
        return proxy
    }

    func websocketDidConnect(socket: WebSocketClient) {
        subject.send(.connected)
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        subject.send(.disconnected(error))
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        subject.send(.message(text))
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        subject.send(.data(data))
    }

    func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        subject.send(.pong)
    }

    deinit {
        subject.send(completion: .finished)
    }
}

extension CombineWrapper where Base: WebSocketClient {

    public var response: some Publisher<WebSocketEvent, Never> {
        WebSocketDelegateProxy.proxy(for: self.base).subject
    }

    public var text: some Publisher<String, Never> {
        response
            .filter {
                switch $0 {
                case .message:
                    return true
                default:
                    return false
                }
            }
            .map {
                switch $0 {
                case .message(let message):
                    return message
                default:
                    return ""
                }
            }
    }

    public var connected: some Publisher<Bool, Never> {
        response
            .filter {
                switch $0 {
                case .connected, .disconnected:
                    return true
                default:
                    return false
                }
            }
            .map {
                switch $0 {
                case .connected:
                    return true
                default:
                    return false
                }
            }
    }

    public func write(data: Data) -> some Publisher<Void, Never> {
        return Future { obs in
            self.base.write(data: data) {
                obs(.success(()))
            }
        }
    }

    public func write(ping: Data) -> some Publisher<Void, Never> {
        return Future { obs in
            self.base.write(ping: ping) {
                obs(.success(()))
            }
        }
    }

    public func write(string: String) -> some Publisher<Void, Never> {
        return Future { obs in
            self.base.write(string: string) {
                obs(.success(()))
            }
        }
    }
}
