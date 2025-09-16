package bugarin.t.comando.data

/**
 * Classe selada para representar resultados de operações de rede
 */
sealed class NetworkResult<out T> {
    data class Success<T>(val data: T) : NetworkResult<T>()
    data class Error(val message: String) : NetworkResult<Nothing>()
    object Loading : NetworkResult<Nothing>()
}

/**
 * Extension functions para facilitar o uso
 */
fun <T> NetworkResult<T>.isSuccess() = this is NetworkResult.Success
fun <T> NetworkResult<T>.isError() = this is NetworkResult.Error
fun <T> NetworkResult<T>.isLoading() = this is NetworkResult.Loading

fun <T> NetworkResult<T>.onSuccess(action: (value: T) -> Unit): NetworkResult<T> {
    if (this is NetworkResult.Success) {
        action(data)
    }
    return this
}

fun <T> NetworkResult<T>.onError(action: (message: String) -> Unit): NetworkResult<T> {
    if (this is NetworkResult.Error) {
        action(message)
    }
    return this
}

fun <T> NetworkResult<T>.onLoading(action: () -> Unit): NetworkResult<T> {
    if (this is NetworkResult.Loading) {
        action()
    }
    return this
}

/**
 * Funções utilitárias adicionais
 */
fun <T> NetworkResult<T>.getOrNull(): T? {
    return when (this) {
        is NetworkResult.Success -> data
        else -> null
    }
}

fun <T> NetworkResult<T>.getOrDefault(default: T): T {
    return when (this) {
        is NetworkResult.Success -> data
        else -> default
    }
}

fun <T, R> NetworkResult<T>.map(transform: (T) -> R): NetworkResult<R> {
    return when (this) {
        is NetworkResult.Success -> NetworkResult.Success(transform(data))
        is NetworkResult.Error -> NetworkResult.Error(message)
        is NetworkResult.Loading -> NetworkResult.Loading
    }
}

fun <T> NetworkResult<T>.fold(
    onSuccess: (T) -> Unit,
    onError: (String) -> Unit,
    onLoading: () -> Unit
) {
    when (this) {
        is NetworkResult.Success -> onSuccess(data)
        is NetworkResult.Error -> onError(message)
        is NetworkResult.Loading -> onLoading()
    }
}