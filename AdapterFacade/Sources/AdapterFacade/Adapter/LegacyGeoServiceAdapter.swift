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
                state.mutate { $0.continuation = continuation }
                
                let requestToken = legacyGeoService.fetch(code: code) { data, error in
                    if let error {
                        state.resume(returning: .failure(.network(underlying: error)))
                        return
                    }
                    
                    guard let data else {
                        state.resume(returning: .failure(.notFound))
                        return
                    }
                    
                    do throws(GeoError) {
                        let country = try mapCountry(data)
                        state.resume(returning: .success(country))
                    } catch {
                        state.resume(returning: .failure(error))
                    }
                }
                state.mutate { $0.requestToken = requestToken }
            }
        } onCancel: {
            // Тут надо подумать, возможно тут есть гонка
            state.value.requestToken?.cancel()
            state.resume(returning: .failure(.cancelled))
        }
        
        return try result.get()
    }
}

// MARK: - Private Methods
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
