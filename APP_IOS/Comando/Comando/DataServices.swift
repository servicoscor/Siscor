import Foundation

// MARK: - Erro Personalizado para a Camada de Serviço
enum DataServiceError: Error {
    case badURL(String)
    case requestFailed(Error)
    case decodingError
    case invalidData
    case parsingError(String)
}

// MARK: - Funções de Coleta de Dados

/// Busca os dados de uma URL e os retorna como String.
private func fetchContent(from urlString: String, includeLanguage: Bool = true) async throws -> String {
    // Adiciona o parâmetro de idioma à URL se necessário
    let finalURL: String
    if includeLanguage {
        let langCode = LocalizationManager.shared.currentLanguage
        let apiLangCode = mapLanguageCodeForAPI(langCode)
        let separator = urlString.contains("?") ? "&" : "?"
        finalURL = "\(urlString)\(separator)lang=\(apiLangCode)"
        print("🌐 API call with language: \(finalURL)")
    } else {
        finalURL = urlString
    }
    
    guard let url = URL(string: finalURL) else {
        throw DataServiceError.badURL(finalURL)
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DataServiceError.invalidData
        }
        guard let contents = String(data: data, encoding: .utf8) else {
            throw DataServiceError.decodingError
        }
        return contents
    } catch {
        throw DataServiceError.requestFailed(error)
    }
}

// Mapeia o código de idioma do app para o código esperado pela API
private func mapLanguageCodeForAPI(_ languageCode: String) -> String {
    switch languageCode {
    case "pt", "pt-BR": return "pt"
    case "en": return "en"
    case "es": return "es"
    case "fr": return "fr"
    case "zh-Hans": return "zh"
    default: return "pt" // Padrão português
    }
}

// MARK: - Serviços de Dados Principais

class ColetaDados_Alertas {
    class func getdata() async throws -> [Alerta] {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/alertas_api")
        let lines = contents.components(separatedBy: .newlines)
        
        return lines.compactMap { line -> Alerta? in
            guard !line.isEmpty else { return nil }
            let components = line.components(separatedBy: ";")
            guard components.count >= 5 else { return nil }
            
            return Alerta(
                nome: components[0],
                data: nil,
                mensagem: components[1].replacingOccurrences(of: " '", with: "").replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "jump_line", with: "\n"),
                geo: components[2],
                audio: components[3],
                audiourl: components[4]
            )
        }
    }
}

class ColetaDados_EstacaoMeteorologica {
    class func getdata() async throws -> [EstacaoMeteorologica] {
        // Esta API provavelmente não precisa de tradução (dados numéricos)
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/tempo_api", includeLanguage: false)
        let lines = contents.components(separatedBy: .newlines)
        
        return lines.compactMap { line -> EstacaoMeteorologica? in
            guard !line.isEmpty else { return nil }
            
            let components = line.components(separatedBy: ";")
            guard components.count >= 9 else { return nil }
            
            guard let lat = Double(components[1].cleaned()),
                  let lon = Double(components[2].cleaned())
            else {
                print("Erro ao parsear lat/lon na linha: \(line)")
                return nil
            }
            
            let tempMed = Float(components[3].cleaned())
            let umdMed = Float(components[4].cleaned())
            let velMed = Float(components[6].cleaned())
            
            return EstacaoMeteorologica(
                nome: components[0].cleaned(),
                fonte: components[8].cleaned(),
                data: nil,
                tem_med: tempMed,
                umd_med: umdMed,
                vel_med: velMed,
                dir_med: components[5].cleaned(),
                lat: lat,
                lon: lon
            )
        }
    }
}

