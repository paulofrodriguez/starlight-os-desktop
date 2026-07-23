# Diferenciais do Starlight OS Vega sobre Debian 13

Este documento descreve o que a imagem Starlight OS Vega adiciona, configura
ou remove em relacao a uma instalacao Debian 13 (`trixie`) amd64 convencional.
O inventario tem como fonte as listas de pacotes, overlays e hooks deste
repositorio. Nao deve ser interpretado como uma lista de todos os pacotes que
o Debian fornece.

## Base e principio de construcao

- Base: Debian 13 (`trixie`), arquitetura amd64, com `main`, `contrib`,
  `non-free` e `non-free-firmware` habilitados.
- Imagem live e ISO reproduzivel, montada por `live-build` a partir de listas
  declarativas, overlays, hooks e configuracao do Calamares.
- Identidade propria em `/etc/os-release`: `ID=starlight`, `ID_LIKE=debian` e
  codinome do produto `vega`; a compatibilidade de pacotes continua Debian.
- Fontes APT online do Debian e de seguranca ficam ativas apos a instalacao;
  fontes `cdrom:` nao permanecem no sistema instalado.
- Artefatos externos incluidos na imagem possuem versao e checksum registrados
  em `config/assets.env`.

## Experiencia grafica Starlight

- GNOME 48, GDM, Wayland, PipeWire, WirePlumber e NetworkManager sao
  selecionados explicitamente, sem o metapacote Ubuntu Desktop.
- Sessao escura com Adwaita, acento amarelo, icones
  `Starlight-Colloid-Yellow-Dark`, wallpaper Starlight e fonte monoespacada
  JetBrainsMono Nerd Font.
- Dock inferior flutuante azul-marinho, com indicadores dourados; favoritos
  incluem Chromium, Arquivos, Ptyxis, Software e o instalador na sessao live.
- Extensoes habilitadas: Dash to Dock, AppIndicator, Caffeine, Tiling
  Assistant, Blur My Shell e a extensao propria que move o relogio para o lado
  direito do painel. O blur e restrito ao overview e a pastas de aplicativos.
- Tema visual do GDM, Plymouth, tela de boot, Calamares, wallpaper e avatar
  seguem a marca Starlight.
- Desktop Icons NG nao e incluido: o desktop permanece sem icones soltos por
  padrao.

## Aplicacoes e fluxos escolhidos

- Chromium e o navegador padrao e fica fixado no dock. Firefox ESR permanece
  como alternativa/fallback, com politicas que removem favoritos padrao e o
  mecanismo de busca de pacotes Debian.
- GNOME Web/Epiphany e o lancador generico `Web Browser` sao removidos para
  evitar navegadores concorrentes na grade de aplicativos.
- Nautilus e File Roller permanecem como fluxo de arquivos. O sistema inclui
  descoberta de rede, SMB/CIFS, MTP, exFAT, NTFS e 7-Zip.
- Comunicacao: Thunderbird e Element Desktop. Flathub e configurado no sistema
  e o ZapZap e instalado como Flatpak de sistema.
- WPS Office, LinuxToys e WebApp Manager sao incluidos por meio de artefatos
  versionados durante a montagem da imagem. Insync possui instalador separado,
  com consentimento explicito e verificacao do fingerprint da chave do
  fornecedor.
- GNOME Software recebe suporte a Flatpak, pacotes Debian e firmware; tambem
  estao disponiveis Gdebi, Synaptic, Nala, Timeshift, Flatseal e fwupd.

## Estacao de desenvolvimento e infraestrutura

- Toolchain pronta para desenvolvimento: compiladores, Git, Python com venv e
  pip, Node.js/npm, Docker, Podman, ShellCheck, shfmt, tmux, fzf, fd, bat,
  eza, yq, direnv e Starship.
