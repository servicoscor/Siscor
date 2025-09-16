import SwiftUI
import MapKit

struct StatusPrincipalView: View {
    // ✅ CORREÇÃO: Recebe o viewModel partilhado do ambiente, em vez de criar um novo.
    @EnvironmentObject private var viewModel: CORViewModel
    
    var body: some View {
        // A StatusAlertaView agora receberá os dados do viewModel partilhado.
        StatusAlertaView(
            eventos: viewModel.eventos,
            alertas: viewModel.alertas,
            infoTempo: viewModel.infoTempo,
            infoTransito: viewModel.infoTransito,
            cameras: viewModel.cameras,
            sirenes: viewModel.sirenes,
            nomeImagemFundo: viewModel.nomeImagemFundo,
            pontosDeApoio: viewModel.pontosDeApoio,
            unidadesDeSaude: viewModel.unidadesDeSaude,
            pontosDeResfriamento: viewModel.pontosDeResfriamento,
            nivelCalor: viewModel.nivelCalor ?? NivelCalor(),
            recomendacoes: viewModel.recomendacoes,
            estagioOperacional: viewModel.estagioOperacional
        )
        // A chamada .onAppear foi removida daqui porque o CORRioApp já
        // trata do carregamento inicial dos dados de uma forma mais controlada.
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Para a preview funcionar, precisamos injetar todos os environment objects necessários
        StatusPrincipalView()
            .environmentObject(CORViewModel())
            .environmentObject(FavoritesManager.shared)
            .environmentObject(LocalizationManager.shared)
    }
}
