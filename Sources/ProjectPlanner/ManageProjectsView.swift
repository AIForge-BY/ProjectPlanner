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
            TechBackground()

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

private struct TechBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.015, green: 0.025, blue: 0.042),
                    Color(red: 0.026, green: 0.055, blue: 0.070),
                    Color(red: 0.018, green: 0.026, blue: 0.048)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GridPattern()
                .stroke(Color(red: 0.40, green: 0.82, blue: 0.92).opacity(0.055), lineWidth: 1)

            CircuitPattern()
                .stroke(Color(red: 0.42, green: 0.90, blue: 0.82).opacity(0.15), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))

            CircuitNodes()
                .fill(Color(red: 0.44, green: 0.91, blue: 0.83).opacity(0.22))

            LinearGradient(
                colors: [
                    .clear,
                    Color(red: 0.32, green: 0.74, blue: 0.92).opacity(0.10),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(-18))
            .offset(x: -180, y: -120)
            .blur(radius: 18)
        }
        .ignoresSafeArea()
    }
}

private struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 36
        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }
        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        return path
    }
}

private struct CircuitPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.08, y: h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.30, y: h * 0.28))
        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.28))

        path.move(to: CGPoint(x: w * 0.62, y: h * 0.12))
        path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.22))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.22))

        path.move(to: CGPoint(x: w * 0.12, y: h * 0.78))
        path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.66))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.66))

        path.move(to: CGPoint(x: w * 0.58, y: h * 0.76))
        path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.62))
        path.addLine(to: CGPoint(x: w * 0.92, y: h * 0.62))

        return path
    }
}

private struct CircuitNodes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = [
            CGPoint(x: rect.width * 0.08, y: rect.height * 0.18),
            CGPoint(x: rect.width * 0.44, y: rect.height * 0.28),
            CGPoint(x: rect.width * 0.62, y: rect.height * 0.12),
            CGPoint(x: rect.width * 0.88, y: rect.height * 0.22),
            CGPoint(x: rect.width * 0.12, y: rect.height * 0.78),
            CGPoint(x: rect.width * 0.38, y: rect.height * 0.66),
            CGPoint(x: rect.width * 0.92, y: rect.height * 0.62)
        ]
        for point in points {
            path.addEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
        }
        return path
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
