# GDM da Starlight OS Vega

O kit permanente fica em `assets/gdm/starlight-os-vega/`. Durante o build,
`scripts/build.sh` o copia para
`/opt/starlight-os/gdm/starlight-os-vega/` no chroot, excluindo
`login-reference.png` e `CODEX-PROMPT.md`. O primeiro é apenas um mockup e
nunca é usado pelo GDM.

O hook `hooks/0999-starlight-vega-gdm.hook.chroot` roda depois da instalação
dos pacotes. Ele chama o instalador e, obrigatoriamente, o validador. O
instalador extrai `/usr/share/gnome-shell/gnome-shell-theme.gresource`, valida
os seletores reais do GNOME Shell 48, aplica o bloco marcado nos stylesheets
dark, light e high-contrast, incorpora o PNG 3840×2160 e recompila o recurso.
Ele também extrai o gresource JavaScript embutido em
`/usr/lib/gnome-shell/libshell-16.so`, patcha o cálculo de alocação de
`/org/gnome/shell/gdm/loginDialog.js` e atualiza a seção ELF
`.gresource.shell_js_resources`. A substituição só ocorre depois de os novos
recursos serem listados com sucesso.
No Debian, `gresource` é fornecido por `libglib2.0-bin`, enquanto
`glib-compile-resources` é fornecido por `libglib2.0-dev-bin`; `objcopy` vem de
`binutils`. Todos são dependências explícitas da imagem.

O original é preservado em
`/usr/lib/starlight-os/backups/gnome-shell-theme.gresource.original`, e a
biblioteca original em `/usr/lib/starlight-os/backups/libshell-16.so.original`.
O bloco entre `STARLIGHT_OS_VEGA_GDM_BEGIN` e `STARLIGHT_OS_VEGA_GDM_END` é
removido antes de uma nova aplicação, tornando a operação idempotente.

O formulário permanece sendo o diálogo nativo e funcional do GDM. O seletor
`#lockDialogGroup` só aplica o fundo. O deslocamento real para a direita fica
no `loginDialog.js`, que posiciona tanto a seleção de usuário quanto o prompt
de senha com margem direita proporcional e mínimo de 48 px. O fundo é aplicado
tanto em `#lockDialogGroup` quanto em
`.screen-shield-background`, cobrindo a tela inicial do GDM e o diálogo de
autenticação. Os seletores foram confirmados no GNOME Shell 48.7 do Debian 13
Trixie.

O mesmo recurso é usado pelo GNOME Shell da sessão. Por isso, o override Vega
também deixa o painel superior azul-marinho, o dash da Visão Geral e o Dash to
Dock com superfície flutuante translúcida azul-marinho, gradiente vertical,
borda fria discreta e sombra. Os estados de foco, seleção e aplicações em
execução permanecem dourados. O bloco também cobre as superfícies nativas do
GNOME Shell: tela de desbloqueio, confirmação de desligar/reiniciar, prompts
de senha e polkit, diálogo de executar comando, seleção de áudio, OSDs,
switcher de janelas, ferramenta de screenshot e Looking Glass. Dash to Dock,
Blur my Shell e a extensão local `starlight-clock-right@starlightbrasil.com`
compõem os ajustes padrão da sessão.

No GDM, tanto a lista inicial de usuários quanto o prompt de senha recebem o
painel azul-marinho, bordas douradas discretas, avatar com aro dourado e
deslocamento relativo para a direita. O avatar e o nome exibidos vêm do
AccountsService configurado pelo usuário live e pelo módulo Calamares
`starlight-user-avatar` no sistema instalado, não de uma imagem de mockup.
O perfil dconf do GDM também define `logo` e `fallback-logo` para o asset
Starlight, substituindo o branding Debian específico da tela de login.

O Blur my Shell vem do pacote oficial Debian
`gnome-shell-extension-blur-my-shell` e é habilitado por padrão para o usuário
live (`blur-my-shell@aunetx`). O pacote Trixie 67-3 declara compatibilidade com
GNOME Shell 48 e não com o 49; uma atualização de GNOME que altere essa faixa
de compatibilidade fará o build falhar na resolução de pacotes, como deve ser.
O tom azul `#0e1f4b` com 5% de opacidade fica restrito ao pipeline
`pipeline_starlight_app_grid`, usado pelo fundo da visão de aplicativos. O
painel superior e o Dash to Dock permanecem nos pipelines sem tint para não
encobrir o degradê e a transparência definidos pelo tema Starlight.

O aplicativo oficial **Extensions** também é incluído pelo pacote
`gnome-shell-extension-prefs`, para que extensões instaladas possam ser vistas
e administradas pela interface padrão do GNOME.
O aplicativo **Tweaks** vem do pacote Debian `gnome-tweaks`, não de Flatpak,
para que o lançador `org.gnome.tweaks.desktop` e o ícone sejam registrados no
menu do GNOME durante a construção da imagem.
A extensão local **Starlight Clock Right** move o menu nativo de data, calendário
e notificações para o lado direito do painel superior, em estilo semelhante ao
macOS, sem substituir o menu original do GNOME.

O script recusa outro major do GNOME Shell e falha claramente se o recurso,
os seletores, os pacotes, a resolução ou a extração do CSS mudarem. Ao migrar
para outro GNOME, extraia novamente os stylesheets, adapte o CSS e atualize
`EXPECTED_GNOME_MAJOR` somente depois de testar o GDM em VM.

## Teste do GDM

`SOSD_LIVE_AUTOLOGIN` em `config/build.env` controla o login automático da
imagem live. A imagem de instalação usa `true`, para abrir a sessão `starlight`
sem senha. Para testar manualmente o GDM, altere temporariamente para `false`
e gere uma ISO descartável.

Para testar sem tocar no GDM do host, gere a ISO com `sudo make build` e rode
`make test`. Para teste manual com disco persistente, use 4 CPUs, 8 GiB de RAM
e um disco qcow2 de pelo menos 40 GiB no virt-manager.
