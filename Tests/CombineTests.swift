//
//  CombineTests.swift
//
//  Copyright (c) 2019 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
        let future = Future<DataResponse<HTTPBinResponse>, Never> { completion in
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
        _ = Just(urlRequest)
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
//        let canceller = Session.default.requestPublisher(for: urlRequest)
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
//        print(response)
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
        _ = Just(urlRequest)
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
    
    func testThatURLRequestConvertibleOperatorCanBeUsedInStream() {
        // Given
        let request = HTTPBinRequest(method: .get, parameters: .default)
        let expect = expectation(description: "operator stream should complete")
        var response: DataResponse<HTTPBinResponse>?
        
        // When
        _ = Just(request)
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