- Terminais GNOME/Ptyxis configuraveis para JetBrainsMono Nerd Font; Oh My
  Bash ja e instalado para contas novas. Homebrew e SDKMAN sao oferecidos como
  instaladores opt-in por usuario, nao como dependencias obrigatorias da ISO.
- Virtualizacao: QEMU, libvirt, virt-manager, bridge-utils e ferramentas de
  imagem de disco.
- Plataforma de containers: Incus, cliente Incus, extensoes Incus, lxcfs,
  dnsmasq, AppArmor e backends Btrfs, LVM e ZFS. Isso deixa a base pronta para
  a topologia Starlight de Incus; os containers e servicos da plataforma nao
  sao embutidos na ISO.
- SSH e NetworkManager sao habilitados no sistema; o usuario decide a politica
  de acesso e exposicao de rede depois da instalacao.

## Midia, hardware e jogos

- Pilha de audio moderna com PipeWire, Bluetooth, JACK/Pulse/ALSA,
  EasyEffects, Helvum e Pavucontrol.
- Codecs e ferramentas para video e midia: FFmpeg, GStreamer, VLC, MPV, GIMP,
  VA-API, VDPAU e suporte a DVD.
- Firmware Debian para dispositivos comuns, incluindo Intel, AMD, Realtek,
  MediaTek e Wi-Fi Intel, alem de microcode Intel e AMD.
- No primeiro boot, quando uma GPU NVIDIA e detectada, a imagem tenta instalar
  a pilha NVIDIA do repositorio Debian, incluindo DKMS open, EGL Wayland,
  VA-API e ferramentas de configuracao. A falha nao bloqueia a sessao.
- Perfil de jogos com Steam, suporte i386, GameMode, MangoHud, GOverlay,
  Vulkan, Mesa e vkBasalt.

## Instalacao e primeiro boot

- Calamares com branding proprio, suporte BIOS e UEFI e caminho de boot UEFI
  removivel para cenarios que nao persistem NVRAM, como algumas VMs.
- O instalador executa limpeza do que e exclusivo da ISO live: launcher,
  configuracao e pacotes do Calamares, helper de navegador live e favorito do
  instalador. O sistema instalado nao carrega esses componentes.
- A imagem live cria o usuario `starlight` e, quando o boot automatico esta
  habilitado, entra diretamente na sessao live. Isso e um recurso da midia de
  instalacao, nao uma conta padrao criada no sistema instalado.
- O primeiro boot instalado registra inventario local minimo de hardware em
  `/var/lib/starlight`, configura Flathub e executa a deteccao de NVIDIA. O
  inventario nao e enviado para servicos externos.

## Higiene, manutencao e limites

- A etapa final remove IDs de maquina, chaves SSH, historicos, caches, logs,
  journals e estado APT de build. Cada maquina gera sua propria identidade.
- Snap e excluido intencionalmente. O sistema usa pacotes Debian e Flatpak;
  ferramentas externas opcionais pedem consentimento ou sao instaladas por
  comando explicito.
- Credenciais, chaves de usuario, telemetria e dados de produtos Starlight nao
  fazem parte da imagem. Telemetria permanece desabilitada ate opt-in futuro.
- O tema KDE/Plasma salvo no repositorio separado `starlight-kde-theme` e um
  perfil da estacao de trabalho atual. A interface padrao da ISO descrita aqui
  continua sendo GNOME, portanto esse tema KDE nao e parte da imagem Vega.

## Fontes no repositorio

- `config/build.env` e `config/assets.env`: base, arquitetura, espelhos e
  artefatos externos.
- `packages/*.list.chroot`: conjuntos de pacotes por responsabilidade.
- `sosd/`: defaults GNOME, branding, servicos, helpers e politicas.
- `hooks/`: configuracao deterministicamente aplicada durante a montagem.
- `installer/`: comportamento do Calamares e limpeza do sistema instalado.
- `docs/architecture.md` e `docs/security.md`: principios de arquitetura,
  reprodutibilidade e higiene da imagem.
