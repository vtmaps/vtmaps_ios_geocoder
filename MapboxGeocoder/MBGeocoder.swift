import Foundation


typealias JSONDictionary = [String: Any]

/// Indicates that an error occurred in MapboxGeocoder.
public let MBGeocoderErrorDomain = "MBGeocoderErrorDomain"
//public var debugMode: Bool = false
/// The Mapbox access token specified in the main application bundle’s Info.plist.
let defaultAccessToken = Bundle.main.infoDictionary?["VTMapAccessToken"] as? String
let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
/// The user agent string for any HTTP requests performed directly within this library.
let userAgent: String = {
    var components: [String] = []

    if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        components.append("\(appName)/\(version)")
    }

    let libraryBundle: Bundle? = Bundle(for: Geocoder.self)

    if let libraryName = libraryBundle?.infoDictionary?["CFBundleName"] as? String, let version = libraryBundle?.infoDictionary?["CFBundleShortVersionString"] as? String {
        components.append("\(libraryName)/\(version)")
    }

    let system: String
    #if os(OSX)
        system = "macOS"
    #elseif os(iOS)
        system = "iOS"
    #elseif os(watchOS)
        system = "watchOS"
    #elseif os(tvOS)
        system = "tvOS"
    #elseif os(Linux)
        system = "Linux"
    #endif
    let systemVersion = ProcessInfo().operatingSystemVersion
    components.append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")

    let chip: String
    #if arch(x86_64)
        chip = "x86_64"
    #elseif arch(arm)
        chip = "arm"
    #elseif arch(arm64)
        chip = "arm64"
    #elseif arch(i386)
        chip = "i386"
    #elseif os(watchOS) // Workaround for incorrect arch in machine.h for watch simulator  gen 4
        chip = "i386"
    #else
        chip = "unknown"
    #endif
    components.append("(\(chip))")

    return components.joined(separator: " ")
}()

extension CharacterSet {
    /**
     Returns the character set including the characters allowed in the “geocoding query” (file name) part of a Geocoding API URL request.
     */
    internal static func geocodingQueryAllowedCharacterSet() -> CharacterSet {
        var characterSet = CharacterSet.urlPathAllowed
        characterSet.remove(charactersIn: "/;")
        return characterSet
    }
}

extension CLLocationCoordinate2D {
    /**
     Initializes a coordinate pair based on the given GeoJSON array.
     */
    internal init(geoJSON array: [CLLocationDegrees]) {
        assert(array.count == 2)
        self.init(latitude: array[1], longitude: array[0])
    }
}

extension CLLocation {
    /**
     Initializes a CLLocation object with the given coordinate pair.
     */
    internal convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /**
     Returns a GeoJSON compatible array of coordinates.
     */
    internal func geojson() -> [CLLocationDegrees] {
        return [coordinate.longitude, coordinate.latitude]
    }
}

/**
 A geocoder object that allows you to query the [Mapbox Geocoding API](https://www.mapbox.com/api-documentation/search/#geocoding) for known places corresponding to a given location. The query may take the form of a geographic coordinate or a human-readable string.

 The geocoder object allows you to perform both forward and reverse geocoding. _Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.

 Each result produced by the geocoder object is stored in a `Placemark` object. Depending on your query and the available data, the placemark object may contain a variety of information, such as the name, address, region, or contact information for a place, or some combination thereof.
 */
@objc(MBGeocoder)
open class Geocoder: NSObject {
    
