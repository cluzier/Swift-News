//
//  ResultState.swift
//  News
//
//  Created by Conner Luzier on 1/24/22.
//

import Foundation

// This is hit when the user opens the app or upon refreshing the articles.
// If the api fails to load data it will display an error screen with failed() case, if it gets data, it will display success() case
enum ResultState {
    case loading
    case success(content: [Article])
    case failed(error: Error)
}
