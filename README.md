# DataControl Solutions — Client Intake (GitHub + Supabase)

Formulário de intake trilíngue (PT/EN/ES), com criação de conta, verificação por código de e‑mail, salvamento automático e upload de documentos. Tudo no plano **gratuito** do Supabase + hospedagem grátis no GitHub Pages.

## Arquivos

```
datacontrol-intake/
├─ index.html              ← o formulário (cole aqui suas 2 chaves do Supabase)
├─ README.md               ← este guia
└─ supabase/
   └─ schema.sql           ← rode no SQL Editor do Supabase (cria tabela, RLS e Storage)
```

> Enquanto você não colar as chaves, o `index.html` funciona em **modo demonstração**: mostra o código de verificação na própria tela (não envia e‑mail) e não salva nada. Serve para testar o fluxo localmente.

---

## Passo a passo

### 1) Supabase — banco de dados e Storage
1. Acesse o painel do Supabase e abra seu projeto (ou crie um novo, plano Free).
2. Menu **SQL Editor → New query**.
3. Cole todo o conteúdo de `supabase/schema.sql` e clique **Run**.
4. Confirme: em **Table Editor** deve aparecer a tabela `intakes`; em **Storage** deve aparecer o bucket `documents` (privado).

### 2) Supabase — autenticação por código de 6 dígitos
1. **Authentication → Providers → Email**: deixe habilitado e mantenha **"Confirm email" LIGADO**.
2. **Authentication → Email Templates → Confirm signup**: substitua o corpo por algo que contenha a variável `{{ .Token }}` (é isso que troca o link mágico por um **código de 6 dígitos**). Exemplo:

   ```html
   <h2>Confirme sua conta — DataControl Solutions</h2>
   <p>Seu código de verificação é:</p>
   <p style="font-size:28px;font-weight:bold;letter-spacing:6px">{{ .Token }}</p>
   <p>Digite este código no formulário para ativar sua conta. Ele expira em 1 hora.</p>
   ```
   Clique **Save**.
3. **Authentication → URL Configuration → Site URL**: por enquanto pode deixar em branco; você volta aqui no passo 5 para colocar o endereço do site publicado.

### 3) Pegar as chaves do projeto
1. **Project Settings → API**.
2. Copie **Project URL** (ex.: `https://abcdxyz.supabase.co`) e a chave **anon / public**.
3. Abra `index.html`, procure o bloco `SUPABASE CONFIG` (perto do início do `<script>`) e cole:
   ```js
   const SUPABASE_URL = 'https://SEU_PROJETO.supabase.co';
   const SUPABASE_ANON_KEY = 'sua_chave_anon_publica';
   ```
   > A chave **anon** pode ficar visível no código — é assim mesmo. Quem protege os dados é o **RLS** (cada usuário só acessa o que é dele). **Nunca** use a chave `service_role` aqui.

### 4) GitHub — subir o código
Pela interface do GitHub (sem terminal):
1. Crie um repositório novo (ex.: `datacontrol-intake`).
2. **Add file → Upload files**, arraste `index.html`, `README.md` e a pasta `supabase/`, e confirme o commit.

Ou pelo terminal:
```bash
cd datacontrol-intake
git init && git add . && git commit -m "Client intake + Supabase"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/datacontrol-intake.git
git push -u origin main
```

### 5) Publicar (GitHub Pages — grátis)
1. No repositório: **Settings → Pages**.
2. Em **Source**, escolha **Deploy from a branch**; selecione branch `main` e pasta `/ (root)`. Salve.
3. Aguarde ~1 min. O endereço aparece no topo da página, no formato:
   `https://SEU_USUARIO.github.io/datacontrol-intake/`
4. Volte ao Supabase (**Authentication → URL Configuration**) e coloque esse endereço em **Site URL** (e em **Redirect URLs**, se houver). Salve.

> O GitHub Pages gratuito exige repositório **público**. Se preferir manter o código privado e ainda assim publicar de graça, use **Cloudflare Pages** ou **Netlify** (conectam ao repositório privado sem custo). O passo do Supabase (Site URL) é o mesmo.

### 6) Testar de ponta a ponta
1. Abra a URL publicada.
2. Crie a conta (nome, e‑mail, telefone, senha) → você recebe um **código por e‑mail** → digite na tela de verificação.
3. Preencha o questionário e envie.
4. No Supabase: **Table Editor → intakes** deve ter a linha com `answers` (JSON) e `status = submitted`; **Storage → documents** deve ter os arquivos enviados, dentro de uma pasta com o ID do usuário.
5. Feche e reabra o site logado: ele **retoma de onde parou** (salvar e continuar).

---

## Recomendado (mas opcional): e‑mail confiável com Resend (grátis)
O envio de e‑mail nativo do Supabase tem limite baixo e pode atrasar/falhar em uso real. Para confiabilidade, configure um SMTP gratuito:
1. Crie conta no **Resend** (plano grátis: ~3.000 e‑mails/mês) e gere as credenciais SMTP.
2. No Supabase: **Project Settings → Authentication → SMTP Settings → Enable Custom SMTP** e preencha host/porta/usuário/senha do Resend, além do remetente.
3. Para enviar para qualquer destinatário, é preciso **verificar um domínio** no Resend (exige ter um domínio).

---

## Limites do plano gratuito (para um protótipo, suficiente)
- Banco 500 MB, Storage 1 GB, 50.000 usuários/mês.
- **Sem backups automáticos.**
- **O projeto é pausado após ~1 semana sem uso** — basta abrir o painel para reativar (ou configurar um ping gratuito, ex.: UptimeRobot).

## Segurança e privacidade
- Como o formulário coleta dados sensíveis (passaporte, endereço, dados financeiros e de imigração), tenha uma **Política de Privacidade** e **Termos** reais (LGPD/GDPR). O checkbox de consentimento já existe no formulário; o texto legal precisa existir de fato.
- Acesso da equipe interna (Master Intake): no começo, use o próprio painel do Supabase (Table Editor / Storage). Depois dá para criar uma tela de administração protegida.

## Solução de problemas
- **Não chega o código por e‑mail:** confirme que o template "Confirm signup" usa `{{ .Token }}` e que "Confirm email" está ligado; verifique spam; considere o SMTP do Resend.
- **"Invalid login / código incorreto":** o código expira (1 h) — use **Reenviar código**.
- **Upload falha / linha não salva:** verifique se o `schema.sql` rodou sem erros (tabela `intakes` + bucket `documents` + policies) e se as chaves no `index.html` são as do mesmo projeto.
- **Página não publica:** no GitHub Pages, o repositório precisa ser público (ou use Cloudflare Pages/Netlify).
