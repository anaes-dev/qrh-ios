//
//  Guideline.swift
//  qrh
//

import Foundation

//    One guideline's details, without its cards

struct Guideline: Codable, Hashable, Identifiable, Sendable {
    var code: String
    var title: String
    var version: Int
    var url: String
    var copyright: Copyright

    var id: String { code }
}

//    Who published this guideline's version, and when. The holder is a key
//    into the file's copyrightHolders.

struct Copyright: Codable, Hashable, Sendable {
    var holder: String
    var year: Int
}

struct CopyrightHolder: Codable, Hashable, Sendable {
    var name: String
    var website: String
}


//    data.json, shared with qrh-android. Each guideline's content is its own
//    cards only: the version line, disclaimer and licence footer every
//    guideline ends with are added by Boilerplate.

struct GuidelineData: Decodable, Sendable {
    var version: String
    var copyrightHolders: [String: CopyrightHolder]
    var data: [Entry]

    struct Entry: Decodable, Sendable {
        var code: String
        var title: String
        var version: Int
        var url: String
        var copyright: Copyright
        var content: [Card]

        var guideline: Guideline {
            Guideline(code: code, title: title, version: version, url: url, copyright: copyright)
        }
    }
}
