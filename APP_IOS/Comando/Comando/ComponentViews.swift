import SwiftUI

// Componente para a barra de Clima
struct ClimaView: View {
    let clima: (temperatura: String, vento: String, chuva: String)
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 25) {
            ClimaItem(
                iconName: "thermometer.sun",
                text: clima.temperatura,
                label: localizationManager.string(for: "temperature")
            )
            ClimaItem(
                iconName: "wind",
                text: clima.vento,
                label: localizationManager.string(for: "wind")
            )
            ClimaItem(
                iconName: "cloud.rain",
                text: clima.chuva,
                label: localizationManager.string(for: "rain")
            )
        }
        .padding(.vertical, 25)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
}

// Sub-componente para cada item do clima
struct ClimaItem: View {
    let iconName: String
    let text: String
    let label: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: iconName)
                .font(.system(size: 32))
                .accessibilityLabel(label)
            Text(text)
                .font(.system(size: 20))
        }
        .foregroundColor(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(text)")
    }
}

// Componente para o Card de Alertas
struct AlertasCard: View {
    let alertas: [Alerta]
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 15) {
            CardHeader(
                iconName: "light.beacon.max",
                title: localizationManager.string(for: "alerts")
            )
            
            // Lista os alertas reais. Se não houver, mostra uma mensagem.
            if alertas.isEmpty {
                Text(localizationManager.string(for: "no_alerts"))
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            } else {
                ForEach(alertas, id: \.nome) { alerta in
                    AlertRow(text: alerta.nome!)
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
}

struct CardHeader: View {
    let iconName: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 24))
            Text(title)
                .font(.system(size: 28, weight: .bold))
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal)
    }
}

struct AlertRow: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundColor(.white)
        .font(.system(size: 18))
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// As chaves temperature, wind, rain, alerts e no_alerts já existem no arquivo original

// Caso precise de novas traduções específicas para este componente:

// Português (pt)
"climate_conditions" = "Condições Climáticas";
"view_all_alerts" = "Ver todos os alertas";

// English (en)
"climate_conditions" = "Weather Conditions";
"view_all_alerts" = "View all alerts";

// Español (es)
"climate_conditions" = "Condiciones Climáticas";
"view_all_alerts" = "Ver todas las alertas";
*/
