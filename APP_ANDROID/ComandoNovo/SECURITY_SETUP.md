# Configuração de Segurança do Projeto

## Arquivos Sensíveis Necessários (NÃO COMMITADOS)

Este projeto requer alguns arquivos sensíveis que **não estão** e **não devem ser** incluídos no controle de versão por motivos de segurança.

### 1. Google Services (Firebase)

**Arquivo**: `app/google-services.json`

- Copie `app/google-services.json.example` para `app/google-services.json`
- Obtenha o arquivo real do [Firebase Console](https://console.firebase.google.com/)
- Vá em: Configurações do Projeto > Seus Apps > Baixar google-services.json

### 2. Keystore de Produção

**Arquivo**: `app/iplanrio-production.keystore`

Este arquivo contém a chave de assinatura do aplicativo Android.

**Para desenvolvedores**:
- Use um keystore de debug durante o desenvolvimento
- Android Studio gera automaticamente um debug.keystore

**Para builds de produção**:
- Solicite o keystore de produção ao gerente do projeto
- **NUNCA** compartilhe este arquivo publicamente
- Armazene as senhas em um gerenciador de senhas seguro

#### Propriedades do Keystore

Você precisará configurar as seguintes variáveis em `local.properties` ou nas variáveis de ambiente do CI/CD:

```properties
# local.properties (NÃO commitar)
storeFile=app/iplanrio-production.keystore
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

### 3. Google Maps API Key

A chave da API do Google Maps está atualmente hardcoded no AndroidManifest.xml.

**Recomendação**: Migrar para BuildConfig ou local.properties

```xml
<!-- AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}" />
```

```gradle
// build.gradle.kts
android {
    defaultConfig {
        // Lê do local.properties
        val properties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            properties.load(localPropertiesFile.inputStream())
        }

        manifestPlaceholders["MAPS_API_KEY"] =
            properties.getProperty("MAPS_API_KEY", "")
    }
}
```

## Checklist de Configuração

- [ ] Copiar `google-services.json.example` → `google-services.json`
- [ ] Baixar `google-services.json` real do Firebase Console
- [ ] Configurar keystore (debug para dev, produção para release)
- [ ] Adicionar configurações do keystore em `local.properties`
- [ ] Migrar Google Maps API Key para local.properties (recomendado)
- [ ] Verificar que arquivos sensíveis estão em `.gitignore`

## Verificação

Execute este comando para garantir que nenhum arquivo sensível está sendo rastreado:

```bash
git ls-files | grep -E "(keystore|google-services\.json|\.jks|\.key)"
```

Se este comando retornar algum arquivo, **NÃO FAÇA COMMIT** e entre em contato com o gerente do projeto.

## Contato

Para obter acesso aos arquivos de configuração sensíveis, entre em contato com:
- Gerente do Projeto: [ADICIONAR CONTATO]
- Email: [ADICIONAR EMAIL]