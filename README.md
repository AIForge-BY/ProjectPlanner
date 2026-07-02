# 星联

星联 is a native macOS menu bar app for managing local client projects.

It tracks projects in four states:

- Todo
- Active
- Completed
- Trash

The menu bar shows active projects and quick actions. The management window provides a board for todo, active, and completed projects, with trash opened from a separate control.

## Features

- Create runnable default projects for iOS, Android, HarmonyOS, and generic VS Code projects.
- Add existing local projects as todo items.
- Create todo aliases first, then bind them to an existing project or a generated default project.
- Enter a custom project type label when choosing Other.
- Display projects by group, choose or create a group when adding todo items, manage groups globally or per project, batch move projects between groups, keep todo cards expanded by default, keep other cards collapsed by default, collapse or expand a whole column, and drag projects to adjust their order.
- Open project folders.
- Open the default IDE by project type:
  - Android: Android Studio
  - iOS: Xcode
  - HarmonyOS: DevEco Studio
  - Other: Visual Studio Code
- Open a terminal in the project directory.
  - Ghostty is used when `/Applications/Ghostty.app` exists.
  - macOS Terminal is used as the fallback.
  - The terminal starts Codex in the project directory, resuming the latest session for that directory when available and creating a new session otherwise.
- Initialize local git repositories for generated default projects.
- Optionally create or bind GitHub/Gitee remotes.
- Record completion time when projects are marked completed.
- Move deleted projects to trash, then open trash as an overlay, restore, empty trash, or permanently delete items.
- Use the menu bar item to open active project folders, IDEs, terminals, or mark projects completed.

## Data Storage

Project records are stored locally:

```text
~/Library/Application Support/ProjectPlanner/projects.json
```

The data file is JSON and includes a schema version plus project records.

## Remote Repository Behavior

星联 supports three remote modes when creating a default project:

- No remote.
- Create a new GitHub or Gitee repository.
- Bind an existing GitHub or Gitee repository.

Existing remote repositories are handled conservatively. If the remote has commits, ProjectPlanner binds `origin` but does not push the generated template. It never force-pushes remote history.

GitHub remote creation uses the `gh` CLI. Gitee remote creation expects a `gitee` CLI-compatible command in `PATH`.

## Development

Run tests:

```bash
HOME=/tmp/project-planner swift test
```

Build:

```bash
HOME=/tmp/project-planner swift build
```

Run the app from source:

```bash
scripts/run-app.sh
```

Build an app bundle:

```bash
scripts/build-app.sh
```

The bundle is written to:

```text
.build/ProjectPlanner.app
```

## Template Notes

The templates are minimal starter projects meant to be opened by their target IDEs. Android and HarmonyOS projects still depend on local SDK and IDE installation.
