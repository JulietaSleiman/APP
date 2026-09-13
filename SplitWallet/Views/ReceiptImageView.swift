import SwiftUI

public struct ReceiptImageView: View {
    public let imageURL: URL
    @State private var isFullScreenPresented = false

    public init(imageURL: URL) {
        self.imageURL = imageURL
    }

    public var body: some View {
        Button {
            isFullScreenPresented = true
        } label: {
            if let data = try? Data(contentsOf: imageURL), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            } else {
                HStack {
                    Image(systemName: "doc.text.image")
                    Text("Ver Comprobante Adjunto")
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $isFullScreenPresented) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    if let data = try? Data(contentsOf: imageURL), let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") {
                            isFullScreenPresented = false
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
