//
//  LegacyGeoServiceLogic.swift
//  AdapterFacade
//
//  Created by Andrew on 25.10.2026.
//


protocol LegacyGeoServiceLogic: Sendable {
    @discardableResult
    func fetch(
        code: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) -> Cancellable
}

extension LegacyGeoService: LegacyGeoServiceLogic, @unchecked Sendable {}
