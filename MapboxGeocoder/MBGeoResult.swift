//
//  AdminServiceResult.swift
//  MapboxGeocoder
//
//

@objc(GeoLatLngToAddsResult)
open class GeoLatLngToAddsResult: NSObject {
    public var status : Int?  = ServiceStatus.OK
    public var data : String?
}

public struct GeoLatLngToAdds: Codable {
    public var status : Int?  = ServiceStatus.OK
    public var data : String?
}

@objc(GeoLatLngToMultiAddsResult)
open class GeoLatLngToMultiAddsResult: NSObject {
    public var status : Int?  = ServiceStatus.OK
    public var addresses : [addressesItem]?
}

public struct GeoLatLngToMultiAdds: Codable {
    public var status : Int?  = ServiceStatus.OK
    public var addresses : [addressesItem]?
}


@objc(GeoTextToAddsResult)
open class GeoTextToAddsResult: NSObject {
    public var status : Int?  = ServiceStatus.OK
    public var total : Int? = 0
    public var items : [GeoObjItem]?
    
}

public struct GeoTextToAdds: Codable {
    public var status : Int?  = ServiceStatus.OK
    public var total : Int? = 0
    public var items : [GeoObjItem]?
}

public class addressesItem: Codable {
    public var location: String?
    public var locationLatLng: LatLng?
    public var address: String?
}
    
public class GeoObjItem: Codable {
    
    public var id: Int? = 0
    public var location: String?
    public var locationLatLng: LatLng?
    public var name: String?
    public var address: String?
    public var type: Int?
    
    public var website: String?
    public var phone: String?
    public var fax: String?
    public var email: String?
    public var description: String?
    public var tourismInfo: String?
    public var hasImage: Bool? = false
    public var imagepath: String?
    
}
