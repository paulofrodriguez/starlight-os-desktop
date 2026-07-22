# Prompt para o Codex

Analise o projeto de build da minha distribuição Starlight OS, baseada em
Debian 13 Trixie com GNOME puro, e integre o kit de login localizado em
`starlight-os-vega-gdm-kit`.

Objetivo:
- usar `assets/starlight-os-vega-4k.png` como fundo real do GDM;
- manter todos os controles de autenticação nativos e funcionais;
- deslocar o formulário de login do centro para o lado direito via
  `loginDialog.js`;
- aplicar o visual azul-marinho e dourado do arquivo CSS;
- não usar `login-reference.png` como tela real, pois ele é apenas mockup;
- não inventar a chave `GdmTheme` em `daemon.conf`;
- executar a personalização durante a compilação da distro;
- manter backup do gresource original;
- falhar o build caso a versão do GNOME não tenha os seletores esperados;
- rodar `scripts/validate-gdm-theme.sh` no final;
- preservar acessibilidade, seleção de sessão, idioma, rede, energia e login
  por senha;
- documentar todas as alterações no repositório.

Primeiro detecte como o projeto constrói a imagem (live-build, debootstrap,
Makefile, scripts próprios ou pipeline). Depois copie o kit para o filesystem
do chroot e conecte o hook no estágio correto. Verifique as dependências
`libglib2.0-bin`, `python3`, `gnome-shell` e `gdm3`.

Antes de concluir:
1. confirme a versão instalada de `gnome-shell`;
2. liste o conteúdo do gresource antes e depois;
3. valide que `starlight-os-vega-4k.png` está incorporado;
4. valide que `loginDialog.js` contém o patch `//RIGHT`;
5. construa a ISO;
6. forneça os comandos para teste em QEMU/virt-manager;
7. não reinicie o GDM no ambiente de desenvolvimento atual.
