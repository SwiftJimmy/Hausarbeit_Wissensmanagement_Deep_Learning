
import Foundation
/**
   Die Klasse/struct repräsentiert ein Image-Objekt
*/
struct MaskImage: Codable, Hashable {
    
    var imageData: Data?
    var location: String
    var date: Date?
    var infos = [ImageInfo]()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }
    
    static func == (lhs: MaskImage, rhs: MaskImage) -> Bool {
        return lhs.location == rhs.location
    }
    
    struct ImageInfo: Codable {
        var labelMapName: String
        var confidenceValue:String
    }

    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(MaskImage.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }

    init(imageData: Data, name: String, date: Date, infos: [ImageInfo]) {
        self.imageData = imageData
        self.location = name
        self.date = date
        self.infos = infos
    }
}

