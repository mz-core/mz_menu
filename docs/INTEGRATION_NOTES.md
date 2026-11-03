# Integração em resources MZ

## Padrão recomendado

O resource de negócio deve continuar tendo:

- callbacks/events próprios;
- validação server-side;
- logs;
- banco;
- regras de acesso.

O `mz_menu` deve fazer apenas:

- abrir menu;
- coletar input;
- mostrar alerta;
- mostrar notify;
- disparar evento/callback do resource chamador.
- controlar o repasse de movimento sem executar acao de gameplay.

## Interacao e movimento do contexto

O contexto permanece interativo enquanto o player se movimenta. O controle global
de movimento pertence ao `mz_menu` e não deve ser reimplementado por cada consumidor.
Diálogos pendentes travam o movimento temporariamente, e controles de combate são
bloqueados enquanto o input do jogo é repassado.

Uma nova sessão abre com movimento travado. O estado selecionado com `F6` é
preservado entre contextos, inclusive quando os builders pertencem a resources
diferentes, até o fechamento completo do menu.

Resources consumidores nao devem interpretar `IsMovementEnabled()` ou
`IsContextFocused()` como permissao. Toda acao continua sendo revalidada pelo
servidor de negocio.

## NUI própria

A versão atual usa NUI própria por padrão:

```txt
mz_menu/web/index.html
mz_menu/web/style.css
mz_menu/web/app.js
```

Isso permite editar layout, cores, espaçamento e ícones sem mexer nos resources de negócio.

## Ícones

Os ícones estão embutidos localmente em `web/app.js`.

Recomendação para produção FiveM:

```txt
Preferir ícones locais/embutidos.
Evitar CDN/web externa dentro da NUI.
```

Motivos:

- funciona sem internet no client;
- carrega mais rápido;
- evita falha por CDN bloqueada;
- mantém identidade visual do MZ Core;
- permite empacotar tudo no resource.

Se quiser expandir, o melhor caminho é criar depois:

```txt
web/assets/icons/*.svg
```

ou manter um mapa SVG local no JS.

## Ordem no server.cfg

```txt
ensure mz_menu
ensure mz_core
ensure mz_houses
```

Se algum resource ainda usa `ox_lib` diretamente para callbacks ou outras funções, ele continua precisando do próprio `ox_lib`. Isso é separado do `mz_menu`.

Exemplo: `mz_houses` pode usar `lib.callback` internamente e, por isso, ainda depender de `ox_lib`, mesmo que o visual do menu venha do `mz_menu`.

## Não fazer

- Não colocar permissões dentro do `mz_menu`.
- Não salvar dados pelo `mz_menu`.
- Não criar regras específicas de casa/org/veículo no `mz_menu`.
- Não expor dados sensíveis só porque o menu é admin.

## Sobre virar uma lib maior

O ideal é não transformar tudo em uma lib gigante agora.

Fase atual:

```txt
mz_menu = menu/input/alert/notify visual
```

Depois, se fizer sentido, criar uma lib maior:

```txt
mz_ui ou mz_lib
- menu
- notify
- progress
- prompt
- modal
- tooltip
- icons
- theme
```

Mas isso deve ser feito depois de estabilizar o menu, para não misturar refatoração visual com notify/progress que já funcionam.


## Versão 0.3.0 - NUI própria estilo v0

- Layout convertido do protótipo do v0 para HTML/CSS/JS puro.
- Não precisa rodar Node/Next/React no servidor FiveM.
- Mantém os mesmos exports usados por `mz_houses`.
- `ox_lib` não é dependência obrigatória; use somente se quiser backend/fallback manual.
- Ícones seguem SVG inline em `web/app.js`, sem CDN.
