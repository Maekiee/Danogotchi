import Combine
import PhotosUI
import SwiftUI

struct PhotoThemeView: View {
    @StateObject private var viewModel: PhotoThemeViewModel

    init(viewModel: PhotoThemeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = viewModel.previewImage {
                PhotoCropView(image: image) { rect in
                    viewModel.updateCropRect(rect, for: image)
                }
                    .aspectRatio(viewModel.targetAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                emptyState
            }

            if viewModel.isLoading || viewModel.isSaving {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView().tint(.white).scaleEffect(1.4)
                }
            }
        }
        .overlay(alignment: .bottom) { bottomBar }
        .disabled(viewModel.isSaving || viewModel.isLoading)
        .photosPicker(
            isPresented: $viewModel.isPickerPresented,
            selection: $viewModel.pickedItem,
            matching: .images
        )
        .onChange(of: viewModel.pickedItem) { viewModel.load(item: $0) }
        .alert("알림", isPresented: isAlertPresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}

private extension PhotoThemeView {
    var isAlertPresented: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )
    }

    var emptyState: some View {
        VStack(spacing: AppSpacing.space12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 44))
                .foregroundColor(Color(AppColor.gray45))
            Text("배경으로 쓸 사진을 골라주세요")
                .font(Font(AppFont.body))
                .foregroundColor(Color(AppColor.textSecondary))
        }
    }

    var bottomBar: some View {
        VStack(spacing: AppSpacing.space12) {
            PhotosPicker(selection: $viewModel.pickedItem, matching: .images) {
                capsuleLabel(
                    viewModel.previewImage == nil ? "사진첩에서 사진 고르기" : "다른 사진 고르기",
                    foreground: AppColor.white,
                    background: AppColor.black.withAlphaComponent(0.55)
                )
            }
            .buttonStyle(.plain)

            Button {
                viewModel.confirmSelection()
            } label: {
                // PrimaryFillButton과 같은 스펙 — 비활성 색까지 맞춘다
                capsuleLabel(
                    "이미지 테마로 지정",
                    foreground: viewModel.canConfirm ? AppColor.white : AppColor.gray45,
                    background: viewModel.canConfirm ? AppColor.black : AppColor.gray30
                )
            }
            .disabled(!viewModel.canConfirm)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.space20)
        .padding(.bottom, AppSpacing.space20)
    }

    func capsuleLabel(_ title: String, foreground: UIColor, background: UIColor) -> some View {
        Text(title)
            .font(Font(AppFont.title3))
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundColor(Color(foreground))
            .background(Color(background))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius20))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.radius20))
    }
}

// MARK: - Preview
#if DEBUG
private struct PreviewSavePhotoThemeUseCase: SavePhotoThemeUseCase {
    func execute(imageData: Data, crop: PhotoThemeCrop) -> AnyPublisher<Void, Error> {
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

#Preview("PhotoThemeView") {
    PhotoThemeView(
        viewModel: PhotoThemeViewModel(savePhotoThemeUseCase: PreviewSavePhotoThemeUseCase())
    )
}
#endif
