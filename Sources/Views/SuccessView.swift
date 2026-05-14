import SwiftUI

struct SuccessView: View {
    let count: Int
    let categoryName: String
    let onAddMore: () -> Void
    let onReveal: () -> Void
    let onOpenFCP: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: count)
                        .accessibilityHidden(true)

                    Text("\(count) title\(count == 1 ? "" : "s") created")
                        .font(.title2.bold())

                    Text("Your 3D objects are ready in Final Cut Pro.\nFind them in the Titles Browser under \"\(categoryName)\".")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button("Reveal in Finder") {
                            onReveal()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Button("Open Final Cut Pro") {
                            onOpenFCP()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Button("Add More Files") {
                        onAddMore()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)

            Divider()

            Link(destination: URL(string: "https://rippletraining.com")!) {
                HStack(spacing: 12) {
                    if let logo = NSImage(named: "Ripple_logo_T") {
                        Image(nsImage: logo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .accessibilityHidden(true)
                    }

                    (Text("World-class training and plugins for Final Cut Pro and Motion at ")
                        .foregroundStyle(.secondary)
                     + Text("rippletraining.com")
                        .foregroundStyle(.blue))
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .accessibilityLabel("Visit Ripple Training")
            .accessibilityHint("World-class training and plugins for Final Cut Pro and Motion. Opens rippletraining.com in your browser.")
        }
    }
}