    /**
     A closure (block) to be called when a geocoding request is complete.

     - parameter placemarks: An array of `Placemark` objects. For reverse geocoding requests, this array represents a hierarchy of places, beginning with the most local place, such as an address, and ending with the broadest possible place, which is usually a country. By contrast, forward geocoding requests may return multiple placemark objects in situations where the specified address matched more than one location.

        If the request was canceled or there was an error obtaining the placemarks, this parameter is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
     - parameter attribution: A legal notice indicating the source, copyright status, and terms of use of the placemark data.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias CompletionHandler = (_ placemarks: [ViettelPlacemark]?, _ attribution: String?, _ error: NSError?) -> Void

    public typealias CompletionHandlerJsonResult = ( _ rawJsonString: String?, _ error: NSError?) -> Void
    
    public typealias CompletionHandlerAdminByPoint = ( _ result: AdminPointResult?, _ error: NSError?) -> Void
    public typealias CompletionHandlerGeoLatLngToAddsResult = ( _ result: GeoLatLngToAddsResult?, _ error: NSError?) -> Void
    public typealias CompletionHandlerGeoLatLngToMultiAddsResult = ( _ result: GeoLatLngToMultiAddsResult?, _ error: NSError?) -> Void
    public typealias CompletionHandlerGeoTextToAddsResult = ( _ result: GeoTextToAddsResult?, _ error: NSError?) -> Void
    
    /**
     A closure (block) to be called when a geocoding request is complete.

     - parameter placemarksByQuery: An array of arrays of `Placemark` objects, one placemark array for each query. For reverse geocoding requests, these arrays represent hierarchies of places, beginning with the most local place, such as an address, and ending with the broadest possible place, which is usually a country. By contrast, forward geocoding requests may return multiple placemark objects in situations where the specified address matched more than one location.

        If the request was canceled or there was an error obtaining the placemarks, this parameter is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
     - parameter attributionsByQuery: An array of legal notices indicating the sources, copyright statuses, and terms of use of the placemark data for each query.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias BatchCompletionHandler = (_ placemarksByQuery: [[ViettelPlacemark]]?, _ attributionsByQuery: [String]?, _ error: NSError?) -> Void

    /**
     The shared geocoder object.

     To use this object, a Mapbox [access token](https://www.mapbox.com/help/define-access-token/) should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    @objc(sharedGeocoder)
    public static let shared = Geocoder(accessToken: nil)

    /// The API endpoint to request the geocodes from.
    internal var apiEndpoint: URL
    
    public var debugMode: Bool = false {
      didSet {
        var baseURLComponents = URLComponents()
        baseURLComponents.scheme = "https"
        
        if(debugMode){
            baseURLComponents.host = "api.viettelmaps.com.vn"
            baseURLComponents.port = 8080
        }else{
            baseURLComponents.host = "api.viettelmaps.vn"
        }
        self.apiEndpoint = baseURLComponents.url!
      }
    }
    
//    public var debugMode: Bool = false
    
    /// The Mapbox access token to associate the request with.
    internal let accessToken: String

    /**
     Initializes a newly created geocoder object with an optional access token and host.

     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the geocoder object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The Mapbox Geocoding API endpoint is used by default.
     */
    @objc public init(accessToken: String?, host: String?) {
        let accessToken = accessToken ?? defaultAccessToken
        assert(accessToken != nil && !accessToken!.isEmpty, "A Mapbox access token is required. Go to <https://www.mapbox.com/studio/account/tokens/>. In Info.plist, set the MGLMapboxAccessToken key to your access token, or use the Geocoder(accessToken:host:) initializer.")

        self.accessToken = accessToken!
        var baseURLComponents = URLComponents()
        baseURLComponents.scheme = "https"
        
        if(debugMode){
            baseURLComponents.host = host ?? "api.viettelmaps.com.vn"
            baseURLComponents.port = 8080
        }else{
            baseURLComponents.host = host ?? "api.viettelmaps.vn"
        }
        self.apiEndpoint = baseURLComponents.url!
        
    }

    /**
     Initializes a newly created geocoder object with an optional access token.

     The geocoder object sends requests to the Mapbox Geocoding API endpoint.

     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the geocoder object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    @objc public convenience init(accessToken: String?) {
        self.init(accessToken: accessToken, host: nil)
    }
    
    // MARK: Geocoding a Location

    /**
     Submits a geocoding request to search for placemarks and delivers the results to the given closure.

     This method retrieves the placemarks asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the placemarks.

     Geocoding results may be displayed atop a Mapbox map. They may be cached but may not be stored permanently. To use the results in other contexts or store them permanently, use the `batchGeocode(_:completionHandler:)` method with a Mapbox enterprise plan.

     - parameter options: A `ForwardGeocodeOptions` or `ReverseGeocodeOptions` object indicating what to search for.
     - parameter completionHandler: The closure (block) to call with the resulting placemarks. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting placemarks, cancel this task.
     */

