import Foundation
import MapKit

class ComandoFiltro {
    var nome: String = ""
    var qt: String = ""
    var criti: String = ""
}

struct Estagio {
    let nivel: Int
    let descricao: String
}


struct Alerta: Identifiable {
    let id = UUID()
    var nome: String?
    var data: String?
    var mensagem: String?
    var geo: String?
    var audio: String?
    var audiourl: String?
}

class Fotos {
    var nome: String = ""
}

struct Evento: Identifiable, Codable {
    var id = UUID()
    var nome: String?
    var data: Date?
    var horaInicio: String?
    var horaEncerramento: String?
    var local: String?
    var zona: String?
    var quantidadePessoas: Int?
    var criticidade: String?
    var fonte: String?
    var lat: Double?
    var lon: Double?
    var importante: Bool?
    var imagemURL: String?
    var descricao: String?
    var categoria: String? // NOVO: Campo para categoria
    
    // Computed property para tipo baseado na categoria ou nome
    var tipo: TipoEvento {
        // Primeiro, tenta usar a categoria do JSON
        if let categoria = self.categoria {
            return TipoEvento(rawValue: categoria) ?? .outro
        }
        
        // Se não tiver categoria, usa a lógica de inferência pelo nome
        guard let nome = nome?.lowercased() else { return .outro }
        
        if nome.contains("corrida") || nome.contains("run") {
            return .esportivo
        } else if nome.contains("show") || nome.contains("música") || nome.contains("orquestra") || nome.contains("samba") {
            return .musical
        } else if nome.contains("festival") || nome.contains("festa") || nome.contains("arraiá") || nome.contains("são joão") {
            return .cultural
        } else if nome.contains("congresso") || nome.contains("feira") {
            return .educacional
        } else if nome.contains("gastro") || nome.contains("comida") {
            return .gastronomico
        }
        
        return .outro
    }
    
    // CodingKeys para mapear o JSON
    enum CodingKeys: String, CodingKey {
        case nome = "Nome do evento"
        case data = "Data"
        case horaInicio = "Hora de início"
        case horaEncerramento = "Hora de encerramento"
        case local = "Local"
        case zona = "Zona"
        case quantidadePessoas = "Quantidade de pessoas"
        case criticidade = "Criticidade"
        case fonte = "Fonte"
        case lat = "Latitude"
        case lon = "Longitude"
        case importante = "Importante"
        case imagemURL = "ImagemURL"
        case descricao = "Descricao"
        case categoria = "Categoria" // NOVO: Mapeamento para categoria
    }
    
    // Custom decoder para lidar com os tipos
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = UUID()
        self.nome = try container.decodeIfPresent(String.self, forKey: .nome)
        self.horaInicio = try container.decodeIfPresent(String.self, forKey: .horaInicio)
        self.horaEncerramento = try container.decodeIfPresent(String.self, forKey: .horaEncerramento)
        self.local = try container.decodeIfPresent(String.self, forKey: .local)
        self.zona = try container.decodeIfPresent(String.self, forKey: .zona)
        
        // CORREÇÃO: Parse de quantidade de pessoas (pode vir como String ou Int)
        if let quantidadeInt = try? container.decode(Int.self, forKey: .quantidadePessoas) {
            self.quantidadePessoas = quantidadeInt
        } else if let quantidadeString = try? container.decode(String.self, forKey: .quantidadePessoas),
                  let quantidade = Int(quantidadeString) {
            self.quantidadePessoas = quantidade
        } else {
            self.quantidadePessoas = nil
        }
        
        self.criticidade = try container.decodeIfPresent(String.self, forKey: .criticidade)
        self.fonte = try container.decodeIfPresent(String.self, forKey: .fonte)
        self.categoria = try container.decodeIfPresent(String.self, forKey: .categoria) // NOVO: Decodifica categoria
        
        // CORREÇÃO: Parse de importante (vem como "Sim"/"Não" string)
        if let importanteString = try? container.decode(String.self, forKey: .importante) {
            self.importante = (importanteString.lowercased() == "sim")
        } else if let importanteBool = try? container.decode(Bool.self, forKey: .importante) {
            self.importante = importanteBool
        } else {
            self.importante = false
        }
        
        // DEBUG: Verifica o valor bruto
        let imagemURLRaw = try container.decodeIfPresent(String.self, forKey: .imagemURL)
        print("🔍 DEBUG Decoder - imagemURL bruta: \(imagemURLRaw ?? "nil")")
        
        self.imagemURL = imagemURLRaw
        
