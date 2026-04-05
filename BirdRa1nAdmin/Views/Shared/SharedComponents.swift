// BirdRa1nAdmin/Views/Shared/SharedComponents.swift
import SwiftUI

// MARK: - Field Label wrapper
struct FieldRow<Content: View>: View {
    let label: String
    var required: Bool = false
    var hint: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 3) {
                Text(label)
                    .font(.footnote).fontWeight(.medium).foregroundStyle(.secondary)
                if required { Text("*").font(.footnote).foregroundStyle(.red) }
            }
            content()
            if let hint {
                Text(hint).font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Styled TextField
struct AppTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var required: Bool = false
    var hint: String? = nil

    var body: some View {
        FieldRow(label: label, required: required, hint: hint) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Styled TextEditor
struct AppTextEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 80

    var body: some View {
        FieldRow(label: label) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body).foregroundStyle(.tertiary)
                        .padding(.horizontal, 8).padding(.top, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight)
                    .padding(3)
            }
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Status Picker
struct AppStatusPicker: View {
    @Binding var status: String
    let options: [String]

    var body: some View {
        FieldRow(label: "Status") {
            Picker("Status", selection: $status) {
                ForEach(options, id: \.self) { opt in
                    Label(opt.capitalized, systemImage: iconFor(opt)).tag(opt)
                }
            }
            .pickerStyle(.menu).labelsHidden()
        }
    }

    private func iconFor(_ s: String) -> String {
        switch s {
        case "published": return "checkmark.circle"
        case "draft":     return "pencil.circle"
        case "archived":  return "archivebox"
        default:          return "circle"
        }
    }
}

// MARK: - Toggle row
struct AppToggle: View {
    let label: String
    var description: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline).fontWeight(.medium)
                if let d = description { Text(d).font(.caption).foregroundStyle(.secondary) }
            }
        }
    }
}

// MARK: - Section Card
struct SectionCard<Content: View>: View {
    var label: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let label {
                Text(label)
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundStyle(.secondary).textCase(.uppercase)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Thumbnail preview
struct URLImagePreview: View {
    let urlString: String?
    var height: CGFloat = 100
    var cornerRadius: CGFloat = 8

    var body: some View {
        if let s = urlString, !s.isEmpty, let url = URL(string: s) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(.secondary.opacity(0.08))
                        .overlay(Image(systemName: "photo").foregroundStyle(.tertiary))
                }
            }
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(.separator, lineWidth: 0.5))
        }
    }
}

// MARK: - Skeleton row
struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.secondary.opacity(0.15)).frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(.secondary.opacity(0.15)).frame(width: 160, height: 11)
                RoundedRectangle(cornerRadius: 4).fill(.secondary.opacity(0.1)).frame(width: 100, height: 9)
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .shimmer()
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            if let s = subtitle { Text(s) }
        }
    }
}

// MARK: - Table list wrapper
struct ListTable<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        List {
            content()
        }
        .listStyle(.inset)
        .alternatingRowBackgrounds()
    }
}
