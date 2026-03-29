// Sources/BirdRa1nAdmin/Views/Shared/PageHeader.swift
import SwiftUI

struct PageHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "NOVO"
    var actionIcon: String = "plus"

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.textMuted)
                }
            }

            Spacer()

            if let action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: actionIcon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(actionLabel)
                    }
                }
                .buttonStyle(NeonButtonStyle(variant: .primary))
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Editor Page Header (with back button)
struct EditorHeader: View {
    let title: String
    var subtitle: String? = nil
    let onBack: () -> Void
    let onSave: () -> Void
    var isSaving: Bool = false
    var extra: AnyView? = nil

    var body: some View {
        HStack(spacing: 16) {
            // Back
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("VOLTAR")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(1)
                }
            }
            .buttonStyle(NeonButtonStyle(variant: .outline))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.textMuted)
                }
            }

            Spacer()

            if let extra { extra }

            Button(action: onSave) {
                HStack(spacing: 6) {
                    if isSaving {
                        NeonSpinner()
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 11))
                    }
                    Text(isSaving ? "SALVANDO..." : "SALVAR")
                }
            }
            .buttonStyle(NeonButtonStyle(variant: .primary))
            .disabled(isSaving)
            .keyboardShortcut("s", modifiers: .command)
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }
}

// MARK: - Section divider
struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.border)
            .frame(height: 1)
    }
}

// MARK: - Empty state
struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.textMuted.opacity(0.4))
            Text(title)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.textMuted.opacity(0.5))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Form field
struct FormField<Content: View>: View {
    let label: String
    var required: Bool = false
    var hint: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(label.uppercased())
                    .monoLabel()
                    .foregroundColor(.textMuted)
                if required {
                    Text("*")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.neon)
                }
            }
            content()
            if let hint {
                Text(hint)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.textMuted.opacity(0.5))
            }
        }
    }
}

// MARK: - Terminal TextField
struct TerminalField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var required: Bool = false
    var hint: String? = nil
    @FocusState private var focused: Bool

    var body: some View {
        FormField(label: label, required: required, hint: hint) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.bgCardAlt)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(focused ? Color.neon.opacity(0.6) : Color.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .focused($focused)
        }
    }
}

// MARK: - Terminal TextEditor
struct TerminalEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 80
    @FocusState private var focused: Bool

    var body: some View {
        FormField(label: label) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.textMuted.opacity(0.4))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                }
                TextEditor(text: $text)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .focused($focused)
            }
            .frame(minHeight: minHeight)
            .background(Color.bgCardAlt)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(focused ? Color.neon.opacity(0.6) : Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

// MARK: - Card container
struct AdminCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var padding: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Toggle row
struct ToggleRow: View {
    let label: String
    var description: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $isOn)
                .toggleStyle(NeonToggleStyle())
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.textPrimary)
                if let description {
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.textMuted)
                }
            }
        }
    }
}

struct NeonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: configuration.isOn ? .trailing : .leading) {
            Capsule()
                .fill(configuration.isOn ? Color.neon : Color.bgCardAlt)
                .overlay(Capsule().stroke(configuration.isOn ? Color.neon : Color.border, lineWidth: 1))
                .frame(width: 36, height: 20)
                .shadow(color: configuration.isOn ? Color.neon.opacity(0.4) : .clear, radius: 6)

            Circle()
                .fill(configuration.isOn ? Color.bgPrimary : Color.textMuted)
                .frame(width: 14, height: 14)
                .padding(3)
        }
        .animation(.spring(duration: 0.2), value: configuration.isOn)
        .onTapGesture { configuration.isOn.toggle() }
    }
}

// MARK: - Status Picker
struct StatusPicker: View {
    @Binding var status: String
    let options: [String]

    var body: some View {
        FormField(label: "Status") {
            Picker("", selection: $status) {
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .font(.system(size: 12, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
