# Graph Report - mz_menu  (2026-10-24)

## Corpus Check
- 15 files · ~13,679 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 169 nodes · 317 edges · 21 communities
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b4cbfa98`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app.js
- Per-Context Visual Identity
- MZMenu.ShowContext
- escapeHtml
- MZMenu.PlayerSelector
- MZMenu.IsReady
- server_debug_security_harness.lua
- setFocus
- nuiAlertDialog
- post
- cfg
- client/main.lua
- Contrato de layout dashboard do `mz_menu`
- svg
- openContext
- Q: Como o Player Selector se integra ao mz_menu?

## God Nodes (most connected - your core abstractions)
1. `cfg()` - 14 edges
2. `MZMenu.ShowContext()` - 12 edges
3. `escapeHtml()` - 12 edges
4. `setFocus()` - 10 edges
5. `normalizeMenu()` - 9 edges
6. `MZMenu.PlayerSelector()` - 9 edges
7. `post()` - 9 edges
8. `trim()` - 8 edges
9. `MZMenu.Notify()` - 8 edges
10. `oxReady()` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Business Resource Ownership` --semantically_similar_to--> `Server-Side Security Boundary`  [INFERRED] [semantically similar]
  docs/INTEGRATION_NOTES.md → README.md
- `Menu Presentation Responsibility` --semantically_similar_to--> `mz_menu Visual Layer`  [INFERRED] [semantically similar]
  docs/INTEGRATION_NOTES.md → README.md
- `trigger()` --calls--> `TriggerClientEvent()`  [INFERRED]
  server/main.lua → tests/server_debug_security_harness.lua
- `Per-Context Visual Identity` --conceptually_related_to--> `Context Panel`  [INFERRED]
  docs/CONTEXT_THEME_CONTRACT.md → web/index.html
- `Dialog Movement Lock and Restore` --conceptually_related_to--> `Dialog Overlay`  [INFERRED]
  docs/INTERACTION_FOCUS_CONTRACT.md → web/index.html

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Context Visual Identity Flow** — readme_native_nui_backend, docs_context_theme_contract_context_visual_identity, docs_context_theme_contract_theme_inheritance_chain, web_index_context_panel [INFERRED 0.85]
- **Visual Layer Security Boundary** — readme_server_side_security_boundary, docs_context_theme_contract_visual_metadata_authorization_boundary, docs_integration_notes_business_resource_ownership, docs_integration_notes_menu_presentation_responsibility [INFERRED 0.95]

## Communities (21 total, 0 thin omitted)

### Community 0 - "app.js"
Cohesion: 0.07
Nodes (27): app, backBtn, brandEl, closeBtn, contextPanel, dashboardMeta, dialogEl, dialogOverlay (+19 more)

### Community 1 - "Per-Context Visual Identity"
Cohesion: 0.11
Nodes (18): Per-Context Visual Identity, Theme Inheritance Chain, Theme Payload Validation, Visual Metadata Authorization Boundary, Business Resource Ownership, Embedded Asset Strategy, Menu Presentation Responsibility, Combat Input Suppression (+10 more)

### Community 2 - "MZMenu.ShowContext"
Cohesion: 0.23
Nodes (13): executeLifecycle(), executeOption(), MZMenu.OpenContext(), MZMenu.OpenMenu(), MZMenu.RegisterContext(), MZMenu.RegisterSimpleMenu(), MZMenu.ShowContext(), normalizeMenu() (+5 more)

### Community 3 - "escapeHtml"
Cohesion: 0.31
Nodes (11): escapeHtml(), notify(), openInputDialog(), renderDashboardMeta(), renderInputRow(), renderMetadata(), renderOption(), renderPill() (+3 more)

### Community 4 - "MZMenu.PlayerSelector"
Cohesion: 0.32
Nodes (8): debugPrint(), loadPlayerSelectorPage(), MZMenu.PlayerSelector(), nuiReady(), sanitizeSelectorItem(), sanitizeSelectorResult(), sanitizeSelectorText(), selectorDisplayResult()

### Community 5 - "MZMenu.IsReady"
Cohesion: 0.48
Nodes (7): alertReady(), contextReady(), inputReady(), MZMenu.GetBackend(), MZMenu.IsReady(), notifyReady(), oxReady()

### Community 6 - "server_debug_security_harness.lua"
Cohesion: 0.29
Nodes (3): trigger(), validTarget(), TriggerClientEvent()

### Community 7 - "setFocus"
Cohesion: 0.50
Nodes (5): finishPlayerSelector(), MZMenu.CloseContext(), MZMenu.SetContextFocus(), MZMenu.ToggleContextFocus(), setFocus()

### Community 8 - "nuiAlertDialog"
Cohesion: 0.48
Nodes (7): awaitNui(), beginNuiDialog(), nextRequestId(), nuiAlertDialog(), nuiInputDialog(), restoreMovementAfterDialog(), sendCurrentTheme()

### Community 9 - "post"
Cohesion: 0.33
Nodes (7): bindPlayerSelectorResults(), cancelPlayerSelector(), closeAll(), closeDialogAsCancel(), post(), requestPlayerSelectorPage(), setMovementMode()

### Community 10 - "cfg"
Cohesion: 0.33
Nodes (9): cfg(), defaultMovementEnabled(), globalTheme(), mergeTheme(), movementToggleEnabled(), resolveContextVisual(), sanitizeThemePatch(), sendTheme() (+1 more)

### Community 11 - "client/main.lua"
Cohesion: 0.23
Nodes (14): actualMovementEnabled(), applyMovementInput(), chat(), movementToggleKey(), MZMenu.AlertDialog(), MZMenu.Confirm(), MZMenu.InputDialog(), MZMenu.IsMovementEnabled() (+6 more)

### Community 16 - "Contrato de layout dashboard do `mz_menu`"
Cohesion: 0.25
Nodes (7): Busca, Campos de contexto, Campos de opcao, Compatibilidade, Contrato de layout dashboard do `mz_menu`, Objetivo, Seguranca

### Community 17 - "svg"
Cohesion: 0.40
Nodes (5): getAlertVariant(), openAlertDialog(), openPlayerSelector(), selectorFilterLabel(), svg()

### Community 18 - "openContext"
Cohesion: 0.50
Nodes (4): applySearchFilter(), openContext(), updateFocus(), visibleButtons()

### Community 20 - "Q: Como o Player Selector se integra ao mz_menu?"
Cohesion: 0.40
Nodes (4): Answer, Outcome, Q: Como o Player Selector se integra ao mz_menu?, Source Nodes

## Knowledge Gaps
- **40 isolated node(s):** `app`, `contextPanel`, `menuTitle`, `brandEl`, `menuSubtitle` (+35 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `app`, `contextPanel`, `menuTitle` to the rest of the system?**
  _40 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app.js` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._
- **Should `Per-Context Visual Identity` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._