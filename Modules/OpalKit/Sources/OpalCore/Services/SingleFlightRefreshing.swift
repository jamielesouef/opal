//
//  SingleFlightRefreshing.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

@MainActor
public protocol SingleFlightRefreshing: AnyObject {
    var refreshTask: Task<Void, Never>? { get set }
    func performRefresh() async
}

extension SingleFlightRefreshing {
    public func refresh() async {
        refreshTask?.cancel()
        let task = Task { [weak self] in
            guard let self else {
                return
            }

            await performRefresh()
        }
        refreshTask = task
        await task.value
    }
}
