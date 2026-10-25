//
//  LegacyGeoServiceAdapter.swift
//  AdapterFacade
//
//  Created by Andrew on 25.10.2026.
//

import Foundation

final class LegacyGeoServiceAdapter: CountryProvider {
    // MARK: - Nested Types
    fileprivate struct State {
        var continuation: CheckedContinuation<Result<Country, GeoError>, Never>?
        var requestToken: Cancellable?
        var isCancelled: Bool = false
    }
    
    // Dependencies
    private let legacyGeoService: LegacyGeoServiceLogic
    
    // MARK: - Init
    init(legacyGeoService: LegacyGeoServiceLogic) {
        self.legacyGeoService = legacyGeoService
    }
    
    // MARK: - Public Methods
    func country(code: String) async throws(GeoError) -> Country {
        let state = ThreadSafeWrapper(State())
        
        let result: Result<Country, GeoError> = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                var isCancelled = false
                state.mutate { state in
                    state.continuation = continuation
                    isCancelled = state.isCancelled
                }
                guard !isCancelled else {
                    state.resume(returning: .failure(.cancelled))
                    return
                }
                
                let requestToken = legacyGeoService.fetch(code: code) { data, error in
                    let result = LegacyGeoServiceAdapter.makeResult(data: data, error: error)
                    state.resume(returning: result)
                }
                
                state.mutate { state in
                    state.requestToken = requestToken
                    isCancelled = state.isCancelled
                }
                if isCancelled {
                    requestToken.cancel()
                }
            }
        } onCancel: {
            var requestToken: Cancellable?
            state.mutate { state in
                state.isCancelled = true
                requestToken = state.requestToken
            }
            requestToken?.cancel()
            state.resume(returning: .failure(.cancelled))
        }
        
        return try result.get()
    }
}

// MARK: - Private Methods
private extension LegacyGeoServiceAdapter {
    static func makeResult(data: [String: Any]?, error: Error?) -> Result<Country, GeoError> {
        if let error {
            return .failure(.network(underlying: error))
        }
        
        guard let data else {
            return .failure(.notFound)
        }
        
        do throws(GeoError) {
            let country = try mapCountry(data)
            return .success(country)
        } catch {
            return .failure(error)
        }
    }
}

private extension ThreadSafeWrapper where T == LegacyGeoServiceAdapter.State {
    func resume(returning: Result<Country, GeoError>) {
        var continuation: CheckedContinuation<Result<Country, GeoError>, Never>?
        mutate { state in
            continuation = state.continuation
            state.continuation = nil
        }
        continuation?.resume(returning: returning)
    }
}
