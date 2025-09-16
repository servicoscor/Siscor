//
//  Data.swift
//  BarraShopping
//
//  Created by Candido Bugarin on 16/07/17.
//  Copyright © 2017 Candido Bugarin. All rights reserved.
//

import Foundation

class Alertas {
    var nome: String = ""
    var data: String = ""
    var mensagem: String = ""
    var geo: String = ""
    var audio: String = ""
    var audiourl: String = ""
}

class Modal {
    var nome: String = ""
    var status: String = ""
    var mensagem: String = ""
}

class ComandoFiltro {
    var nome: String = ""
    var qt: String = ""
    var criti: String = ""
}

class NC {
    var situ: String = ""
}

class Interdicoes {
    var via: String = ""
    var status: String = ""
    var poli: String = ""
    var reg: String = ""
    var nor: String = ""
}

class Cameras {
    var id: String = ""
    var nome: String = ""
    var lat: Double = 0
    var lon: Double = 0
}

class Sirene {
    var nome: String = ""
    var status: String = ""
    var comunidade: String = ""
    var lat: Double = 0
    var lon: Double = 0
}

class Fotos {
    var nome: String = ""
}

class Recomenda {
    var nome: String = ""
}

class Estacao {
    var nome: String = ""
    var data: String = ""
    var municipio: String = ""
    var id: String = ""
    var chuva_i: Float = 0
    var chuva_1: Float = 0
    var chuva_4: Float = 0
    var chuva_24: Float = 0
    var chuva_96: Float = 0
    var chuva_30: Float = 0
    var lat: Double = 0
    var lon: Double = 0
    var situ: String = ""
    var fonte: String = ""
}

class EstacaoMeteCeu {
    var nome: String = ""
    var data: String = ""
    var ceu: String = ""
    var lat: Double = 0
    var lon: Double = 0
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


class Tempo {
    var nascer: Date = Date()
    var por: Date = Date()
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

class EstacaoNuvemMete {
    var nome: String = ""
    var data: String = ""
    var ceu: String = ""
    var lat: Double = 0
    var lon: Double = 0
}

class Comando {
    var nome: String = ""
    var local: String = ""
    var criti: String = ""
    var nome_e: String = ""
    var data: String = ""
    var id: String = ""
    var lat: Double = 0
    var lon: Double = 0
}


class PA {
    var nome: String = ""
    var endereco: String = ""
    var loc: String = ""
    var status: String = ""
    var lat: Double = 0
    var lon: Double = 0
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

class AlertaN {
    var estagio: String = ""
}

class UV {
    var valor: Double = 0
}

class TTG {
    var tt: String = ""
}

class TTT {
    var tt: String = ""
}

class TTA {
    var tt: String = ""
}

class KM {
    var tt: String = ""
}
