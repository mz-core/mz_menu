---
type: "query"
date: "2026-10-04T08:53:07.189540+00:00"
question: "Como o Player Selector se integra ao mz_menu?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["MZMenu.PlayerSelector()", "loadPlayerSelectorPage()"]
---

# Q: Como o Player Selector se integra ao mz_menu?

## Answer

MZMenu.PlayerSelector orquestra foco, busca assincrona, filtros e selecao por chave; a NUI recebe apenas DTO visual e o consumer fornece o backend.

## Outcome

- Signal: useful

## Source Nodes

- MZMenu.PlayerSelector()
- loadPlayerSelectorPage()