    @discardableResult
    @objc(geocodeWithOptions:uid:completionHandler:)
    open func geocode(_ options: GeocodeOptions, uid: String? = nil, completionHandler: @escaping CompletionHandler) -> URLSessionDataTask {
        let url = urlForGeocoding(options)

        let task = dataTaskWithURL(url, uid: uid, completionHandler: { (data) in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(GeocodeResult.self, from: data)
                assert(result.type == "FeatureCollection")
                completionHandler(result.placemarks, result.attribution, nil)
            } catch {
                completionHandler(nil, nil, error as NSError)
            }
        }) { (error) in
            completionHandler(nil, nil, error)
        }
        task.resume()
        return task
    }

    /**
     Submits a batch geocoding request to search for placemarks and delivers the results to the given closure.

     This method retrieves the placemarks asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the placemarks.

     Batch geocoding requires a Mapbox enterprise plan and allows you to store the resulting placemark data as part of a private database.

     - parameter options: A `ForwardBatchGeocodeOptions` or `ReverseBatchGeocodeOptions` object indicating what to search for.
     - parameter completionHandler: The closure (block) to call with the resulting placemarks. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting placemarks, cancel this task.
     */
    @discardableResult
    @objc(batchGeocodeWithOptions:uid:completionHandler:)
    open func batchGeocode(_ options: GeocodeOptions & BatchGeocodeOptions, uid: String, completionHandler: @escaping BatchCompletionHandler) -> URLSessionDataTask {
        let url = urlForGeocoding(options)

        let task = dataTaskWithURL(url, uid: uid, completionHandler: { (data) in
            guard let data = data else { return }
            let decoder = JSONDecoder()

            do {

                let result: [GeocodeResult]

                do {
                    // Decode multiple batch geocoding queries
                    result = try decoder.decode([GeocodeResult].self, from: data)
                } catch {
                    // Decode single batch geocding queries
                    result = [try decoder.decode(GeocodeResult.self, from: data)]
                }

                let placemarks = result.map { $0.placemarks }
                let attributionsByQuery = result.map { $0.attribution }
                completionHandler(placemarks, attributionsByQuery, nil)

            } catch {
                completionHandler(nil, nil, error as NSError)
            }

        }) { (error) in
            completionHandler(nil, nil, error)
        }
        task.resume()
        return task
    }

    /**
     Returns a URL session task for the given URL that will run the given blocks on completion or error.

     - parameter url: The URL to request.
     - parameter completionHandler: The closure to call with the parsed JSON response dictionary.
     - parameter errorHandler: The closure to call when there is an error.
     - returns: The data task for the URL.
     - postcondition: The caller must resume the returned task.
     */
    fileprivate func dataTaskWithURL(_ url: URL, uid: String? = nil, completionHandler: @escaping (_ data: Data?) -> Void, errorHandler: @escaping (_ error: NSError) -> Void) -> URLSessionDataTask {
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        if components.queryItems == nil {
            components.queryItems = []
        }
        if let uid = uid {
            components.queryItems?.append(URLQueryItem(name: "uid", value: uid))
        }

        if let query = components.url!.query {
            request.httpBody = Data(query.utf8)
        }

        return URLSession.shared.dataTask(with: request) { (data, response, error) in

            guard let data = data else {
                DispatchQueue.main.async {
                    if let e = error as NSError? {
                        errorHandler(e)
                    } else {
                        let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: -1024, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "this error happens when data task return nil data and nil error, which typically is not possible"])
                        errorHandler(unexpectedError)
                    }
                }
                return
            }
            let decoder = JSONDecoder()

            do {
                // Handle multiple batch geocoding queries
                let result = try decoder.decode([GeocodeAPIResult].self, from: data)

                // Check if any of the batch geocoding queries failed
                if let failedResult = result.first(where: { $0.message != nil }) {
                    let apiError = Geocoder.descriptiveError(["message": failedResult.message!], response: response, underlyingError: error as NSError?)
                    DispatchQueue.main.async {
                        errorHandler(apiError)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completionHandler(data)
                }
            } catch {
                // Handle single & single batch geocoding queries
                do {
                    let result = try decoder.decode(GeocodeAPIResult.self, from: data)
                    // Check if geocoding query failed
                    if let message = result.message {
                        let apiError = Geocoder.descriptiveError(["message": message], response: response, underlyingError: error as NSError?)
                        DispatchQueue.main.async {
                            errorHandler(apiError)
                        }
                        return

                    }
                    DispatchQueue.main.async {
                        completionHandler(data)
                    }
                } catch {
                    // Handle errors that don't return a message (such as a server/network error)
                    DispatchQueue.main.async {
                        errorHandler(error as NSError)
                    }
                }
            }
        }
    }
    
    internal struct GeocodeAPIResult: Codable {
        let message: String?
    }
    
    internal struct HistoriesAPIResult: Codable {
        let statusCode: Int
        let message: String
        let data: History?
    }

    /**
     The HTTP URL used to fetch the geocodes from the API.
     */
    @objc open func urlForGeocoding(_ options: GeocodeOptions) -> URL {
        let params = options.params + [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "bundle_id", value: bundleIdentifier),
        ]

        assert(!options.queries.isEmpty, "No query")

