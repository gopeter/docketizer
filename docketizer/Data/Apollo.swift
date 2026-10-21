//
//  Apollo.swift
//  docketizer
//
//  Created by Peter Oesteritz on 02.04.25.
//

import Apollo
import ApolloAPI
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.docket.docketizer", category: "Apollo")

// Reads the current auth token from UserDefaults on every request so that
// a retried request after silent re-auth automatically uses the new token
// without needing to rebuild the entire Apollo client.
class AuthHeaderInterceptor: ApolloInterceptor {
    var id: String = "AuthHeaderInterceptor"

    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        if let apiKey = UserDefaults.standard.string(forKey: "apiKey") {
            request.additionalHeaders["Authorization"] = apiKey
        }
        chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
    }
}

// On a 401 response, attempts a silent re-authentication using credentials
// stored in the Keychain. If successful, retries the original request with
// the new token. If not, clears the session so @AppStorage shows the login screen.
class UnauthorizedInterceptor: ApolloInterceptor {
    var id: String = "UnauthorizedInterceptor"

    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        guard
            let httpResponse = response?.httpResponse
        else {
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        if httpResponse.statusCode != 401 {
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        let failedToken = request.additionalHeaders["Authorization"]

        // Guard against infinite retry loops: if this request already went through a
        // re-auth cycle once (the header was set below before the previous retry) and
        // still came back with a 401, the new credentials are also invalid – e.g. the
        // password was changed server-side. Bail out instead of retrying forever.
        if request.additionalHeaders["X-Reauth-Attempted"] == "1" {
            chain.handleErrorAsync(
                AuthError.invalidCredentials,
                request: request,
                response: response,
                completion: completion
            )
            return
        }

        // Mark the request before retrying so the guard above can detect a second 401.
        // Apollo's chain.retry() reuses the same HTTPRequest object, so the header
        // survives into the retried attempt and reaches this interceptor again.
        request.additionalHeaders["X-Reauth-Attempted"] = "1"

        Task {
            let result = await AuthManager.shared.silentReAuth(failedToken: failedToken)

            switch result {
            case .success:
                // AuthHeaderInterceptor will pick up the new token from UserDefaults on retry
                chain.retry(request: request, completion: completion)
            case .failure(let requiresLogin, let error):
                if requiresLogin {
                    // Could not re-auth – clear the session. @AppStorage("apiKey") in RootView
                    // will react and show the login screen.
                    await MainActor.run {
                        AuthManager.shared.logout()
                    }
                }
                chain.handleErrorAsync(
                    error ?? AuthError.invalidCredentials,
                    request: request,
                    response: response,
                    completion: completion
                )
            }
        }
    }
}

// Logs any error that reaches the end of the interceptor chain so that
// failures are visible in Console.app under the "Apollo" category.
class ErrorLoggingInterceptor: ApolloInterceptor {
    var id: String = "ErrorLoggingInterceptor"

    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        chain.proceedAsync(request: request, response: response, interceptor: self) { result in
            switch result {
            case .failure(let error):
                let statusCode = response?.httpResponse.statusCode
                let operationName = Operation.operationName

                if let statusCode {
                    logger.error("[\(operationName)] Request failed with HTTP \(statusCode): \(error.localizedDescription)")
                } else {
                    logger.error("[\(operationName)] Request failed: \(error.localizedDescription)")
                }
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    let operationName = Operation.operationName
                    let messages = errors.map { $0.message ?? "(no message)" }.joined(separator: ", ")
                    logger.error("[\(operationName)] GraphQL error(s): \(messages)")
                }
            }

            completion(result)
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
            AuthHeaderInterceptor(),
            NetworkFetchInterceptor(client: client),
            UnauthorizedInterceptor(),
            ResponseCodeInterceptor(),
            JSONResponseParsingInterceptor(),
            ErrorLoggingInterceptor(),
        ]
    }
}

class Apollo {
    static let shared = Apollo()
    private var apolloClient: ApolloClient?

    private init() {
        configureClient()
    }

    func configureClient() {
        let domain = DocketServer.domain

        guard
            let tenant = UserDefaults.standard.string(forKey: "tenant"),
            let url = URL(string: "https://\(tenant).\(domain)/graphql")
        else {
            return
        }

        let client = URLSessionClient()
        let store = ApolloStore()
        let interceptors = CustomInterceptorProvider(store: store, client: client)

        let transport = RequestChainNetworkTransport(
            interceptorProvider: interceptors,
            endpointURL: url
        )

        apolloClient = ApolloClient(networkTransport: transport, store: store)
    }

    func client() -> ApolloClient? {
        if apolloClient == nil {
            configureClient()
        }

        return apolloClient
    }
}
