//
//  AlertasCardView.swift
//  Comando
//
//  Created by Candido Bugarin on 09/06/25.
//  Copyright © 2025 Candido Bugarin. All rights reserved.
//


struct AlertasCardView: View {
    let alertas: [Alerta]
    let isLoading: Bool
    
    // NOVO: Estado para controlar qual alerta está selecionado para ver os detalhes
    @State private var alertaSelecionado: Alerta?
    // NOVO: Estado para controlar a animação de entrada
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabeçalho
            HStack {
                Image(systemName: "bell.badge.fill").foregroundColor(.yellow) // Ícone mais sugestivo
                Text("Alertas").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12).padding(.horizontal)
            
            // Lógica de Loading / Vazio
            if isLoading {
                BrandedLoadingView().frame(height: 150)
            } else if alertas.isEmpty {
                EmptyStateView(icon: "checkmark.circle", message: "Nenhum alerta no momento")
            } else {
                // Lista de Alertas
                VStack(spacing: 12) {
                    // Usamos .enumerated() para pegar o índice para a animação
                    ForEach(Array(alertas.enumerated()), id: \.element.id) { index, alerta in
                        AlertaRow(alerta: alerta)
                            .onTapGesture {
                                // Ao tocar, define o alerta selecionado para abrir a sheet
                                alertaSelecionado = alerta
                            }
                            // MUDANÇA: Animação de entrada com delay
                            .opacity(isVisible ? 1 : 0)
                            .offset(x: isVisible ? 0 : -20)
                            .animation(.easeOut.delay(Double(index) * 0.1), value: isVisible)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(cardGradient)
        .cornerRadius(12)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
        // MUDANÇA: Apresenta a view de detalhes quando um alerta é selecionado
        .sheet(item: $alertaSelecionado) { alerta in
            AlertaDetalhesView(alerta: alerta)
        }
        .onAppear {
            // Ativa a animação de entrada quando a view aparece
            isVisible = true
        }
    }
}

//====================================================================//
// MARK: - Linha de Alerta (Repaginada)
//====================================================================//
struct AlertaRow: View {
    let alerta: Alerta

    var body: some View {
        HStack(spacing: 15) {
            // Ícone contextual
            Image(systemName: iconFor(alerta: alerta))
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 30)

            // Título e Data
            VStack(alignment: .leading, spacing: 2) {
                Text(alerta.nome ?? "Alerta sem título")
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2) // Limita a duas linhas para não quebrar o layout
                
                if let data = alerta.data {
                    Text(data)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.5))
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Função auxiliar para escolher um ícone
    private func iconFor(alerta: Alerta) -> String {
        let texto = (alerta.nome ?? "").lowercased()
        if texto.contains("chuva") { return "cloud.rain.fill" }
        if texto.contains("vento") { return "wind" }
        if texto.contains("trânsito") || texto.contains("via") { return "car.fill" }
        if texto.contains("sirene") { return "bell.fill" }
        return "exclamationmark.triangle.fill" // Padrão
    }
}


//====================================================================//
// MARK: - View de Detalhes do Alerta (NOVA)
//====================================================================//
struct AlertaDetalhesView: View {
    let alerta: Alerta
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho da Sheet
            VStack(spacing: 4) {
                Capsule().fill(Color.gray.opacity(0.5)).frame(width: 40, height: 5)
                Text(alerta.nome ?? "Detalhes do Alerta")
                    .font(.headline)
                    .padding(.top, 8)
            }
            .padding()
            
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    infoRow(icon: "text.bubble.fill", title: "Mensagem", value: alerta.mensagem)
                    infoRow(icon: "calendar", title: "Data", value: alerta.data)
                    infoRow(icon: "mappin.and.ellipse", title: "Geolocalização", value: alerta.geo)
                    
                    // Player de áudio, só aparece se houver uma URL de áudio
                    if let audioURLString = alerta.audiourl, let url = URL(string: audioURLString) {
                        Divider()
                        audioPlayer(url: url)
                    }
                }
                .padding()
            }
        }
    }
    
    // View auxiliar para as linhas de informação
    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String?) -> some View {
        if let value = value, !value.isEmpty {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: icon).foregroundColor(.accentColor)
                    Text(title).font(.caption.bold()).foregroundColor(.secondary)
                }
                Text(value).padding(.top, 2)
            }
        }
    }
    
    // View auxiliar para o player de áudio
    private func audioPlayer(url: URL) -> some View {
        HStack {
            Text("Áudio do Alerta")
            Spacer()
            Button(action: toggleAudioPlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            // Configura o player de áudio
            let playerItem = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: playerItem)
        }
    }
    
    private func toggleAudioPlayback() {
        guard let player = player else { return }
        isPlaying.toggle()
        if isPlaying {
            player.seek(to: .zero) // Reinicia o áudio
            player.play()
        } else {
            player.pause()
        }
    }
}