//        let mode = options.mode

        let queryComponent = options.queries.map {
            $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
        }.joined(separator: ";")

        let unparameterizedURL = URL(string: "/gateway/searching/v1/search/geocoding/\(queryComponent).json", relativeTo: apiEndpoint)!
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        return components.url!
    }
    
    //MARK: - UPDATE API: GET REQUEST
    /**
     Returns a URL session task for the given URL that will run the given blocks on completion or error.

     - parameter url: The URL to request.
     - parameter completionHandler: The closure to call with the parsed JSON response dictionary.
     - parameter errorHandler: The closure to call when there is an error.
     - returns: The data task for the URL.
     - postcondition: The caller must resume the returned task.
     */
    fileprivate func dataTaskWithGETURL(_ url: URL, completionHandler: @escaping (_ data: Data?) -> Void, errorHandler: @escaping (_ error: NSError) -> Void) -> URLSessionDataTask {
        print("dataTaskWithGETURL : " + url.absoluteString)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        return URLSession.shared.dataTask(with: request) { (data, response, error) in
            var statusCode = 0
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    if let e = error as NSError? {
                        errorHandler(e)
                    } else {
                        let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: -1024, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "this error happens when data task return nil data and nil error, which typically is not possible"])
                        errorHandler(unexpectedError)
                    }
                }
                return
            }
            
            guard error == nil else {
                print("Error: error calling GET")
                print(error!)
                let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: statusCode, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "Error: error calling GET"])
                DispatchQueue.main.async {
                    errorHandler(unexpectedError)
                }
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                print("Error: HTTP request failed")
                let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: statusCode, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "Error: HTTP request failed"])
                DispatchQueue.main.async {
                    errorHandler(unexpectedError)
                }
                return
            }
            do {
                guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("Error: Cannot convert data to JSON object")
                    let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: statusCode, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "Error: Cannot convert data to JSON object"])
                    DispatchQueue.main.async {
                        errorHandler(unexpectedError)
                    }
                    return
                }
                guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                    print("Error: Cannot convert JSON object to Pretty JSON data")
                    let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: statusCode, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "Error: Cannot convert JSON object to Pretty JSON data"])
                    DispatchQueue.main.async {
                        errorHandler(unexpectedError)
                    }
                    return
                }
                guard let prettyPrintedJson = String(data: prettyJsonData, encoding: .utf8) else {
                    print("Error: Could print JSON in String")
                    let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: statusCode, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "Error: Could print JSON in String"])
                    DispatchQueue.main.async {
                        errorHandler(unexpectedError)
                    }
                    return
                }
                print(prettyPrintedJson)
                DispatchQueue.main.async {
                    completionHandler(data)
                }
            } catch {
                print("Error: Trying to convert JSON data to string")
                let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: statusCode, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "Error: Trying to convert JSON data to string"])
                DispatchQueue.main.async {
                    errorHandler(unexpectedError)
                }
                return
            }
            
        }
    }
    
    //MARK: - UPDATE API: GET URL
    
    /**
      Geoservice - latlng to address
     
     - parameter f: getaddr(cố định không thay đổi parram này)
     - parameter pt: LatLng(kiểu String ví dụ 16.059366,108.208236)
     - parameter k : accessToken
     - returns: The HTTP URL used to fetch the data  from the API.
     */
    
    @objc open func urlForGeoserviceLatlngToAddress(_ options: GeocodeOptions, LatLng: String) -> URL {
            let params = [
                URLQueryItem(name: "f", value: "getaddr"),
                URLQueryItem(name: "pt", value: LatLng),
                URLQueryItem(name: "k", value: accessToken),
            ]
            assert(!options.queries.isEmpty, "No query")
            let _ = options.queries.map {
                $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
            }.joined(separator: ";")

            let unparameterizedURL = URL(string: "/gateway/placeapi/v2-old/place-api/VTMapService/geoprocessing", relativeTo: apiEndpoint)!
            var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
            components.queryItems = params
            return components.url!
    }
    
    
    /**
      Geoservice - multi latlng to address
     
     - parameter f: getmultiaddr(cố định không thay đổi parram này)
     - parameter pt: LatLng(kiểu String ví dụ 21.044844,105.852367;21.044844,105.835372)
     - parameter k : accessToken
     - returns: The HTTP URL used to fetch the data  from the API.
     */
    @objc open func urlForGeoserviceMultiLatlngToAddress(_ options: GeocodeOptions, LatLng: String) -> URL {
            let params = [
                URLQueryItem(name: "f", value: "getmultiaddr"),
                URLQueryItem(name: "pt", value: LatLng),
                URLQueryItem(name: "k", value: accessToken),
            ]
            assert(!options.queries.isEmpty, "No query")
            let _ = options.queries.map {
                $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
            }.joined(separator: ";")

            let unparameterizedURL = URL(string: "/gateway/placeapi/v2-old/place-api/VTMapService/geoprocessing", relativeTo: apiEndpoint)!
            var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
            components.queryItems = params
            return components.url!
    }
    
    /**
      Geoservice - text to address
     
     - parameter t: text search(kiểu String)
     - parameter off: offset
     - parameter lm: limit
     - parameter k : accessToken
     - returns: The HTTP URL used to fetch the data  from the API.
     */
    @objc open func urlForGeoserviceTextToAddress(_ options: GeocodeOptions, textSearch: String, offset: String, limit: String) -> URL {
            let params = [
                URLQueryItem(name: "t", value: textSearch),
                URLQueryItem(name: "off", value: offset),
                URLQueryItem(name: "lm", value: limit),
                URLQueryItem(name: "k", value: accessToken),
            ]
            assert(!options.queries.isEmpty, "No query")
            let _ = options.queries.map {
                $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
            }.joined(separator: ";")

            let unparameterizedURL = URL(string: "/gateway/placeapi/v2-old/place-api/VTMapService/placeService/geocoding", relativeTo: apiEndpoint)!
            var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
            components.queryItems = params
            return components.url!
    }
    
    /**
      Geoservice - search around
     
     - parameter f: search(cố định không thay đổi parram này)
     - parameter pt: LatLng(kiểu String ví dụ 16.059366,108.208236)
     - parameter t: text search(kiểu String)
     - parameter r: bán kính mét(kiểu int)
     - parameter off: offset
     - parameter lm: limit
     - parameter k : accessToken
     - returns: The HTTP URL used to fetch the data  from the API.
     */
    @objc open func urlForGeoserviceSearchAround(_ options: GeocodeOptions, LatLng: String, textSearch: String, radius: String, offset: String, limit: String) -> URL {
            let params = [
                URLQueryItem(name: "f", value: "search"),
                URLQueryItem(name: "pt", value: LatLng),
                URLQueryItem(name: "t", value: textSearch),
                URLQueryItem(name: "r", value: radius),
                URLQueryItem(name: "off", value: offset),
                URLQueryItem(name: "lm", value: limit),
                URLQueryItem(name: "k", value: accessToken),
            ]
            assert(!options.queries.isEmpty, "No query")
            let _ = options.queries.map {
                $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
            }.joined(separator: ";")

            let unparameterizedURL = URL(string: "/gateway/placeapi/v2-old/place-api/VTMapService/placeService/geoprocessing", relativeTo: apiEndpoint)!
            var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
            components.queryItems = params
            return components.url!
    }
    
    /**
      Adminservice - by point
     
     - parameter f: point(cố định không thay đổi parram này)
     - parameter pt: LatLng(kiểu String ví dụ 16.059366,108.208236)
     - parameter rt: 255(cố định không thay đổi param này)
     - parameter l=1 : trả về Tỉnh thành,  l=2: trả về quận,huyện, l=3: trả về xã,phường
     - parameter k : accessToken
     - returns: The HTTP URL used to fetch the data  from the API.
     */
    @objc open func urlForAdminserviceByPoint(_ options: GeocodeOptions, LatLng: String, returnType: String, type: String) -> URL {
            let params = [
                URLQueryItem(name: "f", value: "point"),
                URLQueryItem(name: "pt", value: LatLng),
                URLQueryItem(name: "rt", value: returnType),
                URLQueryItem(name: "l", value: type),
                URLQueryItem(name: "k", value: accessToken),
            ]
            assert(!options.queries.isEmpty, "No query")
            let _ = options.queries.map {
                $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
            }.joined(separator: ";")

            let unparameterizedURL = URL(string: "/gateway/placeapi/v2-old/place-api/VTMapService/administrationService", relativeTo: apiEndpoint)!
            var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
            components.queryItems = params
            return components.url!
    }
    
    /**
      Adminservice - by code
     
     - parameter f: code(cố định không thay đổi parram này)
     - parameter code: mã hành chính (ví dụ 79)
     - parameter rt: 255(cố định không thay đổi parram này)
     - parameter l=1 : trả về Tỉnh thành, l=2: trả về quận,huyện, l=3: trả về xã,phường
     - parameter k : accessToken
     - returns: The HTTP URL used to fetch the data  from the API.
     */
    @objc open func urlForAdminserviceByCode(_ options: GeocodeOptions, code: String, returnType: String, type: String) -> URL {
            let params = [
                URLQueryItem(name: "f", value: "code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "rt", value: returnType),
                URLQueryItem(name: "l", value: type),
                URLQueryItem(name: "k", value: accessToken),
            ]
            assert(!options.queries.isEmpty, "No query")
            let _ = options.queries.map {
                $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
            }.joined(separator: ";")

            let unparameterizedURL = URL(string: "/gateway/placeapi/v2-old/place-api/VTMapService/administrationService", relativeTo: apiEndpoint)!
            var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
            components.queryItems = params
            return components.url!
    }
    
    /**
      Adminservice - by circle
    - parameter
    - returns: The HTTP URL used to fetch the data  from the API.
     */
    @objc open func urlForAdminserviceByCircle(_ options: GeocodeOptions, LatLng: String, radius: String, returnType: String, type: String) -> URL {
            let params = [
                URLQueryItem(name: "f", value: "circle"),
                URLQueryItem(name: "pt", value: LatLng),
                URLQueryItem(name: "r", value: radius),
                URLQueryItem(name: "rt", value: "3"),
                URLQueryItem(name: "l", value: type),
                URLQueryItem(name: "k", value: accessToken),
            ]
            assert(!options.queries.isEmpty, "No query")
            let _ = options.queries.map {
                $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
            }.joined(separator: ";")

            let unparameterizedURL = URL(string: "/gateway/placeapi/v2-old/place-api/VTMapService/administrationService", relativeTo: apiEndpoint)!
            var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
            components.queryItems = params
            return components.url!
    }
    
    /**
      Adminservice - by boundary
     - parameter
     - returns: The HTTP URL used to fetch the data  from the API.
     */
    @objc open func urlForAdminserviceByBoundary(_ options: GeocodeOptions, LatLng: String, returnType: String, type: String) -> URL {
            let params = [
                URLQueryItem(name: "f", value: "view"),
                URLQueryItem(name: "rt", value: returnType),
                URLQueryItem(name: "l", value: type),
                URLQueryItem(name: "b", value: LatLng),
                URLQueryItem(name: "k", value: accessToken),
            ]
            assert(!options.queries.isEmpty, "No query")
            let _ = options.queries.map {
                $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
            }.joined(separator: ";")

            let unparameterizedURL = URL(string: "/gateway/placeapi/v2-old/place-api/VTMapService/administrationService", relativeTo: apiEndpoint)!
            var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
            components.queryItems = params
            return components.url!
    }
    
    //MARK: - UPDATE API: METHOD
    
    @discardableResult
    @objc(geoserviceLatlngToAddressWithOptions:LatLng:completionHandler:)
    open func geoserviceLatlngToAddress(_ options: GeocodeOptions, LatLng: String? = "", completionHandler: @escaping CompletionHandlerGeoLatLngToAddsResult) -> URLSessionDataTask {
        let url = urlForGeoserviceLatlngToAddress(options, LatLng: LatLng!)
        let decoder = JSONDecoder()
        let task = dataTaskWithGETURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            do {
                var resultJsonString = ""
                if let (arrayJsonString) = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(arrayJsonString)
                    let dataJsonString =  try JSONSerialization.data(withJSONObject:arrayJsonString, options: .prettyPrinted)
                    print(dataJsonString)
                    let rawJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                    print(rawJsonString)
                    resultJsonString = rawJsonString
                }
                let result = try decoder.decode(GeoLatLngToAdds.self, from: data)
                let geoResult = GeoLatLngToAddsResult()
                geoResult.status = result.status
                geoResult.data = result.data
                completionHandler(geoResult, nil)
            } catch {
                completionHandler(nil, error as NSError)
            }
        }) { (error) in
            completionHandler(nil, error)
        }
        task.resume()
        return task
    }
    
    @discardableResult
    @objc(geoserviceMultiLatlngToAddressWithOptions:LatLng:completionHandler:)
    open func geoserviceMultiLatlngToAddress(_ options: GeocodeOptions, LatLngString: String? = "", completionHandler: @escaping CompletionHandlerGeoLatLngToMultiAddsResult) -> URLSessionDataTask {
        let url = urlForGeoserviceMultiLatlngToAddress(options, LatLng: LatLngString!)
        let decoder = JSONDecoder()
        let task = dataTaskWithGETURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            do {
                var resultJsonString = ""
                if let (arrayJsonString) = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(arrayJsonString)
                    let dataJsonString =  try JSONSerialization.data(withJSONObject:arrayJsonString, options: .prettyPrinted)
                    print(dataJsonString)
                    let rawJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                    print(rawJsonString)
                    resultJsonString = rawJsonString
                }
                let result = try decoder.decode(GeoLatLngToMultiAdds.self, from: data)
                let geoResult = GeoLatLngToMultiAddsResult()
                geoResult.status = result.status
                geoResult.addresses = result.addresses
                if(nil != geoResult.addresses && !geoResult.addresses!.isEmpty){
                    for item in geoResult.addresses! {
                        
                        let listDecodeLatLng : [VTMLatLng] = VTMapUtils.decodePoints(item.location, withType: Int32(VMSEncryptEarthPoint.rawValue)) as! [VTMLatLng]
                        if (!listDecodeLatLng.isEmpty){
                            let latLng = listDecodeLatLng[0]
                            item.locationLatLng = LatLng(latitude: latLng.latitude, longitude: latLng.longitude)
                        }else{
                            item.locationLatLng = LatLng(latitude: 0.0, longitude: 0.0)
                        }
                    }
                }
                completionHandler(geoResult, nil)
            } catch {
                completionHandler(nil, error as NSError)
            }
        }) { (error) in
            completionHandler(nil, error)
        }
        task.resume()
        return task
    }
    
    @discardableResult
    @objc(geoserviceTextToAddressWithOptions:textSearch:offset:limit:completionHandler:)
    open func geoserviceTextToAddress(_ options: GeocodeOptions, textSearch: String? = "", offset: String? = "", limit: String? = "", completionHandler: @escaping CompletionHandlerGeoTextToAddsResult) -> URLSessionDataTask {
        let url = urlForGeoserviceTextToAddress(options, textSearch: textSearch!, offset: offset!, limit: limit!)
        let decoder = JSONDecoder()
        let task = dataTaskWithGETURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            do {
                var resultJsonString = ""
                if let (arrayJsonString) = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(arrayJsonString)
                    let dataJsonString =  try JSONSerialization.data(withJSONObject:arrayJsonString, options: .prettyPrinted)
                    print(dataJsonString)
                    let rawJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                    print(rawJsonString)
                    resultJsonString = rawJsonString
                }
                let result = try decoder.decode(GeoTextToAdds.self, from: data)
                let geoResult = GeoTextToAddsResult()
                geoResult.status = result.status
                geoResult.total = result.total
                geoResult.items = result.items
                
                if(nil != geoResult.items && !geoResult.items!.isEmpty){
                    for item in geoResult.items! {
                        
                        let listDecodeLatLng : [VTMLatLng] = VTMapUtils.decodePoints(item.location, withType: Int32(VMSEncryptEarthPoint.rawValue)) as! [VTMLatLng]
                        if (!listDecodeLatLng.isEmpty){
                            let latLng = listDecodeLatLng[0]
                            item.locationLatLng = LatLng(latitude: latLng.latitude, longitude: latLng.longitude)
                        }else{
                            item.locationLatLng = LatLng(latitude: 0.0, longitude: 0.0)
                        }
                    }
                }
                completionHandler(geoResult, nil)
            } catch {
                completionHandler(nil, error as NSError)
            }
        }) { (error) in
            completionHandler(nil, error)
        }
        task.resume()
        return task
    }
    
    @discardableResult
    @objc(geoserviceSearchAroundWithOptions:LatLng:textSearch:radius:offset:limit:completionHandler:)
    open func geoserviceSearchAround(_ options: GeocodeOptions, LatLng: String? = "", textSearch: String? = "", radius:String? = "", offset: String? = "", limit: String? = "",completionHandler: @escaping CompletionHandlerJsonResult) -> URLSessionDataTask {
        let url = urlForGeoserviceSearchAround(options, LatLng: LatLng!, textSearch: textSearch!, radius: radius!, offset: offset!, limit: limit!)

        let task = dataTaskWithGETURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            do {
                var resultJsonString = ""
                if let (arrayJsonString) = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(arrayJsonString)
                    let dataJsonString =  try JSONSerialization.data(withJSONObject:arrayJsonString, options: .prettyPrinted)
                    print(dataJsonString)
                    let rawJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                    print(rawJsonString)
                    resultJsonString = rawJsonString
                }
                completionHandler(resultJsonString, nil)
            } catch {
                completionHandler("", error as NSError)
            }
        }) { (error) in
            completionHandler("", error)
        }
        task.resume()
        return task
    }
    
    @discardableResult
    @objc(adminserviceByPointWithOptions:LatLng:returnType:type:completionHandler:)
    open func adminserviceByPoint(_ options: GeocodeOptions, LatLng: String? = "", returnType: String? = "", type: String? = "", completionHandler: @escaping CompletionHandlerAdminByPoint) -> URLSessionDataTask {
        let url = urlForAdminserviceByPoint(options, LatLng: LatLng!, returnType: returnType!, type: type!)
        let decoder = JSONDecoder()
        
        let task = dataTaskWithGETURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            do {
                var resultJsonString = ""
                if let (arrayJsonString) = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(arrayJsonString)
                    let dataJsonString =  try JSONSerialization.data(withJSONObject:arrayJsonString, options: .prettyPrinted)
                    print(dataJsonString)
                    let rawJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                    print(rawJsonString)
                    resultJsonString = rawJsonString
                }
                let result = try decoder.decode(AdminServiceResult.self, from: data)
                let adminPointResult = AdminPointResult()
                adminPointResult.status = result.status
                adminPointResult.total = result.total
                adminPointResult.items = result.items
                
                completionHandler(adminPointResult, nil)
            } catch {
                completionHandler(nil, error as NSError)
            }
        }) { (error) in
            completionHandler(nil, error)
        }
        task.resume()
        return task
    }
    
    @discardableResult
    @objc(adminserviceByCodeWithOptions:LatLng:returnType:type:completionHandler:)
    open func adminserviceByCode(_ options: GeocodeOptions, code: String? = "", returnType: String? = "", type: String? = "",completionHandler: @escaping CompletionHandlerJsonResult) -> URLSessionDataTask {
        let url = urlForAdminserviceByCode(options, code: code!, returnType: returnType!, type: type!)

        let task = dataTaskWithGETURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            do {
                var resultJsonString = ""
                if let (arrayJsonString) = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(arrayJsonString)
                    let dataJsonString =  try JSONSerialization.data(withJSONObject:arrayJsonString, options: .prettyPrinted)
                    print(dataJsonString)
                    let rawJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                    print(rawJsonString)
                    resultJsonString = rawJsonString
                }
                completionHandler(resultJsonString, nil)
            } catch {
                completionHandler("", error as NSError)
            }
        }) { (error) in
            completionHandler("", error)
        }
        task.resume()
        return task
    }
    
    @discardableResult
    @objc(adminserviceByCircleWithOptions:LatLng:radius:returnType:type:completionHandler:)
    open func adminserviceByCircle(_ options: GeocodeOptions, LatLng: String? = "", radius: String? = "", returnType: String? = "", type: String? = "", completionHandler: @escaping CompletionHandlerJsonResult) -> URLSessionDataTask {
        let url = urlForAdminserviceByCircle(options, LatLng: LatLng!, radius: radius!, returnType: returnType!, type: type!)

        let task = dataTaskWithGETURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            do {
                var resultJsonString = ""
                if let (arrayJsonString) = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(arrayJsonString)
                    let dataJsonString =  try JSONSerialization.data(withJSONObject:arrayJsonString, options: .prettyPrinted)
                    print(dataJsonString)
                    let rawJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                    print(rawJsonString)
                    resultJsonString = rawJsonString
                }
                completionHandler(resultJsonString, nil)
            } catch {
                completionHandler("", error as NSError)
            }
        }) { (error) in
            completionHandler("", error)
        }
        task.resume()
        return task
    }
    
    @discardableResult
    @objc(adminserviceByBoundaryWithOptions:LatLng:returnType:type:completionHandler:)
    open func adminserviceByBoundary(_ options: GeocodeOptions, LatLng: String? = "", returnType: String? = "", type: String? = "", completionHandler: @escaping CompletionHandlerJsonResult) -> URLSessionDataTask {
        let url = urlForAdminserviceByBoundary(options, LatLng: LatLng!, returnType: returnType!, type: type!)

        let task = dataTaskWithGETURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            do {
                var resultJsonString = ""
                if let (arrayJsonString) = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(arrayJsonString)
                    let dataJsonString =  try JSONSerialization.data(withJSONObject:arrayJsonString, options: .prettyPrinted)
                    print(dataJsonString)
                    let rawJsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                    print(rawJsonString)
                    resultJsonString = rawJsonString
                }
                completionHandler(resultJsonString, nil)
            } catch {
                completionHandler("", error as NSError)
            }
        }) { (error) in
            completionHandler("", error)
        }
        task.resume()
        return task
    }
    
    //MARK: -

    /**
     Returns an error that supplements the given underlying error with additional information from the an HTTP response’s body or headers.
     */
    static func descriptiveError(_ json: JSONDictionary, response: URLResponse?, underlyingError error: NSError?) -> NSError {
        var userInfo = error?.userInfo ?? [:]
        if let response = response as? HTTPURLResponse {
            var failureReason: String? = nil
            var recoverySuggestion: String? = nil
            switch response.statusCode {
            case 429:
                if let timeInterval = response.rateLimitInterval, let maximumCountOfRequests = response.rateLimit {
                    let intervalFormatter = DateComponentsFormatter()
                    intervalFormatter.unitsStyle = .full
                    let formattedInterval = intervalFormatter.string(from: timeInterval) ?? "\(timeInterval) seconds"
                    let formattedCount = NumberFormatter.localizedString(from: maximumCountOfRequests as NSNumber, number: .decimal)
                    failureReason = "More than \(formattedCount) requests have been made with this access token within a period of \(formattedInterval)."
                }
                if let rolloverTime = response.rateLimitResetTime {
                    let formattedDate = DateFormatter.localizedString(from: rolloverTime, dateStyle: .long, timeStyle: .long)
                    recoverySuggestion = "Wait until \(formattedDate) before retrying."
                }
            default:
                failureReason = json["message"] as? String
            }
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason ?? userInfo[NSLocalizedFailureReasonErrorKey] ?? HTTPURLResponse.localizedString(forStatusCode: error?.code ?? -1)
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion ?? userInfo[NSLocalizedRecoverySuggestionErrorKey]
        }
        if let error = error {
            userInfo[NSUnderlyingErrorKey] = error
        }
        return NSError(domain: error?.domain ?? MBGeocoderErrorDomain, code: error?.code ?? -1, userInfo: userInfo)
    }
    
    @discardableResult
    open func getHistories(uid: String, token: String, completionHandler: @escaping (_ histories: History?, _ error: NSError?) -> Void) -> URLSessionDataTask {

        let task = historiesDataTask(uid: uid, token: token, method: "GET", completionHandler: { (histories) in
            completionHandler(histories, nil)
        }) { (error) in
            completionHandler(nil, error as NSError)
        }
        task.resume()
        return task
    }
    
    fileprivate func historiesDataTask(uid: String, token: String, method: String, completionHandler: @escaping (_ histories: History?) -> Void, errorHandler: @escaping (_ error: NSError) -> Void) -> URLSessionDataTask {
        //var request = URLRequest(url: URL(string: "https://api.viettelmaps.com.vn:8080/gateway/searching/v1/histories")!)
		var request = URLRequest(url: URL(string: "http://api.viettelmaps.vn/gateway/searching/v1/histories")!)

        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField:"Authorization")
        request.setValue(uid, forHTTPHeaderField:"uid")
        return URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    if let e = error as NSError? {
                        errorHandler(e)
                    } else {
                        let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: -1024, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "this error happens when data task return nil data and nil error, which typically is not possible"])
                        errorHandler(unexpectedError)
                    }
                }
                return
            }
            let decoder = JSONDecoder()
            
            do {
                let result = try decoder.decode(HistoriesAPIResult.self, from: data)
                
                if result.statusCode != 200 {
                    let apiError = Geocoder.descriptiveError(["message": result.message], response: response, underlyingError: error as NSError?)
                    DispatchQueue.main.async {
                        errorHandler(apiError)
                    }
                    return

                }
                DispatchQueue.main.async {
                    completionHandler(result.data)
                }
            } catch {
                // Handle errors that don't return a message (such as a server/network error)
                DispatchQueue.main.async {
                    errorHandler(error as NSError)
                }
            }
        }
    }
    
    @discardableResult
    open func deleteHistories(uid: String, token: String, completionHandler: @escaping (_ histories: History?, _ error: NSError?) -> Void) -> URLSessionDataTask {

        let task = historiesDataTask(uid: uid, token: token, method: "DELETE", completionHandler: { (histories) in
            completionHandler(histories, nil)
        }) { (error) in
            completionHandler(nil, error as NSError)
        }
        task.resume()
        return task
    }
}

extension HTTPURLResponse {
    var rateLimit: UInt? {
        guard let limit = allHeaderFields["X-Rate-Limit-Limit"] as? String else {
            return nil
        }
        return UInt(limit)
    }

    var rateLimitInterval: TimeInterval? {
        guard let interval = allHeaderFields["X-Rate-Limit-Interval"] as? String else {
            return nil
        }
        return TimeInterval(interval)
    }

    var rateLimitResetTime: Date? {
        guard let resetTime = allHeaderFields["X-Rate-Limit-Reset"] as? String else {
            return nil
        }
        guard let resetTimeNumber = Double(resetTime) else {
            return nil
        }
        return Date(timeIntervalSince1970: resetTimeNumber)
    }

}
