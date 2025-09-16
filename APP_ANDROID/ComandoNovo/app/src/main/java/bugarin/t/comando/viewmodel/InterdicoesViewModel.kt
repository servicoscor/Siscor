package bugarin.t.comando.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import bugarin.t.comando.data.CORRepository
import bugarin.t.comando.data.Interdicao
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

// ✅ ARQUITETURA: O estado da UI agora vive junto com seu ViewModel.
data class InterdicoesUiState(
    val isLoading: Boolean = false,
    val interdicoes: List<Interdicao> = emptyList(),
    val error: String? = null
)

@HiltViewModel
class InterdicoesViewModel @Inject constructor(
    private val repository: CORRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(InterdicoesUiState())
    val uiState: StateFlow<InterdicoesUiState> = _uiState.asStateFlow()

    fun loadInterdicoes() {
        if (_uiState.value.isLoading) return // Evita carregamentos múltiplos

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                val fetchedInterdicoes = repository.getInterdicoes()
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        // Filtra itens vazios na camada de dados, não na UI.
                        interdicoes = fetchedInterdicoes.filter { interdicao ->
                            !interdicao.via.isNullOrBlank() || !interdicao.nor.isNullOrBlank()
                        }
                    )
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }
}