        // Adiciona o domínio base se a URL não for completa
        if let imagemURL = self.imagemURL, !imagemURL.isEmpty, !imagemURL.hasPrefix("http") {
            self.imagemURL = "https://aplicativo.cocr.com.br\(imagemURL)"
            print("🔗 DEBUG Decoder - imagemURL após adicionar domínio: \(self.imagemURL!)")
        } else if let url = self.imagemURL {
            print("🔗 DEBUG Decoder - imagemURL já completa: \(url)")
        } else {
            print("⚠️ DEBUG Decoder - imagemURL é nil ou vazia")
        }
        
        self.descricao = try container.decodeIfPresent(String.self, forKey: .descricao)
        
        // DEBUG FINAL: Confirma o estado do objeto
        print("✅ DEBUG Decoder - Evento criado:")
        print("   - Nome: \(self.nome ?? "nil")")
        print("   - Importante: \(self.importante ?? false)")
        print("   - ImagemURL: \(self.imagemURL ?? "nil")")
        
        // Parse de data
        if let dataString = try container.decodeIfPresent(String.self, forKey: .data) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            self.data = formatter.date(from: dataString)
        } else {
            self.data = nil
        }
        
        // Parse de coordenadas
        if let latString = try container.decodeIfPresent(String.self, forKey: .lat),
           let lat = Double(latString) {
            self.lat = lat
        } else {
            self.lat = nil
        }
        
        if let lonString = try container.decodeIfPresent(String.self, forKey: .lon),
           let lon = Double(lonString) {
            self.lon = lon
        } else {
            self.lon = nil
        }
    }
    
    // Encoder não é necessário para nosso caso
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(nome, forKey: .nome)
        // ... adicionar outros campos se necessário
    }
}

class EventosCarnaval {
    var nome: String = ""
    var data_i: String = ""
    var data_f: String = ""
    var end: String = ""
    var link: String = ""
    var lat: Double = 0
    var lon: Double = 0
    
    var data_i_c: String = ""
    var data_f_c: String = ""
}

class PontosTur {
    var nome: String = ""
    var end: String = ""
    var lat: Double = 0
    var lon: Double = 0
    var programa: String = ""
    var texto: String = ""
}

class InterdicoesSite {
    var texto: String = ""
    var condicao: String = ""
}

class PontosCarnaval {
    var nome: String = ""
    var end: String = ""
    var lat: Double = 0
    var lon: Double = 0
}

class EstacaoMete {
    var nome: String = ""
    var fonte: String = ""
    var data: String = ""
    var tem_med: Float = 0
    var umd_med: Float = 0
    var vel_med: Float = 0
    var dir_med: String = ""
    var lat: Double = 0
    var lon: Double = 0
}

class Bairros {
    var nome: String = ""
}


// Usado para o Estágio Operacional
struct EstagioOperacional: Identifiable {
    let id = UUID()
    var estagio: String?
}

// Usado para Nível de Calor
struct NivelCalor: Identifiable {
    let id = UUID()
    var situacao: String?
}

// Usado para Câmeras no mapa
struct Camera: Identifiable, Hashable {
    let id = UUID()
    var apiId: String?
    var nome: String?
    var lat: Double?
    var lon: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // Essencial para o Set no CameraClusterManager
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: Camera, rhs: Camera) -> Bool {
        lhs.id == rhs.id
    }
}

// Usado para Sirenes no mapa
struct Sirene: Identifiable {
    let id = UUID()
    var nome: String?
    var status: String?
    var lat: Double?
    var lon: Double?
    var loc: String? // <-- PROPRIEDADE ADICIONADA PARA A COMUNIDADE

    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lon = lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// Usado para Pontos de Apoio e locais similares
struct PontoDeApoio: Identifiable {
    let id = UUID()
    var nome: String?
    var endereco: String?
    var loc: String?
    var status: String?
    var lat: Double?
    var lon: Double?
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lon = lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// Usado para informes de tempo nos cards
struct InformeTempo: Identifiable {
    let id = UUID()
    var texto: String?
}

// Usado para informes de trânsito nos cards
struct InformeTrânsito: Identifiable {
    let id = UUID()
    var texto: String?
}

// Usado para Recomendações
struct Recomendacao: Identifiable {
    let id = UUID()
    var nome: String?
}

// MARK: - Modelos de Dados para a Lógica de Fundo (Ex: Fundo Dinâmico)

// Usado para Estações de Chuva
struct EstacaoChuva: Identifiable {
    let id = UUID()
    var nome: String?
    var data: String?
    var municipio: String?
    var apiId: String? // Mantido do 'Estacao' original
    var chuva_i: Float?
    var chuva_1: Float?
    var chuva_4: Float?
    var chuva_24: Float?
    var chuva_96: Float?
    var chuva_30: Float?
    var lat: Double?
    var lon: Double?
    var situ: String?
    var fonte: String?
    
