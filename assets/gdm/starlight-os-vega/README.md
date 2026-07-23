# Starlight OS Vega — kit de login GDM

Este kit foi preparado como integração **de build da distribuição**, não como
um tema comum instalado pelo usuário.

## Alvo

- Debian 13 (Trixie)
- GNOME Shell 48 / GDM
- Tela 16:9, asset 3840×2160
- Formulário deslocado para a direita via patch do `loginDialog.js`

## Estrutura

- `assets/starlight-os-vega-4k.png`: fundo real usado pelo GDM.
- `assets/login-reference.png`: referência visual; não deve ser usada como fundo.
- `assets/starlight-os-vega-gdm.css`: override visual do GDM, lock screen,
  diálogos nativos do GNOME Shell, OSDs, switchers e dock.
- `scripts/install-gdm-theme.sh`: extrai, altera e recompila o gresource.
- `scripts/validate-gdm-theme.sh`: valida o resultado após a instalação.
- `scripts/0999-starlight-vega-gdm.hook.chroot`: exemplo para live-build.
- `CODEX-PROMPT.md`: instrução pronta para o Codex integrar ao projeto.

## Integração no live-build

1. Copie este diretório para:
   `/opt/starlight-os/gdm/starlight-os-vega/` dentro do chroot.
2. Neste projeto live-build 3, o hook versionado é:
   `hooks/0999-starlight-vega-gdm.hook.chroot`.
3. Garanta no build:
   `libglib2.0-bin`, `libglib2.0-dev-bin`, `python3`, `gnome-shell`, `gdm3`.
4. Execute a compilação da imagem.
5. Teste o ISO em VM antes de hardware real.

## Observações importantes

O GDM não oferece uma API estável para trocar integralmente o layout. Ele usa
os recursos compilados do GNOME Shell. Por isso o instalador:

- localiza o gresource real do sistema;
- localiza o gresource JavaScript embutido em `libshell-16.so`;
- cria backup;
- valida o seletor `.login-dialog`;
- falha em vez de aplicar silenciosamente algo incompatível;
- recompila o resource com o wallpaper e o CSS;
- atualiza a alocação nativa do GDM para a coluna direita.

O CSS controla o visual. O posicionamento horizontal é feito no
`/org/gnome/shell/gdm/loginDialog.js` embutido no GNOME Shell, porque esse
arquivo centraliza a seleção de usuário e o prompt de senha por alocação
manual. A margem direita usada pelo patch é proporcional à largura da tela,
com mínimo de 48 px.

Não use uma imagem que já contenha campos, relógio ou botões desenhados. O
arquivo `login-reference.png` é apenas mockup. O GDM renderiza os controles
funcionais sobre `starlight-os-vega-4k.png`.
