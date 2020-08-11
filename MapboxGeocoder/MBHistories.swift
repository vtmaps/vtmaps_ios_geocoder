//
//  MBHistories.swift
//  MapboxGeocoder
//
//  Created by waz on 11/18/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

public struct History: Codable {
    public let homePlace: PlaceHistory?
    public let companyPlace: PlaceHistory?
    public let searchHistories: [SearchHistory]?
}

public struct PlaceHistory: Codable {
    public let id: Int
    public let userId: Int
    public let poiId: Int
    public let poiType: Int
    public let name: String
    public let address: String
    public let lat: String
    public let lng: String
    public let placeType: Int
    public let iconName: String
}

public struct SearchHistory: Codable {
    public var id: Int
    public var userId: Int?
    public var poiId: Int?
    public var keySearch: String?
    public var poiType: Int?
    public var createdDate: String?
    public var name: String?
    public var address: String?
    public var iconName: String?
    
    public init(id: Int, podId: Int?, poiType: Int?, name: String?, address: String?) {
        self.id = id
        self.userId = nil
        self.poiId = podId
        self.keySearch = nil
        self.poiType = poiType
        self.createdDate = nil
        self.name = name
        self.address = address
        self.iconName = nil
    }
    
    public init(id: Int, keySearch: String?) {
        self.id = id
        self.userId = nil
        self.poiId = nil
        self.keySearch = keySearch
        self.poiType = nil
        self.createdDate = nil
        self.name = nil
        self.address = nil
        self.iconName = nil
    }
}