// Pequena extensão para limpar as strings
extension String {
    func cleaned() -> String {
        return self.replacingOccurrences(of: "'", with: "")
                   .replacingOccurrences(of: ")", with: "")
                   .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func cleanedForNumber() -> String {
        return self.replacingOccurrences(of: " ", with: "")
                   .replacingOccurrences(of: "'", with: "")
                   .replacingOccurrences(of: ",", with: ".")
                   .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class ColetaDados_TTA { // Informes de Tempo
    class func getdata() async throws -> [InformeTempo] {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/ttempo_api")
        let trimmedContents = contents.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedContents.components(separatedBy: .newlines).compactMap { line in
            guard !line.isEmpty else { return nil }
            return InformeTempo(texto: line.replacingOccurrences(of: ";", with: "\n"))
        }
    }
}

class ColetaDados_Eventos {
    class func getdata() async throws -> [Evento] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dataAtual = dateFormatter.string(from: Date())
        
        // URL com parâmetro de idioma será adicionado automaticamente
        let urlString = "https://aplicativo.cocr.com.br/eventos_json_api_app"
        
        // Constrói a URL com o idioma
        let langCode = LocalizationManager.shared.currentLanguage
        let apiLangCode = mapLanguageCodeForAPI(langCode)
        let urlWithLang = "\(urlString)?lang=\(apiLangCode)"
        
        guard let url = URL(string: urlWithLang) else {
            throw DataServiceError.badURL(urlWithLang)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw DataServiceError.invalidData
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let eventosResponse = try decoder.decode(EventosResponse.self, from: data)
            
            return eventosResponse.eventos
            
        } catch {
            print("Erro ao buscar eventos: \(error)")
            throw DataServiceError.requestFailed(error)
        }
    }
    
    // Função alternativa que aceita uma data específica
    class func getdata(para data: Date) async throws -> [Evento] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dataString = dateFormatter.string(from: data)
        
        // Constrói a URL com data e idioma
        let langCode = LocalizationManager.shared.currentLanguage
        let apiLangCode = mapLanguageCodeForAPI(langCode)
        let urlString = "https://aplicativo.cocr.com.br/eventos_json_api?data_i=\(dataString)&lang=\(apiLangCode)"
        
        guard let url = URL(string: urlString) else {
            throw DataServiceError.badURL(urlString)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw DataServiceError.invalidData
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let eventosResponse = try decoder.decode(EventosResponse.self, from: data)
            
            return eventosResponse.eventos
            
        } catch {
            print("Erro ao buscar eventos para data \(dataString): \(error)")
            throw DataServiceError.requestFailed(error)
        }
    }
}

// MARK: - Estrutura de Resposta da API
struct EventosResponse: Codable {
    let eventos: [Evento]
}

class ColetaDados_Interdicoes_V2 {
    class func getdata() async throws -> [Interdicao] {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/interdicoes_api")
        
        let fullText = contents.replacingOccurrences(of: "jumpline", with: "\n")
        let individualInterdictions = fullText.components(separatedBy: "\n")
        
        return individualInterdictions.compactMap { text -> Interdicao? in
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else { return nil }
            
            var dayOfWeek: String? = nil
            var description = trimmedText
            
            // Ajusta os padrões de dias da semana baseado no idioma
            let daysPattern = getDaysPattern()
            for day in daysPattern {
                if trimmedText.contains(day) {
                    dayOfWeek = day
                    break
                }
            }
            
            var via: String? = nil
            if trimmedText.contains("Túnel") || trimmedText.contains("Ponte") ||
               trimmedText.contains("Elevado") || trimmedText.contains("viaduto") {
                let infrastructureTypes = ["Túnel", "Ponte", "Elevado", "viaduto", "Av.", "Avenida"]
                for type in infrastructureTypes {
                    if let range = trimmedText.range(of: type) {
                        let startIndex = trimmedText.index(range.lowerBound, offsetBy: 0)
                        let substring = String(trimmedText[startIndex...])
                        let endOfVia = substring.firstIndex(of: ",") ?? substring.endIndex
                        via = String(substring[..<endOfVia])
                        break
                    }
                }
            }
            
            var horario: String? = nil
            if let dasRange = trimmedText.range(of: "das "),
               let ateRange = trimmedText.range(of: "h", range: dasRange.upperBound..<trimmedText.endIndex) {
                let startIndex = dasRange.upperBound
                let searchEndIndex = trimmedText.index(ateRange.upperBound, offsetBy: min(20, trimmedText.distance(from: ateRange.upperBound, to: trimmedText.endIndex)))
                if let endRange = trimmedText.range(of: ".", range: ateRange.upperBound..<searchEndIndex) {
                    horario = String(trimmedText[startIndex..<endRange.lowerBound])
                }
            }
            
            return Interdicao(
                via: via ?? description,
                status: "Interdição programada",
                poli: dayOfWeek,
                reg: horario,
                nor: description
            )
        }
    }
    
