//
//  CombineTests.swift
//  Alamofire
//
//  Created by Jon Shier on 6/9/19.
//  Copyright © 2019 Alamofire. All rights reserved.
//

import Alamofire
import XCTest

#if canImport(Combine)

import Combine

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
final class CombineTests: BaseTestCase {
    func testThatResponsesCanBeManuallyWrappedByFuture() {
        // Given
        let urlRequest = URLRequest.makeHTTPBinRequest()
        let expect = expectation(description: "combine Future should complete")
        var response: DataResponse<HTTPBinResponse>?

        // When
        let request = AF.request(urlRequest)
        let future = Publishers.Future<DataResponse<HTTPBinResponse>, Never> { completion in
            request.responseDecodable { (networkResponse: DataResponse<HTTPBinResponse>) in
                completion(.success(networkResponse))
            }
        }

        _ = future.sink {
            response = $0
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response)
    }

    func testThatFutureDecodableWorks() {
        // Given
        let urlRequest = URLRequest.makeHTTPBinRequest()
        let expect = expectation(description: "futureDecodable should complete")
        var response: DataResponse<HTTPBinResponse>?

        // When
        let request = AF.request(urlRequest)
        let future = request.futureDecodable(of: HTTPBinResponse.self)
        _ = future.sink {
            response = $0
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response)
    }

    func testThatFutureDecodableCanBeComposed() {
        // Given
        let urlRequest = URLRequest.makeHTTPBinRequest()
        let expect = expectation(description: "futureDecodables should complete")
        var firstResponse: DataResponse<HTTPBinResponse>?
        var secondResponse: DataResponse<HTTPBinResponse>?

        // When
        let first = AF.request(urlRequest).futureDecodable(of: HTTPBinResponse.self)
        let second = AF.request(urlRequest).futureDecodable(of: HTTPBinResponse.self)
        let zipped = Publishers.Zip(first, second)
        _ = zipped.sink {
            firstResponse = $0
            secondResponse = $1
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(firstResponse)
        XCTAssertNotNil(secondResponse)
    }

    func testThatResponseOperatorCanBeUsedInStream() {
        // Given
        let urlRequest = URLRequest.makeHTTPBinRequest()
        let expect = expectation(description: "operator stream should complete")
        var response: DataResponse<HTTPBinResponse>?

        // When
        _ = Publishers.Just(urlRequest)
            .map { AF.request($0) }
            .response(of: HTTPBinResponse.self)
            .sink {
                response = $0
                expect.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response)
    }

    // TODO: Figure out cancellation.
//    func testThatResponseOperatorCanBeCancelled() {
//        // Given
//        let urlRequest = URLRequest.makeHTTPBinRequest()
//        let expect = expectation(description: "operator stream should complete")
//        var response: DataResponse<HTTPBinResponse>?
//
//        // When
//        let canceller = Publishers.Just(urlRequest)
//            .map { AF.request($0) }
//            .response(of: HTTPBinResponse.self)
//            .sink {
//                response = $0
//                expect.fulfill()
//            }
//        canceller.cancel()
//
//        waitForExpectations(timeout: timeout)
//
//        // Then
//        switch response?.result {
//        case let .failure(error)?:
//            XCTAssertTrue(error.asAFError?.isExplicitlyCancelledError == true)
//        default: XCTFail()
//        }
//        XCTAssertNotNil(response)
//    }

    func testThatRequestOperatorCanBeUsedInStream() {
        // Given
        let urlRequest = URLRequest.makeHTTPBinRequest()
        let expect = expectation(description: "operator stream should complete")
        var response: DataResponse<HTTPBinResponse>?

        // When
        _ = Publishers.Just(urlRequest)
            .request()
            .response(of: HTTPBinResponse.self)
            .sink {
                response = $0
                expect.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response)
    }
}

#endif
