// No novo ficheiro: bugarin/t/comando/ui/utils/Mappers.kt
package bugarin.t.comando.ui.utils

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import bugarin.t.comando.data.TipoEvento

// A lógica de UI (ícones e cores) agora vive na camada de UI.

val TipoEvento.icon: ImageVector
    get() = when (this) {
        TipoEvento.CONGRESSO, TipoEvento.G20, TipoEvento.CORPORATIVO -> Icons.Default.Business
        TipoEvento.CULTURAL -> Icons.Default.TheaterComedy
        TipoEvento.ESPORTIVO -> Icons.Default.SportsSoccer
        TipoEvento.FEIRA -> Icons.Default.Storefront
        TipoEvento.MUSICAL -> Icons.Default.MusicNote
        TipoEvento.MANIFESTACAO -> Icons.Default.Campaign
        TipoEvento.RELIGIOSO -> Icons.Default.Church
        TipoEvento.REVEILLON -> Icons.Default.Celebration
        TipoEvento.CARNAVAL_BAIRRO, TipoEvento.CARNAVAL_DESFILES, TipoEvento.CARNAVAL_ENSAIOS, TipoEvento.CARNAVAL_BLOCOS, TipoEvento.CARNAVAL_PALCOS, TipoEvento.BLOCOS_NAO_OFICIAIS -> Icons.Default.Festival // Ícone mais adequado
        TipoEvento.SIMULADO -> Icons.Default.Description
        TipoEvento.ACADEMICOS, TipoEvento.EDUCACIONAL -> Icons.Default.School
        TipoEvento.POLITICO -> Icons.Default.Gavel
        TipoEvento.GASTRONOMICO -> Icons.Default.Restaurant
        TipoEvento.OUTRO -> Icons.Default.Star
    }

val TipoEvento.color: Color
    get() = when (this) {
        TipoEvento.CONGRESSO, TipoEvento.G20, TipoEvento.CORPORATIVO -> Color(0xFF4A148C) // Roxo Escuro
        TipoEvento.CULTURAL -> Color(0xFFC2185B) // Rosa
        TipoEvento.ESPORTIVO -> Color(0xFF388E3C) // Verde
        TipoEvento.FEIRA -> Color(0xFF00796B) // Teal
        TipoEvento.MUSICAL -> Color(0xFFF57C00) // Laranja
        TipoEvento.MANIFESTACAO -> Color(0xFFFFEB3B) // Amarelo
        TipoEvento.RELIGIOSO -> Color(0xFFB2EBF2) // Ciano Claro
        TipoEvento.REVEILLON -> Color(0xFF03A9F4) // Azul Claro
        TipoEvento.CARNAVAL_BAIRRO, TipoEvento.CARNAVAL_DESFILES, TipoEvento.CARNAVAL_ENSAIOS, TipoEvento.CARNAVAL_BLOCOS, TipoEvento.CARNAVAL_PALCOS, TipoEvento.BLOCOS_NAO_OFICIAIS -> Color(0xFF7B1FA2) // Roxo
        TipoEvento.SIMULADO -> Color(0xFF6D4C41) // Marrom
        TipoEvento.ACADEMICOS, TipoEvento.EDUCACIONAL -> Color(0xFF1976D2) // Azul
        TipoEvento.POLITICO -> Color(0xFF2E7D32) // Verde Escuro
        TipoEvento.GASTRONOMICO -> Color(0xFFD32F2F) // Vermelho
        TipoEvento.OUTRO -> Color.Gray
    }