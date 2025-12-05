# Guia: Preparar Repositório para GitHub

## ⚠️ ATENÇÃO: ARQUIVOS SENSÍVEIS DETECTADOS

Este repositório contém arquivos sensíveis que **NÃO PODEM** ser publicados:
- Keystores de assinatura do app
- Configurações do Firebase (google-services.json)
- API Keys hardcoded

## Passo 1: Remover Arquivos Sensíveis do Índice Git

Execute os seguintes comandos para remover os arquivos sensíveis do controle de versão (mas mantê-los localmente):

```bash
# Remover arquivos sensíveis do índice Git
git rm --cached app/google-services.json
git rm --cached app/iplanrio-production.keystore
git rm --cached app/src/main/java/bugarin/t/comando/google-services.json
git rm --cached app/src/main/java/bugarin/t/comando/iplanrio-production.keystore

# Remover arquivos temporários e de build
git rm --cached build_log.txt 2>/dev/null || true
git rm --cached -r "app/build 2/" 2>/dev/null || true

# Remover .DS_Store files (se existirem)
find . -name .DS_Store -print0 | xargs -0 git rm --cached 2>/dev/null || true
```

## Passo 2: Limpar Histórico Git (OPCIONAL mas RECOMENDADO)

⚠️ **AVISO**: Estes comandos reescrevem o histórico do Git. Use com cuidado!

### Opção A: Usar BFG Repo-Cleaner (Recomendado - Mais Rápido)

```bash
# Instalar BFG (macOS)
brew install bfg

# Fazer backup do repositório
cd ..
cp -r ComandoNovo ComandoNovo_backup

# Limpar arquivos sensíveis do histórico
cd ComandoNovo
bfg --delete-files google-services.json
bfg --delete-files "*.keystore"
bfg --delete-files "*.jks"

# Limpar e compactar
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### Opção B: Usar git filter-branch (Método Manual)

```bash
# Fazer backup primeiro!
cd ..
cp -r ComandoNovo ComandoNovo_backup
cd ComandoNovo

# Remover arquivos do histórico
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch \
    app/google-services.json \
    app/iplanrio-production.keystore \
    app/src/main/java/bugarin/t/comando/google-services.json \
    app/src/main/java/bugarin/t/comando/iplanrio-production.keystore \
    app/*.keystore \
    app/*.jks' \
  --prune-empty --tag-name-filter cat -- --all

# Limpar referências
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## Passo 3: Verificar Limpeza

```bash
# Verificar que nenhum arquivo sensível está sendo rastreado
git ls-files | grep -E "(keystore|google-services\.json|\.jks|\.key)"

# Se o comando acima retornar algo, os arquivos ainda estão sendo rastreados!
# Não prossiga até que o comando não retorne nada.

# Verificar status
git status
```

## Passo 4: Commit das Mudanças de Segurança

```bash
git add .gitignore
git add app/google-services.json.example
git add SECURITY_SETUP.md
git add PREPARAR_REPO.md
git commit -m "chore: melhorar .gitignore e adicionar guias de segurança

- Adicionar regras abrangentes ao .gitignore
- Criar template google-services.json.example
- Adicionar documentação SECURITY_SETUP.md
- Remover arquivos sensíveis do controle de versão"
```

## Passo 5: Criar Novo Repositório no GitHub

### 5a. Criar no GitHub:
1. Acesse https://github.com/new
2. Nome do repositório: `comando-android` (ou o nome desejado)
3. **NÃO** inicialize com README, .gitignore ou license
4. Visibilidade: Private (RECOMENDADO) ou Public
5. Clique em "Create repository"

### 5b. Conectar ao Novo Repositório:

```bash
# Remover remote antigo (se necessário)
git remote remove origin

# Adicionar novo remote
git remote add origin https://github.com/SEU_USERNAME/NOME_DO_REPO.git

# Ou com SSH:
# git remote add origin git@github.com:SEU_USERNAME/NOME_DO_REPO.git

# Verificar remote
git remote -v

# Push para o novo repositório
git push -u origin main

# Se o histórico foi reescrito, você precisará forçar o push:
# git push -u origin main --force
```

## Passo 6: Rotacionar Credenciais Expostas

🔒 **IMPORTANTE**: Como as credenciais já foram commitadas, é recomendado rotacioná-las:

### Google Maps API Key
1. Acesse [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Desabilite a chave atual: `AIzaSyBZD9s_erb3Dss20AdVLQvqkc_b4F9gloU`
3. Crie uma nova chave
4. Configure restrições adequadas
5. Atualize em `local.properties` ou use BuildConfig

### Firebase (google-services.json)
1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Considere rotacionar credenciais sensíveis
3. Configure regras de segurança adequadas

### Keystore
Se o keystore foi publicado em repositório público:
1. **CRÍTICO**: Gere um novo keystore
2. Publique uma nova versão do app
3. O keystore antigo pode ser usado para publicar apps maliciosos

## Passo 7: Configurar Proteções no GitHub

No novo repositório, configure:

### Branch Protection (Settings → Branches):
- [ ] Require pull request reviews
- [ ] Require status checks to pass
- [ ] Require conversation resolution
- [ ] Require signed commits (recomendado)

### Secret Scanning (Settings → Security):
- [ ] Habilitar "Secret scanning"
- [ ] Habilitar "Push protection"

### .github/CODEOWNERS (opcional):
```
# Arquivo CODEOWNERS
* @SEU_USERNAME
/app/build.gradle.kts @SEU_USERNAME
```

## Checklist Final

Antes de considerar o repositório pronto:

- [ ] `.gitignore` atualizado e commitado
- [ ] Arquivos sensíveis removidos do índice (`git rm --cached`)
- [ ] Histórico limpo (opcional mas recomendado)
- [ ] Verificação executada (nenhum arquivo sensível rastreado)
- [ ] `google-services.json.example` criado
- [ ] `SECURITY_SETUP.md` criado
- [ ] Novo repositório GitHub criado
- [ ] Remote configurado
- [ ] Push realizado com sucesso
- [ ] Credenciais rotacionadas (API Keys, Firebase, etc)
- [ ] Branch protection configurada
- [ ] Secret scanning habilitado
- [ ] README.md criado (opcional)

## Solução de Problemas

### "The following untracked working tree files would be overwritten"
```bash
# Remover arquivos temporários
rm -rf app/build\ 2/
rm build_log.txt
```

### "Updates were rejected because the tip of your current branch is behind"
```bash
# Se você limpou o histórico e tem certeza do que está fazendo:
git push -u origin main --force
```

### "Permission denied (publickey)"
```bash
# Configure SSH ou use HTTPS com token
gh auth login  # Se tiver GitHub CLI instalado
```

## Recursos Adicionais

- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [Git Filter-Branch](https://git-scm.com/docs/git-filter-branch)

---

**Dúvidas?** Consulte a documentação ou entre em contato com a equipe.