

struct StorySettings: Hashable {
    var user: User
    var genre: [String]
    var world: [String]
    var narrativeStyle: String
}


extension StorySettings {
    static let stub = StorySettings(
        user: User(name: "Jane", gender: .female),
        genre: ["台大校園生活", "輕鬆有趣"],
        world: ["現代都市", "爸爸是一個住鶯歌的怪人", "師大資工系學生", "最喜歡參加資工營"],
        narrativeStyle: "對話主導（以角色互動推動情節），角色對話要多一點"
    )
    
    static func withStubSettings(name: String, gender: User.Gender) -> StorySettings {
        var stub = StorySettings.stub
        stub.user = User(name: name, gender: gender)
        return stub
    }
}
