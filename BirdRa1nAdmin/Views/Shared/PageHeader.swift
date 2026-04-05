// BirdRa1nAdmin/Views/Shared/PageHeader.swift
//
// Este arquivo existia na versão anterior com design "neon".
// Todo o conteúdo foi migrado para SharedComponents.swift com design nativo Apple.
//
// Mapeamento dos componentes antigos → novos:
//
//  PageHeader        → .navigationTitle() + .toolbar { ToolbarItem { Button } }
//  EditorHeader      → .navigationTitle() + .toolbar { ToolbarItem(cancellation) + ToolbarItem(confirmation) }
//  SectionDivider    → Divider()
//  EmptyStateView    → ContentUnavailableView  (em SharedComponents.swift)
//  FormField         → FieldRow               (em SharedComponents.swift)
//  TerminalField     → AppTextField           (em SharedComponents.swift)
//  TerminalEditor    → AppTextEditor          (em SharedComponents.swift)
//  AdminCard         → SectionCard            (em SharedComponents.swift)
//  ToggleRow         → AppToggle              (em SharedComponents.swift)
//  NeonToggleStyle   → Toggle nativo
//  StatusPicker      → AppStatusPicker        (em SharedComponents.swift)
//  NeonButtonStyle   → .buttonStyle(.borderedProminent) / .bordered nativos
//  NeonSpinner       → ProgressView().controlSize(.small)
//  LoadingTable      → List { SkeletonRow() } (em SharedComponents.swift)
//  TableHeader       → removido — List nativo não usa header custom
//  FlowLayout        → FlowLayout             (em DesignSystem.swift)
//
// IMPORTANTE: delete este arquivo do Xcode após confirmar que não há mais
// referências a PageHeader, EditorHeader ou SectionDivider no projeto.
//
// Se alguma view ainda referencia SectionDivider ou os tipos antigos,
// substitua por Divider() diretamente.

import SwiftUI

// Mantido apenas para evitar erros de compilação durante a transição.
// Remova após limpar todas as referências.

@available(*, deprecated, renamed: "Divider")
typealias SectionDivider_Deprecated = Divider
