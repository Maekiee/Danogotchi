import Combine
import ComposableArchitecture
import PhotosUI
import SwiftUI

struct PhotoThemeView: View {
    @Bindable
    var store: StoreOf<PhotoThemeFeature>

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = store.previewImage {
                PhotoCropView(image: image) { rect in
                    store.send(.cropChanged(rect, image))
                }
                    .aspectRatio(targetAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                emptyState
            }

            if store.isLoading || store.isSaving {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView().tint(.white).scaleEffect(1.4)
                }
            }
        }
        .overlay(alignment: .bottom) { bottomBar }
        .disabled(store.isSaving || store.isLoading)
        .photosPicker(
            isPresented: $store.isPickerPresented,
            selection: $store.pickedItem,
            matching: .images
        )
        .alert("알림", isPresented: isAlertPresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(store.alertMessage ?? "")
        }
    }
}

private extension PhotoThemeView {
    var targetAspectRatio: CGFloat {
        UIScreen.main.nativeBounds.width / UIScreen.main.nativeBounds.height
    }

    var isAlertPresented: Binding<Bool> {
        Binding(
            get: { store.alertMessage != nil },
            set: { if !$0 { store.alertMessage = nil } }
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
            PhotosPicker(selection: $store.pickedItem, matching: .images) {
                capsuleLabel(
                    store.previewImage == nil ? "사진첩에서 사진 고르기" : "다른 사진 고르기",
                    foreground: AppColor.white,
                    background: AppColor.black.withAlphaComponent(0.55)
                )
            }
            .buttonStyle(.plain)

            Button {
                store.send(.confirmTapped)
            } label: {
                // PrimaryFillButton과 같은 스펙 — 비활성 색까지 맞춘다
                capsuleLabel(
                    "이미지 테마로 지정",
                    foreground: store.canConfirm ? AppColor.white : AppColor.gray45,
                    background: store.canConfirm ? AppColor.black : AppColor.gray30
                )
            }
            .disabled(!store.canConfirm)
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
        store: Store(initialState: PhotoThemeFeature.State()) {
            PhotoThemeFeature(savePhotoThemeUseCase: PreviewSavePhotoThemeUseCase(), onThemeSaved: {})
        }
    )
}
#endif
