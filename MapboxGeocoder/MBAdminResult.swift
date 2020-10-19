//
//  AdminServiceResult.swift
//  MapboxGeocoder
//
//

@objc(AdminPointResult)
open class AdminPointResult: NSObject {
    public var status : Int?  = ServiceStatus.OK
    public var total : Int? = 0
    public var items : [AdminItem]?
    
}

public struct AdminServiceResult: Codable {
    public var status : Int?  = ServiceStatus.OK
    public var total : Int? = 0
    public var items : [AdminItem]?
}
    
public struct AdminItem: Codable {
    public var id: Int? = 0
    public var level: Int?
    public var code: String?
    public var name: String?
    public var paths: [String]?
    public var colorIndex: Int?
    public var obj_id : String?
    public var bound: LatLngBounds?
    public var coordinates: [[LatLng]]?
//    public var coordinates: List<List<LatLng>>?
}

public struct LatLngBounds: Codable {
    public var latitudeSouth : Double? = 0.0
    public var longitudeWest : Double? = 0.0
    public var latitudeNorth : Double? = 0.0
    public var longitudeEast : Double? = 0.0
}

public struct LatLng: Codable {
    public var latitude : Double?
    public var longitude : Double?
}

public struct ServiceStatus{
    /** Xu ly thanh cong, khong co loi xay ra */
    public static let OK = 0
    
    /** Invalid request, thieu hoac truyen sai kieu parameter */
    public static let INVALID_REQUEST = 1
    
    /** Thieu quyen thuc hien request, kiem tra app name va app key */
    public static let REQUEST_DENIED = 2
    
    /** Loi khong ro nguyen nhan, request co the thanh cong trong lan thu lai sau do */
    public static let UNKNOWN_ERROR = 3
    
    /** Khong co ket qua tra ve, tim kiem duoc 0 record */
    public static let ZERO_RESULTS = 4
    
    /** Co loi xay ra phia server khi xu ly request */
    public static let ERROR = 5
    
    /** Loi danh rieng cho routing, truyen qua nhieu diem waypoint cho xu ly routing */
    public static let MAX_POINTS_EXCEEDED = 6
}

public struct AdminLevelType: Codable{
    public static let PROVINCE = 1
    
    public static let DISTRICT = 2
    
    public static let COMMUNE = 3
    
}

public struct AdminReturnType: Codable{
    public static let CODE = 1
    
    public static let NAME = 2
    
    public static let PATH = 4
    
    public static let INDEX_COLOR = 8
    
    public static let OBJ_ID = 16
    
    public static let BOUND = 32
    
    public static let ALL = 256
    
}
