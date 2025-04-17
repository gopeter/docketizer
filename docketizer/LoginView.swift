//
//  LoginView.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import SwiftUI

struct LoginResponse: Codable {
    let auth_token: String
}

struct LoginView: View {
    @State var tenant: String = ""
    @State var email: String = ""
    @State var password: String = ""
    @State var errors: String = ""

    @State var settings = Settings()

    var body: some View {
        Form {
            TextField("Tenant", text: $tenant)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)

            if errors != "" {
                Text(errors).padding(.vertical)
            }

            Button("Login") {
                login()
            }
        }.padding()
    }

    private func login() {
        errors = ""

        guard let url = URL(string: "https://\(tenant).godocket.app/api/login")
        else {
            errors = "Invalid docket URL"
            return
        }

        let payload = ["email": email, "password": password]
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: payload)
        else {
            errors = "Error while handling user input"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                errors = "User not found or password wrong, please try again"
                return
            }

            if data == nil {
                errors = "Error while handling server response"
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(
                    LoginResponse.self,
                    from: data!
                )

                settings.apiKey = decodedResponse.auth_token
                settings.tenant = tenant
            } catch {
                errors = "Error while handling server response"
                return
            }

        }.resume()
    }
}

#Preview {
    LoginView().frame(width: 300)
}
