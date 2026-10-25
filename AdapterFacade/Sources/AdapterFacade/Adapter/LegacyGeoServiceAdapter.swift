//
//  LegacyGeoServiceAdapter.swift
//  AdapterFacade
//
//  Created by Andrew on 25.10.2026.
//

import Foundation

final class LegacyGeoServiceAdapter: CountryProvider {
    private let legacyGeoService: LegacyGeoServiceLogic
    
    init(legacyGeoService: LegacyGeoServiceLogic) {
        self.legacyGeoService = legacyGeoService
    }
    
//    legacyGeoService.fetch(code: code) - completion вызывается 2жды. Эту проблему не исправил
    
    func country(code: String) async throws(GeoError) -> Country {
        let token: ThreadSafeWrapper<Cancellable?> = ThreadSafeWrapper(nil)
        let result: Result<Country, GeoError> = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                token.mutate { token in
                    token = legacyGeoService.fetch(code: code) { data, error in
                        if let error {
                            continuation.resume(returning: .failure(.network(underlying: error)))
                            return
                        }
                        
                        guard let data else {
                            continuation.resume(returning: .failure(.invalidData))
                            return
                        }
                        
                        do throws(GeoError) {
                            let country = try mapCountry(data)
                            continuation.resume(returning: .success(country))
                        } catch {
                            continuation.resume(returning: .failure(error))
                        }
                    }
                }
            }
        } onCancel: {
            token.mutate { $0?.cancel() }
        }
        
        return try result.get()
    }
}
