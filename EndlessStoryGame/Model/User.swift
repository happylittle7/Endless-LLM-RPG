

struct User: Hashable {
    var name: String
    var gender: Gender
}

extension User {
    enum Gender: CaseIterable {
        case male
        case female

        var description: String {
            switch self {
            case .male: "男"
            case .female: "女"
            }
        }
    }
}