    var coordinate: CLLocationCoordinate2D? {
           // Garante que lat e lon não são nulos antes de criar a coordenada
           guard let lat, let lon else { return nil }
           return CLLocationCoordinate2D(latitude: lat, longitude: lon)
       }
}

// Usado para Estações Meteorológicas (Céu)
struct EstacaoCeu: Identifiable {
    let id = UUID()
    var nome: String?
    var data: String?
    var ceu: String?
    var lat: Double?
    var lon: Double?
}

// Usado para Previsão (Nascer e Pôr do Sol)
struct InfoTempoSol: Identifiable {
    let id = UUID()
    var nascer: Date?
    var por: Date?
}

// MARK: - Modelos de Dados Adicionais (Mantidos para uso futuro)

// Usado para Modais de Transporte
struct Modal: Identifiable {
    let id = UUID()
    var nome: String?
    var status: String?
    var mensagem: String?
}

// Usado para Interdições
struct Interdicao: Identifiable {
    let id = UUID()
    var via: String?
    var status: String?
    var poli: String?
    var reg: String?
    var nor: String?
}


struct Foto: Identifiable {
    let id = UUID()
    var nome: String?
}

struct EventoCarnaval: Identifiable {
    let id = UUID()
    var nome: String?
    var data_i: String?
    var data_f: String?
    var end: String?
    var link: String?
    var lat: Double?
    var lon: Double?
    var data_i_c: String?
    var data_f_c: String?
}



struct InterdicaoSite: Identifiable {
    let id = UUID()
    var texto: String?
    var condicao: String?
}

struct PontoTuristico {
    let id: String
    let nome: LocalizedText
    let categoria: CategoriaPonto
    let texto: LocalizedText
    let endereco: String
    let telefone: String?
    let website: String?
    let coordenadas: CLLocationCoordinate2D?
    let avaliacao: Double?
}

struct PontoCarnaval: Identifiable {
    let id = UUID()
    var nome: String?
    var end: String?
    var lat: Double?
    var lon: Double?
}

struct EstacaoMeteorologica: Identifiable {
    let id = UUID()
    var nome: String?
    var fonte: String?
    var data: String?
    var tem_med: Float?
    var umd_med: Float?
    var vel_med: Float?
    var dir_med: String?
    var lat: Double?
    var lon: Double?
    
    var coordinate: CLLocationCoordinate2D? {
           guard let lat, let lon else { return nil }
           return CLLocationCoordinate2D(latitude: lat, longitude: lon)
       }
}

struct Bairro: Identifiable {
    let id = UUID()
    var nome: String?
}

struct EstacaoNuvemMete: Identifiable {
    let id = UUID()
    var nome: String?
    var data: String?
    var ceu: String?
    var lat: Double?
    var lon: Double?
}

struct Comando: Identifiable {
    let id = UUID() // UUID para SwiftUI
    var apiId: String? // ID vindo da API
    var nome: String?
    var local: String?
    var criti: String?
    var nome_e: String?
    var data: String?
    var lat: Double?
    var lon: Double?
}

struct PontoCritico: Identifiable {
    let id = UUID()
    var nome: String?
    var endereco: String?
    var dir: String?
    var lat: Double?
    var lon: Double?
}

struct Rota: Identifiable {
    let id = UUID()
    var nome: String?
    var endereco: String?
    var data: String?
    var tempo: String?
}

struct PrevisaoGeral: Identifiable {
    let id = UUID()
    var prev: String?
    var prev3: String?
    var img: String?
}

struct Aviso: Identifiable {
    let id = UUID()
    var nome: String?
    var text: String?
    var caus: String?
    var risc: String?
}

struct IndiceUV: Identifiable {
    let id = UUID()
    var valor: Double?
}

struct TextoGenerico: Identifiable {
    let id = UUID()
    var tt: String?
}

class PC {
    var nome: String = ""
    var endereco: String = ""
    var dir: String = ""
    var lat: Double = 0
    var lon: Double = 0
}

class Rotas {
    var nome: String = ""
    var endereco: String = ""
    var data: String = ""
    var tempo: String = ""
}

class Prev {
    var prev: String = ""
    var prev3: String = ""
    var img: String = ""
}

class Avisos {
    var nome: String = ""
    var text: String = ""
    var caus: String = ""
    var risc: String = ""
}

class UV {
    var valor: Double = 0
}

class TTG {
    var tt: String = ""
}

class KM {
    var tt: String = ""
}
