//
//  Combine.swift
//  Alamofire
//
//  Created by Jon Shier on 6/9/19.
//  Copyright © 2019 Alamofire. All rights reserved.
//

#if canImport(Combine)

import Combine

extension DataRequest {
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    public func futureDecodable<T: Decodable>(of type: T.Type = T.self, queue: DispatchQueue = .main, decoder: DataDecoder = JSONDecoder()) -> Publishers.Future<DataResponse<T>, Never> {
        return Publishers.Future { (completion) in
            self.responseDecodable(queue: queue, decoder: decoder) { (response: DataResponse<T>) in
                completion(.success(response))
            }
        }
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension Publisher where Output == DataRequest {
    func response<T: Decodable>(of type: T.Type = T.self, queue: DispatchQueue = .main, decoder: DataDecoder = JSONDecoder()) -> Publishers.AF.Response<Self, T> {
        return Publishers.AF.Response(self, queue: queue, decoder: decoder, of: type)
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension Publishers {
    enum AF {
        public struct Response<Upstream: Publisher, T: Decodable>: Publisher where Upstream.Output == DataRequest {
            public typealias Output = DataResponse<T>
            public typealias Failure = Upstream.Failure

            let upstream: Upstream
            let queue: DispatchQueue
            let decoder: DataDecoder

            init(_ upstream: Upstream, queue: DispatchQueue, decoder: DataDecoder, of: T.Type) {
                self.upstream = upstream
                self.queue = queue
                self.decoder = decoder
            }

            public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
                let inner = Inner(subscriber, queue: queue, decoder: decoder)
                upstream.subscribe(inner)
                subscriber.receive(subscription: inner)
            }

            final class Inner<Downstream: Subscriber>: Subscriber, Subscription where Downstream.Input == DataResponse<T> {
                typealias Input = DataRequest
                typealias Failure = Downstream.Failure

                var subscription: Subscription?
                var downstream: Downstream?

                let queue: DispatchQueue
                let decoder: DataDecoder
                let lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)

                init(_ downstream: Downstream, queue: DispatchQueue, decoder: DataDecoder) {
                    self.downstream = downstream
                    self.queue = queue
                    self.decoder = decoder
                }

                deinit {
                    lock.deallocate()
                }

                func receive(subscription: Subscription) {
                    os_unfair_lock_lock(lock)
                    guard self.subscription == nil else {
                        os_unfair_lock_unlock(lock)
                        subscription.cancel()
                        return
                    }
                    self.subscription = subscription
                    os_unfair_lock_unlock(lock)
                }

                func receive(_ input: DataRequest) -> Subscribers.Demand {
                    input.responseDecodable(queue: queue, decoder: decoder, completionHandler: { (response: DataResponse<T>) -> Void in
                        if let result = self.downstream?.receive(response) {
                            if result > 0 {
                                os_unfair_lock_lock(self.lock)
                                if let sub = self.subscription {
                                    os_unfair_lock_unlock(self.lock)
                                    sub.request(result)
                                    return
                                }
                                os_unfair_lock_unlock(self.lock)
                            }
                        }
                    })
                    return .none
                }

                func receive(completion: Subscribers.Completion<Downstream.Failure>) {
                    os_unfair_lock_lock(lock)
                    if let ds = downstream {
                        os_unfair_lock_unlock(lock)
                        ds.receive(completion: completion)
                        return
                    }
                    os_unfair_lock_unlock(lock)
                }

                func request(_ demand: Subscribers.Demand) {
                    os_unfair_lock_lock(lock)
                    if let sub = subscription {
                        os_unfair_lock_unlock(lock)
                        sub.request(demand)
                        return
                    }
                    os_unfair_lock_unlock(lock)

                }

                func cancel() {
                    os_unfair_lock_lock(lock)
                    subscription = nil
                    downstream = nil
                    os_unfair_lock_unlock(lock)
                }
            }
        }
    }
}

#endif