    private class func getDaysPattern() -> [String] {
        let langCode = LocalizationManager.shared.currentLanguage
        
        switch langCode {
        case "en":
            return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        case "es":
            return ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        case "fr":
            return ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        case "zh":
            return ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]
        default: // pt
            return ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]
        }
    }
}

class ColetaDados_TTT { // Informes de Trânsito
    class func getdata() async throws -> [InformeTrânsito] {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/transito_api")
        return contents
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { InformeTrânsito(texto: $0.replacingOccurrences(of: ";", with: "\n")) }
    }
}

class ColetaDados_Cameras {
    class func getdata() async throws -> [Camera] {
        // Câmeras provavelmente não precisam de tradução
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/cameras_api", includeLanguage: false)
        let lines = contents.components(separatedBy: .newlines)
        
        return lines.compactMap { line -> Camera? in
            guard !line.isEmpty else { return nil }
            
            let components = line.components(separatedBy: ";")
            guard components.count >= 4 else { return nil }
            
            let latString = components[0].cleanedForNumber()
            let lonString = components[1].cleanedForNumber()
            
            guard let lat = Double(latString), let lon = Double(lonString) else {
                return nil
            }
            
            return Camera(
                apiId: components[3].cleaned(),
                nome: components[2].cleaned(),
                lat: lat,
                lon: lon
            )
        }
    }
}

class ColetaDados_Sirene {
    class func getdata() async throws -> [Sirene] {
        // Sirenes podem ter nomes/status traduzidos
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/sirene_api")
        let lines = contents.components(separatedBy: .newlines)
        
        return lines.compactMap { line -> Sirene? in
            let components = line.components(separatedBy: ";")
            guard components.count >= 7 else { return nil }
            
            let latString = components[0].replacingOccurrences(of: " ", with: "")
            let lonString = components[1].replacingOccurrences(of: " ", with: "")
            
            guard let lat = Double(latString), let lon = Double(lonString) else { return nil }
            
            return Sirene(
                nome: components[2].replacingOccurrences(of: "'", with: "").trimmingCharacters(in: .whitespaces),
                status: components[6].replacingOccurrences(of: "'", with: "").trimmingCharacters(in: .whitespaces),
                lat: lat,
                lon: lon
            )
        }
    }
}

class ColetaDados_PA { // Pontos de Apoio
    class func getdata() async throws -> [PontoDeApoio] {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/pa_api")
        return parsePALike(contents: contents)
    }
}

class ColetaDados_CF { // Unidades de Saúde
    class func getdata() async throws -> [PontoDeApoio] {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/cf_api")
        return parsePALike(contents: contents)
    }
}

class ColetaDados_FR { // Pontos de Resfriamento
    class func getdata() async throws -> [PontoDeApoio] {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/ph_api")
        return parsePALike(contents: contents)
    }
}

// Função auxiliar para parsear modelos parecidos com Ponto de Apoio
private func parsePALike(contents: String) -> [PontoDeApoio] {
    let lines = contents.components(separatedBy: .newlines)
    return lines.compactMap { line -> PontoDeApoio? in
        let components = line.components(separatedBy: ";")
        guard components.count >= 4 else { return nil }

        let latString = components[1].replacingOccurrences(of: " '", with: "").replacingOccurrences(of: "'", with: "").replacingOccurrences(of: ")", with: "")
        let lonString = components[2].replacingOccurrences(of: " '", with: "").replacingOccurrences(of: "'", with: "").replacingOccurrences(of: ")", with: "")

        guard let lat = Double(latString), let lon = Double(lonString) else { return nil }

        return PontoDeApoio(
            nome: components[0].replacingOccurrences(of: "'", with: "").trimmingCharacters(in: .whitespaces),
            endereco: components[3].replacingOccurrences(of: "'", with: "").trimmingCharacters(in: .whitespaces),
            lat: lat,
            lon: lon
        )
    }
}

