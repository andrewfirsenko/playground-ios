//
//  CountryMapper.swift
//  AdapterFacade
//
//  Created by Andrew on 25.10.2026.
//

func mapCountry(_ raw: [String: Any]) throws(GeoError) -> Country {
    guard let code = raw["code"] as? String,
          let name = raw["name"] as? String,
          let capital = raw["capital"] as? String else {
        throw .invalidData
    }
    return Country(
        code: code,
        name: name,
        capital: capital
    )
}
