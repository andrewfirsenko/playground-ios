import Foundation

let data = """
{
    "name": "USERBOB",
    "info": {
        "birth_day": "213124213"
    }
}
"""

struct UserData: Codable {
    
    var name: String
    var birthDay: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case info
    }
    
    enum InfoCodingKeys: String, CodingKey {
        case birthDay = "birth_day"
    }
    
    init(name: String, birthDay: String) {
        self.name = name
        self.birthDay = birthDay
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let infoContainer = try container.nestedContainer(keyedBy: InfoCodingKeys.self, forKey: .info)
        self.name = try container.decode(String.self, forKey: .name)
        self.birthDay = try infoContainer.decode(String.self, forKey: .birthDay)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        var infoContainer = container.nestedContainer(keyedBy: InfoCodingKeys.self, forKey: .info)
        try infoContainer.encode(birthDay, forKey: .birthDay)
    }
}

let jsonUser = try? JSONDecoder().decode(UserData.self, from: data.data(using: .ascii)!)
print(jsonUser?.name)
print(jsonUser?.birthDay)

let myUser = UserData(name: "Bob", birthDay: "23423423")
let myData = try? JSONEncoder().encode(myUser)
print(String(data: myData!, encoding: .utf8))


