//
//  ContentView.swift
//  TCASharedWhat
//
//  Created by oantoniuk on 17.10.2024.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Feature {
    struct State {
        @Shared var thing: SharedThing

        init(thing: SharedThing = .init()) {
            self._thing = Shared(wrappedValue: .init(), .sharedThing)
        }
    }

    enum Action: IOS16SharedStateAction {
        case onAppear
        case toggleThing
        case _sharedStateDidUpdate
    }

    enum CancelID {
        case sharedState
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if #available(iOS 17.0, *) {
                    return .none
                } else {
                    return .syncSharedState(state.$thing)
                    .cancellable(id: CancelID.sharedState, cancelInFlight: true)
                }

            case .toggleThing:
                state.thing.isOk.toggle()
                return .none

            case ._sharedStateDidUpdate:
                return .none
            }
        }
    }
}

struct ContentView: View {
    struct ViewState: Equatable {
        let isOn: Bool

        init(state: Feature.State) {
            self.isOn = state.thing.isOk
        }
    }

    let store: StoreOf<Feature>
    @ObservedObject var viewStore: ViewStore<ViewState, Feature.Action>

    init(store: StoreOf<Feature>) {
        self.store = store
        self.viewStore = .init(store, observe: ViewState.init(state:))
    }

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Toggle(isOn: viewStore.binding(get: \.isOn, send: { _ in .toggleThing })) {
                Text("Is OK?")
            }
        }
        .padding()
        .onAppear {
            viewStore.send(.onAppear)
        }
    }
}

#Preview {
    ContentView(store: Store(initialState: Feature.State(), reducer: {
        Feature()
    }))
}

/// ---------------

struct SharedThing {
    var isOk: Bool

    init(isOk: Bool = false) {
        self.isOk = isOk
    }
}

extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<SharedThing>> {
    static var sharedThing: Self {
        PersistenceKeyDefault(.inMemory("sharedThing"), SharedThing())
    }
}

public protocol IOS16SharedStateAction: Equatable {
    static var _sharedStateDidUpdate: Self { get }
}

extension Effect where Action: IOS16SharedStateAction {
    public static func syncSharedState<Value>(_ state: Shared<Value>) -> Effect<Action> {
        .run { send in
            for await _ in state.publisher.values {
                await send(Action._sharedStateDidUpdate)
            }
        }
    }
}
