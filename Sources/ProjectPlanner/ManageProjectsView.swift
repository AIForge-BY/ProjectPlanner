import SwiftUI

struct ManageProjectsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isCreatingTodo = false
    @State private var isShowingTrash = false
    @State private var isShowingGroupManager = false
    @State private var selectedExistingTodoProject: PlannedProject?
    @State private var selectedTemplateTodoProject: PlannedProject?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.020, green: 0.030, blue: 0.050),
                    Color(red: 0.035, green: 0.070, blue: 0.095),
                    Color(red: 0.025, green: 0.035, blue: 0.060)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                toolbar
                board
                    .padding(.horizontal, 18)
                    .padding(.bottom, 22)
            }

            if let errorMessage = appState.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.82), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom, 16)
                }
            }

            if isShowingTrash {
                FloatingModalOverlay {
                    isShowingTrash = false
                } content: {
                    TrashView(closeAction: {
                        isShowingTrash = false
                    })
                    .environmentObject(appState)
                }
            }

            if isShowingGroupManager {
                FloatingModalOverlay {
                    isShowingGroupManager = false
                } content: {
                    GroupManagerView(closeAction: {
                        isShowingGroupManager = false
                    })
                    .environmentObject(appState)
                }
            }
        }
        .sheet(isPresented: $isCreatingTodo) {
            NewTodoView()
                .environmentObject(appState)
        }
        .sheet(item: $selectedExistingTodoProject) { project in
            AddExistingProjectView(todoProject: project)
                .environmentObject(appState)
        }
        .sheet(item: $selectedTemplateTodoProject) { project in
            NewProjectView(todoProject: project)
                .environmentObject(appState)
        }
    }

    private var toolbar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppBrand.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("项目管理中枢")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.58))
            }
            Spacer()
            Button {
                isShowingGroupManager = true
            } label: {
                Label("分组", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .tint(Color(red: 0.70, green: 0.82, blue: 0.90))
            Button {
                isShowingTrash = true
            } label: {
                Label("回收站", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(Color(red: 0.70, green: 0.82, blue: 0.90))
            Button {
                isCreatingTodo = true
            } label: {
                Label("新建待办", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.15, green: 0.46, blue: 0.78))
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var board: some View {
        HStack(alignment: .top, spacing: 14) {
            ProjectColumn(
                title: "待办项目",
                status: .todo,
                accent: Color(red: 0.28, green: 0.72, blue: 0.88),
                newExistingAction: { project in
                    selectedExistingTodoProject = project
                },
                newTemplateAction: { project in
                    selectedTemplateTodoProject = project
                }
            )
            ProjectColumn(title: "执行中", status: .active, accent: Color(red: 0.36, green: 0.84, blue: 0.68))
            ProjectColumn(title: "完成", status: .completed, accent: Color(red: 0.58, green: 0.50, blue: 0.88))
        }
    }
}

private struct FloatingModalOverlay<Content: View>: View {
    let closeAction: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()
                .onTapGesture(perform: closeAction)

            content()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.42), radius: 28, x: 0, y: 18)
                .transition(.scale(scale: 0.98).combined(with: .opacity))
        }
        .zIndex(20)
    }
}
