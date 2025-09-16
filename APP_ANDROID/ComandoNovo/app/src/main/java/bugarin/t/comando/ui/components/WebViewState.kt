package bugarin.t.comando.ui.components

sealed class WebViewState2 {
    object Loading : WebViewState()
    object Success : WebViewState()
    object Error : WebViewState()
}