class ColetaDados_Situ { // Estágio Operacional
    class func getdata() async throws -> EstagioOperacional {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/estagio_api_app")
        return EstagioOperacional(estagio: contents.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

class ColetaDados_NCSitu { // Nível de Calor
    class func getdata() async throws -> NivelCalor {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/calor_api")
        return NivelCalor(situacao: contents.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "calor", with: "Calor", options: .caseInsensitive))
    }
}

class ColetaDados_Recomenda {
    class func getdata() async throws -> [Recomendacao] {
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/recomenda_api")
        return contents.components(separatedBy: .newlines).compactMap { line -> Recomendacao? in
            guard !line.isEmpty else { return nil }
            return Recomendacao(nome: line.replacingOccurrences(of: ";", with: "\n"))
        }
    }
}

class EstacaoSer { // Estações de Chuva
    class func getEsta() async throws -> [EstacaoChuva] {
        // Dados numéricos, não precisam de tradução
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/chuva_api", includeLanguage: false)
        let lines = contents.components(separatedBy: .newlines)
        
        return lines.compactMap { line -> EstacaoChuva? in
            let components = line.components(separatedBy: ";")
            guard components.count >= 13 else { return nil }
            
            guard let lat = Double(components[0].replacingOccurrences(of: " ", with: "")),
                  let lon = Double(components[1].replacingOccurrences(of: " ", with: "")),
                  let chuva_i = Float(components[5]),
                  let chuva_1 = Float(components[6]),
                  let chuva_4 = Float(components[7]),
                  let chuva_24 = Float(components[8]),
                  let chuva_96 = Float(components[9]),
                  let chuva_30 = Float(components[10].replacingOccurrences(of: ")", with: ""))
            else {
                return nil
            }
            
            return EstacaoChuva(
                nome: components[2],
                data: components[4],
                municipio: components[3],
                chuva_i: chuva_i,
                chuva_1: chuva_1,
                chuva_4: chuva_4,
                chuva_24: chuva_24,
                chuva_96: chuva_96,
                chuva_30: chuva_30,
                lat: lat,
                lon: lon,
                situ: components[11],
                fonte: components[12]
            )
        }
    }
}

class EstacaoMetCeu { // Estações de Céu
    class func getEsta() async throws -> [EstacaoCeu] {
        // Condições do céu podem precisar de tradução
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/ceu_api")
        let lines = contents.components(separatedBy: .newlines)
        
        return lines.compactMap { line -> EstacaoCeu? in
            let components = line.components(separatedBy: ";")
            guard components.count >= 4 else { return nil }
            
            guard let lat = Double(components[1].replacingOccurrences(of: " ", with: "")),
                  let lon = Double(components[2].replacingOccurrences(of: " ", with: ""))
            else { return nil }
            
            return EstacaoCeu(
                nome: components[0],
                data: nil,
                ceu: components[3],
                lat: lat,
                lon: lon
            )
        }
    }
}

class Porenascer { // Nascer e Pôr do Sol
    class func getEsta() async throws -> [InfoTempoSol] {
        // Dados de horário, não precisam de tradução
        let contents = try await fetchContent(from: "https://aplicativo.cocr.com.br/sol_api", includeLanguage: false)
        let lines = contents.components(separatedBy: .newlines)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return lines.compactMap { line -> InfoTempoSol? in
            let components = line.components(separatedBy: ";")
            guard components.count >= 3 else { return nil }
            
            guard let nascer = dateFormatter.date(from: components[1]),
                  let por = dateFormatter.date(from: components[2])
            else { return nil }
            
            return InfoTempoSol(nascer: nascer, por: por)
        }
    }
}
