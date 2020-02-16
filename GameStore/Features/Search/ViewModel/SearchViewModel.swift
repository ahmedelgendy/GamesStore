//
//  SearchViewModel.swift
//  GameStore
//
//  Created by Elgendy on 11.02.2020.
//  Copyright © 2020 Elgendy. All rights reserved.
//

import Foundation

protocol SearchViewModelDelegate: class {
    func onFetchCompleted(showLoadingCell: Bool)
    func onFetchFailed(reason: String)
}

class SearchViewModel {
    
    weak var delegate: SearchViewModelDelegate?

    private var repository: GameRepository
    private var games = [Game]()
    private var throttler = Throttler(delay: 0.7)
    private var page = 1

    var searchKeyword: String!
    var showLoadingCell = false
    
    init(repository: GameRepository) {
        self.repository = repository
    }
    
    func resetState() {
        games = []
        page = 1
        showLoadingCell = false
    }
    
    func startNewSearch(with keyword: String) {
        resetState() // start with clean state
        throttler.throttle { [unowned self] in
            self.searchKeyword = keyword
            self.search()
        }
    }
    
    func search() {
        print("Searching started for \(String(describing: searchKeyword))...")
        var params = SearchGamesParameters(keyword: searchKeyword)
        params.page = page
        repository.searchGames(with: params) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let value):
                    self.games.append(contentsOf: value.results ?? [])
                    if let _ = value.next {
                        self.showLoadingCell = true
                        self.page += 1
                    }
                    self.delegate?.onFetchCompleted(showLoadingCell: self.showLoadingCell)
                case .failure(let error):
                    self.delegate?.onFetchFailed(reason: error.localizedDescription)
                }
            }
        }
    }
    
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        guard showLoadingCell else { return false }
        return indexPath.row == (numberOfItems() - 1)
    }
    
    func numberOfItems() -> Int {
        return showLoadingCell ? (self.games.count + 1) : self.games.count
    }
    
    func cellViewModelAt(index: Int) -> SearchCellViewModel {
        return SearchCellViewModel(game: self.games[index])
    }
    
    func gameIdAt(index: Int) -> Int {
        self.games[index].id
    }
    
}
