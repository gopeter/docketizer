//
//  Apollo.swift
//  docketizer
//
//  Created by Peter Oesteritz on 02.04.25.
//

import Apollo
import ApolloAPI
import Foundation

class UnauthorizedInterceptor: ApolloInterceptor {
    var id: String = "UnauthorizedInterceptor"
    
    func interceptAsync<Operation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        
        
        // Prüfe, ob die Response ein 401 war
        if let httpResponse = response?.httpResponse,
           httpResponse.statusCode == 401 {
            
            UserDefaults.standard.set(nil, forKey: "apiKey")
            UserDefaults.standard.set(nil, forKey: "tenant")
            
        } else {
            // Kein 401 – normal weitermachen
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
        }
    }
}

class CustomInterceptorProvider: InterceptorProvider {
    private let store: ApolloStore
    private let client: URLSessionClient

    init(store: ApolloStore, client: URLSessionClient) {
        self.store = store
        self.client = client
    }

    func interceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [ApolloInterceptor] {
        return [
            MaxRetryInterceptor(),
            NetworkFetchInterceptor(client: client),
            UnauthorizedInterceptor(),
            ResponseCodeInterceptor(),
            JSONResponseParsingInterceptor(),
        ]
    }
}

class Apollo {
    static let shared = Apollo()
    private var apolloClient: ApolloClient!

    private init() {
        configureClient()
    }

    func configureClient() {
        var domain = ProcessInfo.processInfo.environment["DOCKET_URL"] ?? "godocket.app"
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            domain = "docket.dev:3000"
        }
        
        guard let tenant = UserDefaults.standard.string(forKey: "tenant"),
              let url = URL(string: "https://\(tenant).\(domain)/graphql") else {
            print("Settings not found")
            return
        }

        let authToken = UserDefaults.standard.string(forKey: "apiKey") ?? ""

        let client = URLSessionClient()
        let store = ApolloStore()
        let interceptors = CustomInterceptorProvider(store: store, client: client)

        let transport = RequestChainNetworkTransport(
            interceptorProvider: interceptors,
            endpointURL: url,
            additionalHeaders: [
                "Authorization": "\(authToken)"
            ]
        )

        apolloClient = ApolloClient(networkTransport: transport, store: store)
    }

    func client() -> ApolloClient {
        if apolloClient == nil {
            configureClient()
        }
        
        return apolloClient
    }
}
