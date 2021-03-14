//
//  NetworkRequester.swift
//  iOSWebinar2020
//
//  Created by Mario Vanegas on 3/14/21.
//

import Foundation
import Combine

enum NetworkError: LocalizedError {
    case addressUnreachable(URL)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from the server"
        case .addressUnreachable(let url):
            return "Unreachable URL: \(url.absoluteString)"
        }
    }
}

typealias NetworkResponse = (data: Data, httpResponse: HTTPURLResponse?)
typealias DecodedResponse<T: Decodable> = (response: T, httpResponse: HTTPURLResponse?)

protocol NetworkRequesterType {
    func request(from url: URL) -> AnyPublisher<NetworkResponse, Error>
}

extension NetworkRequesterType {
    func request<T: Decodable>(from url: URL, using decoder: JSONDecoder = .init()) -> AnyPublisher<DecodedResponse<T>, Error> {
        request(from: url)
            .tryMap { response in
                let decodedResponse = try decoder.decode(T.self, from: response.data)
                return (response: decodedResponse, httpResponse: response.httpResponse)
            }
            .eraseToAnyPublisher()
    }
}

struct NetworkRequester: NetworkRequesterType {
    func request(from url: URL) -> AnyPublisher<NetworkResponse, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map { (data: $0.data, httpResponse: $0.response as? HTTPURLResponse) }
            .mapError { error -> NetworkError in
                switch error {
                case is URLError:
                    return NetworkError.addressUnreachable(url)
                default:
                    return NetworkError.invalidResponse
                }
            }
            .eraseToAnyPublisher()
    }
}
