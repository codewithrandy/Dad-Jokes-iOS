//
//  Joke.swift
//  DadJokes
//
//  Created by Randy McKown on 2/14/23.
//

import Foundation

struct Joke: Codable, Identifiable {
    var id: String
    var category: String
    var setup: String
    var punchline: String
}
