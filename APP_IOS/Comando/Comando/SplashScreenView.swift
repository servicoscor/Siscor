import SwiftUI

struct SplashScreenView: View {
    // 1. Acessa o ViewModel que foi injetado no ambiente.
    @EnvironmentObject var viewModel: CORViewModel
    
    // Estados para controlar a animação sequencial
    @State private var imageOpacity = 0.0
    @State private var loadingOpacity = 0.0
    
    var body: some View {
        ZStack {
            // Cor de fundo da sua splash screen.
            Color(red: 0.05, green: 0.1, blue: 0.15)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Imagem/Logo com animação
                Image("logocordeitado") // Substitua "logo" pelo nome da sua imagem
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 90)
                    .opacity(imageOpacity)
                
                // Sua animação de loading
                BrandedLoadingView()
                    .opacity(loadingOpacity)
            }
        }
        // 2. Quando a view aparecer, chama a função para buscar os dados.
        .onAppear {
            // Primeiro aparece a imagem
            withAnimation(.easeIn(duration: 0.8)) {
                imageOpacity = 1.0
            }
            
            // Depois aparece o loading (com delay de 0.5s)
            withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
                loadingOpacity = 1.0
            }
            
            Task {
                await viewModel.fetchData()
            }
        }
    }
}
