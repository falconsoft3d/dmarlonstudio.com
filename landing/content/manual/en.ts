import type { Manual } from "./types";

const shot = (name: string) => `/manual/en/${name}.jpg`;

/** User manual in English: the translation of content/manual/es.ts. */
export const manualEn: Manual = {
  ui: {
    title: "DMarlon Studio manual",
    subtitle: "The complete guide to the visual IDE for building Python apps",
    intro:
      "Everything DMarlon Studio does, module by module: the window Designer, the code Editor with git, the database, API, FTP and diagram tools, artificial intelligence and settings.",
    contents: "Contents",
    chapter: "Chapter",
    previous: "Previous",
    next: "Next",
    onThisPage: "On this page",
    downloadPdf: "Download the PDF manual",
    allChapters: "All chapters",
    version: "Version",
    printTitle: "User manual",
  },
  chapters: [
    // ------------------------------------------------------------------ 1
    {
      slug: "introduction",
      title: "Introduction and installation",
      summary: "What DMarlon Studio is, what it needs and where it keeps everything.",
      sections: [
        {
          id: "what-it-is",
          title: "What DMarlon Studio is",
          blocks: [
            {
              type: "p",
              text: "DMarlon Studio is a visual desktop IDE. You design windows by dragging components onto a form, adjust their properties in an inspector and write the code of each event in Python. **F9** runs the window on your computer.",
            },
            {
              type: "p",
              text: "Today the same designer builds two kinds of app: desktop windows with **tkinter** and web apps with **Flask**. Around the designer there is a VS Code-style code editor with git and a terminal, a database manager, an API client, an FTP client, a diagram editor and AI assistants (Claude by default).",
            },
            {
              type: "img",
              src: shot("designer"),
              alt: "The Designer with the Calculator project open",
              caption: "The Designer: palette on top, tree and inspector on the left and the form in the center.",
            },
          ],
        },
        {
          id: "requirements",
          title: "Requirements",
          blocks: [
            {
              type: "table",
              head: ["To…", "You need"],
              rows: [
                ["Use the studio", "macOS 10.15 or later, or 64-bit Windows 10/11."],
                [
                  "Run desktop windows",
                  "Python 3 with tkinter. On macOS: `brew install python-tk` or the python.org installer. On Windows: the python.org installer with the **tcl/tk and IDLE** option ticked.",
                ],
                ["Run web apps", "Flask in that same Python: `python3 -m pip install flask` (on Windows, `py -3 -m pip install flask`)."],
                ["Version control in the Editor", "git installed on the computer."],
                ["Claude Code chat in the Designer", "Claude Code installed and signed in (optional)."],
                ["AI assistants", "An API key for the provider chosen in **Settings** (optional)."],
              ],
            },
            {
              type: "note",
              text: "The studio finds Python on its own: on the PATH, in the Homebrew folders and in the python.org install, and keeps the one with the newest Tk. The result is shown on the Designer's project list.",
            },
          ],
        },
        {
          id: "installation",
          title: "Installation",
          blocks: [
            { type: "p", text: "Download the zip for your system from the downloads section of dmarlonstudio.com." },
            {
              type: "ol",
              items: [
                "**macOS**: unzip `DMarlonStudio-macOS.zip` and move **DMarlon Studio** to the Applications folder. The first time, open the app with right-click → **Open**: it is not signed.",
                "**Windows**: unzip the whole `DMarlonStudio-Windows.zip` wherever you like (not in Program Files) and run `DMarlonStudio.exe`. If “Windows protected your PC” appears, click **More info** → **Run anyway**.",
              ],
            },
          ],
        },
        {
          id: "data",
          title: "Where everything is stored",
          blocks: [
            {
              type: "table",
              head: ["What", "Where"],
              rows: [
                [
                  "Designer projects",
                  "One folder per project in `~/Documents/DMarlon Studio/Proyectos` (it can be changed in the Designer). They can be versioned with git.",
                ],
                [
                  "Settings, connections, API requests, history and diagrams",
                  "`studio.sqlite`, in the app's data folder: `~/Library/Application Support/com.dmarlonstudio.studio` on macOS and `%APPDATA%\\DMarlon Studio\\DMarlon Studio` on Windows.",
                ],
                ["Deleted projects", "The `.papelera` folder inside the workspace: nothing is erased for good."],
              ],
            },
            {
              type: "p",
              text: "Each project folder holds `project.dmsproj` (the design, as JSON), the window's code (`Form1.py`, named after the form), a `.gitignore` and, once run, `build/` with the generated Python.",
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 2
    {
      slug: "getting-started",
      title: "Getting started",
      summary: "The main window, the modules, the theme and the language.",
      sections: [
        {
          id: "window",
          title: "The main window",
          blocks: [
            {
              type: "p",
              text: "On the left is the module bar: **Designer**, **Editor**, **Databases**, **API**, **FTP**, **Diagrams** and, at the bottom, the **Dark**/**Light** button and **Settings**.",
            },
            {
              type: "p",
              text: "Each module is created the first time you open it and keeps its state: you can go from the Designer to the Editor and back without losing anything unsaved.",
            },
            { type: "img", src: shot("designer-projects"), alt: "Designer project list", caption: "The project list, with the examples that come with the studio." },
          ],
        },
        {
          id: "theme-language",
          title: "Theme and language",
          blocks: [
            {
              type: "ul",
              items: [
                "The **Dark**/**Light** button on the bar switches the theme at once. In **Settings → Appearance** you can also choose **System** to follow your computer.",
                "**Settings → Language** switches between **Español** and **English** without closing anything. The first time, the system language is used.",
              ],
            },
          ],
        },
        {
          id: "first-project",
          title: "Your first window in five steps",
          blocks: [
            {
              type: "ol",
              items: [
                "In **Designer**, click **New project**, type a name and choose **Desktop (Python)**.",
                "Drag a **Label**, a **Text field** and a **Button** from the palette onto the form.",
                "Select the button and change its **Text** in the inspector, for example to “Greet”.",
                "Double-click the button: the `Button1_click` method is created and the code opens. Type `self.Label1.config(text=\"Hello, \" + self.Entry1.get())`.",
                "Press **F9**. The window opens in its own system window.",
              ],
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 3
    {
      slug: "designer",
      title: "The Designer",
      summary: "Projects, components, inspector, events, generated code and running.",
      sections: [
        {
          id: "projects",
          title: "Projects",
          blocks: [
            {
              type: "p",
              text: "The project list shows the workspace projects and those opened from other folders. At the top you see the Python found (Python and Tk versions) and the button to **Look for Python again**.",
            },
            {
              type: "ul",
              items: [
                "**New project**: asks for the name and the target, **Desktop (Python)** or **Web (Flask)**. The target cannot be changed later.",
                "**Open folder…**: opens a project stored in any other folder; it stays on the list as a recent one.",
                "**Workspace**: **Show** opens it in Finder or Explorer and **Change…** picks another folder.",
                "On each card: **Run**, **Show the folder** and, under **More actions**, **Duplicate** and **Delete** (moves the project to the workspace trash).",
              ],
            },
            {
              type: "note",
              text: "The first time, the studio copies some example projects (calculator, unit converter, tasks, stopwatch, customer form, Odoo contacts…), in desktop and web versions. They are good starting points.",
            },
          ],
        },
        {
          id: "screen",
          title: "The Designer screen",
          blocks: [
            {
              type: "ul",
              items: [
                "**Toolbar**: back to the projects, application name (click to rename it), **Save**, **Undo**, **Run (F9)** in green, **Stop** in red, **Open in browser** (web), **Show the project folder**, **Export the .py file**, **Ask the AI**, **Chat with Claude Code**, alignment, **Snap to grid** and **Show output**.",
                "**Palette**: a bar of icons; hovering shows the component's name. Drag it onto the form or add it with a double click.",
                "**Tree**: the window and its components, with those inside a frame or a page indented.",
                "**Inspector**: **Properties** and **Events** of the selected component or, if none, of the window.",
                "**Center**: **Design**, **Code** and **Generated Python** tabs. **F12** switches between design and code.",
              ],
            },
            { type: "img", src: shot("designer"), alt: "Designer with the calculator", caption: "The example calculator in the Designer." },
          ],
        },
        {
          id: "components",
          title: "Components",
          blocks: [
            {
              type: "p",
              text: "Every component has a **Name**, a position and a size. Almost all accept **Background color**, **Text color** and font (**Font**, **Font size**, **Bold**, **Italic**), and the mouse events (**Click**, **Double click**, **Right click**, **Mouse enter**, **Mouse leave**). Typing components add the keyboard ones (**Focus in**, **Focus out**, **Key down**, **Key up**, **Enter key**).",
            },
            {
              type: "table",
              head: ["Component", "Own properties", "Main events"],
              rows: [
                ["**Label** (`Label`)", "Text, Alignment, Justification, Relief, Line wrap", "Mouse"],
                ["**Button** (`Button`)", "Text, State, Relief", "**On press** (`Button1_click`)"],
                ["**Text field** (`Entry`)", "Initial text, Justification, Mask with (e.g. `*` for passwords), State, Linked table and Linked field", "Keyboard and mouse"],
                ["**Password** (`Password`)", "Placeholder text, Button to show the password, Maximum length, State", "Keyboard and mouse"],
                ["**Image** (`Image`)", "File (in the project's `images` folder), Fit (original size, whole without distortion, fill and crop, stretch), Border", "Mouse"],
                ["**Long text** (`Text`)", "Initial text (several lines), Line wrap, State", "Keyboard and mouse"],
                ["**Checkbox** (`Checkbutton`)", "Text, State, Checked", "**On press**"],
                ["**Option** (`Radiobutton`)", "Text, State, Group, Value, Checked", "**On press**"],
                ["**List** (`Listbox`)", "Items (one per line), Selection (browse, single, multiple, extended)", "**On select**"],
                ["**Drop-down list** (`Combobox`)", "Items (one per line), Initial text, Justification, State (normal, readonly, disabled)", "**On select**"],
                ["**Slider** (`Scale`)", "Title, From, Until, Step, Value, Orientation, Show value", "**On change** (receives the value)"],
                ["**Frame** (`Frame`)", "Relief, Border. Holds other components", "Mouse"],
                ["**Canvas** (`Canvas`)", "Background color. For drawing from code", "Mouse, **Drag**, **Button release**, **Mouse move**"],
                ["**Data table** (`Treeview`)", "Data source, SQL query, Columns (field|title|width), Limit, Sequence, Load on open", "**On select**"],
                ["**Progress bar** (`Progressbar`)", "Value, Maximum, Mode (determinate or indeterminate), Orientation", "Mouse"],
                ["**Page control** (`PageControl`)", "Pages (one per line), Active page. Each page holds its own components", "**On page change**"],
                ["**Status bar** (`StatusBar`)", "Text. Always takes the bottom edge of the window", "Mouse"],
                ["**Ribbon** (`Ribbon`)", "Tabs, groups and buttons (indented; “Button | icon”), Active tab", "**On button press**, **On tab change**"],
                ["**Menu** (`Menu`)", "Options (one per line; indent = submenu; `-` = separator). Non-visual: shown at the top of the window", "**On choosing an option** (receives the option)"],
                ["**Timer** (`Timer`)", "Interval (ms), Active. Non-visual", "**Every interval**"],
                ["**API integration** (`RestClient`)", "Base URL, Authentication (none, Bearer token, basic or a key in a header; the secret, preferably in an environment variable), Headers, Timeout. Non-visual", "**When a call finishes**, **If a call fails**"],
                ["**Tray icon** (`TrayIcon`)", "Hover text, Image, Menu (one option per line). Non-visual", "**On icon click**, **On choosing a menu option**"],
                ["**Open dialog** (`OpenDialog`)", "Title, Types (“Text|*.txt”), Default extension, Initial folder, Choose several files. Non-visual", "**On choosing a file**"],
                ["**Save dialog** (`SaveDialog`)", "Title, Types, Default extension, Initial folder, File name, Ask before overwriting. Non-visual", "**On choosing a file**"],
                ["**Data connection** (`Connection`)", "Connection (one of those saved in **Databases**). Non-visual", "—"],
              ],
            },
            {
              type: "note",
              text: "Menu, Progress bar, Status bar, Timer and Page control arrive with version 1.0.5; Password, Image, Ribbon, API integration, Tray icon and the Open and Save dialogs, with 1.0.6. In a web app, components without an equivalent say so in the inspector.",
            },
          ],
        },
        {
          id: "editing",
          title: "Moving, aligning and editing",
          blocks: [
            {
              type: "ul",
              items: [
                "Click selects; dragging moves; the handles resize. With **Snap to grid** on, everything fits the grid.",
                "The arrow keys move the selection one grid step; with Alt (Option), one pixel; with Shift, they resize.",
                "With two or more components selected, **Align left**, **Center horizontally**, **Align right**, **Align top**, **Center vertically**, **Align bottom**, **Same width** and **Same height** become available (relative to the first one selected).",
                "Right-click offers **Cut**, **Copy**, **Paste**, **Delete**, **Bring to front** and **Send to back**. What you copy can be pasted in another window, children included.",
                "**Undo** (⌘Z / Ctrl+Z) reverts each design change. If the code was edited by hand after a step, that step restores the design but not the code, and you are told so.",
              ],
            },
          ],
        },
        {
          id: "events",
          title: "Events and code",
          blocks: [
            {
              type: "p",
              text: "The window's code is a Python class named after the form that inherits from `FormDesign`, the class the studio generates. `self.root` is the window and each component is `self.<Name>`.",
            },
            {
              type: "ul",
              items: [
                "Double-clicking a component opens its main event (`Button1_click`, `Listbox1_select`…) and creates it if needed.",
                "On the inspector's **Events** tab you type or choose the method for each event; **Go to code** jumps to it.",
                "Renaming a component renames its default methods and the references in the code.",
                "The window has its own events: **On open** (`form_create`), **On close**, **Key down** and **On resize**, and its properties **Title**, **Background color**, **Resizable** and **Always on top**.",
              ],
            },
            {
              type: "code",
              code: 'class Form1(FormDesign):\n    def form_create(self):\n        self.total = 0\n        self.StatusBar1.config(text="Ready")\n\n    def Button1_click(self):\n        self.total += 1\n        self.Label1.config(text=f"Clicked {self.total} times")',
            },
            {
              type: "note",
              tone: "warn",
              text: "Put what should happen at startup in the **On open** event (`form_create`). If you define your own `__init__`, call `super().__init__()` first.",
            },
            { type: "img", src: shot("designer-code"), alt: "The Designer's Code tab", caption: "The Code tab: the window class with its handlers." },
          ],
        },
        {
          id: "generated",
          title: "Generated Python and export",
          blocks: [
            {
              type: "p",
              text: "The **Generated Python** tab shows, read-only, the complete file that runs: the design turned into code plus your class. When you run, it is written to `build/<project>.py` inside the project folder.",
            },
            {
              type: "p",
              text: "**Export the .py file** saves that file wherever you want. It works with any Python 3 with tkinter (or Flask, for web apps) without the studio.",
            },
            { type: "img", src: shot("designer-generated"), alt: "Generated Python tab", caption: "The generated Python: not edited, rebuilt from the design and the code." },
          ],
        },
        {
          id: "running",
          title: "Run, stop and see the output",
          blocks: [
            {
              type: "ul",
              items: [
                "**Run (F9)** saves the project and launches the window in its own system window, with your user's permissions.",
                "**Stop** closes the running window or server.",
                "**Show output** opens the panel with what the app writes (`print`, Python errors) and the Python used.",
                "For a web app, the studio starts the Flask server on this computer and opens the browser; **Open in browser** opens it again. It can only be reached from this computer.",
              ],
            },
          ],
        },
        {
          id: "data",
          title: "Data connections",
          blocks: [
            {
              type: "ol",
              items: [
                "Save the database in the **Databases** module (SQLite, PostgreSQL or MySQL/MariaDB).",
                "Add a **Data connection** to the form and choose that connection in its **Connection** property.",
                "Add a **Data table**, choose the connection in **Data source** and write the **SQL query** and the **Columns** (`field|title|width`).",
                "To edit the selected row, link a **Text field** with **Linked table** and **Linked field**.",
              ],
            },
            {
              type: "p",
              text: "From code, `self.Connection1.query(sql, params)` returns rows and `self.Connection1.execute(sql, params)` changes data (always with `?` parameters, never by joining text). `self.Treeview1_refresh()` reloads the table.",
            },
            {
              type: "note",
              text: "Passwords are never written to the generated file: they reach the process in `DMSTUDIO_DB_…` environment variables. An exported file reads them from the environment.",
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 4
    {
      slug: "ai-in-the-designer",
      title: "AI in the Designer",
      summary: "Chat with Claude Code and “Ask the AI”.",
      sections: [
        {
          id: "claude-code",
          title: "Chat with Claude Code",
          blocks: [
            {
              type: "p",
              text: "The **Chat with Claude Code** button (the robot on the toolbar) opens a panel on the right. Describe the change and press Enter (Shift+Enter adds a new line).",
            },
            {
              type: "ul",
              items: [
                "It uses the Claude Code installed on your computer and your session: no API key needed.",
                "Before each message the studio saves the project. Claude Code reads and edits the design (`project.dmsproj`) and the window's code, without a terminal.",
                "When it finishes, the new design and code are loaded into the Designer as a single step that can be undone.",
                "The conversation continues between messages; the trash button starts a new one.",
              ],
            },
            { type: "img", src: shot("designer-claude"), alt: "Claude Code panel in the Designer", caption: "The Claude Code panel, to the right of the form." },
          ],
        },
        {
          id: "ask",
          title: "Ask the AI",
          blocks: [
            {
              type: "p",
              text: "**Ask the AI** uses the provider set in **Settings** (Claude by default) and has three modes:",
            },
            {
              type: "ul",
              items: [
                "**Switch** changes the current window (“Add a phone field and align the buttons”).",
                "**New window** designs a window from scratch; you can **Attach a sketch** (an image).",
                "**Code of** a component: with a component selected, it writes the method for its main event.",
              ],
            },
            {
              type: "p",
              text: "The answer arrives as an **AI proposal**: you review it before applying it and, once applied, it is undone in one step.",
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 5
    {
      slug: "editor",
      title: "The Editor",
      summary: "Code editor with explorer, search, terminal, git and AI.",
      sections: [
        {
          id: "open",
          title: "Opening a folder",
          blocks: [
            {
              type: "p",
              text: "With no folder open you get **Open folder…**, **Open DMarlon Studio** (the studio's documents folder), **Clone repository…** and the list of **Recent** folders.",
            },
            {
              type: "p",
              text: "If a project is open in the Designer, the Editor shows its code and its generated Python as **Project open in the Interface designer**: what you type here is the same text as in the Code tab.",
            },
            { type: "img", src: shot("editor"), alt: "The Editor with the calculator folder", caption: "The Editor: activity bar, explorer and tabs." },
          ],
        },
        {
          id: "files",
          title: "Explorer and tabs",
          blocks: [
            {
              type: "ul",
              items: [
                "The activity bar holds **Explorer**, **Search**, **Source control**, **Claude: implement** and **AI chat**, with the terminal and **Open folder** at the bottom.",
                "The explorer offers **New file**, **New folder**, **Rename**, **Delete**, **Copy path**, **Open in terminal** and **Collapse all**.",
                "Tabs have syntax highlighting for dozens of languages and line numbers. ⌘S / Ctrl+S saves; closing something unsaved asks first.",
                "Anything unsaved is kept when you switch modules.",
              ],
            },
          ],
        },
        {
          id: "search",
          title: "Find and replace",
          blocks: [
            {
              type: "ul",
              items: [
                "**Find in file** with **Replace** and **Replace all**.",
                "The **Search** panel goes through every file in the folder, with **Match case** and **Regular expression**; a click opens the file at that line.",
              ],
            },
          ],
        },
        {
          id: "terminal",
          title: "Terminal",
          blocks: [
            {
              type: "p",
              text: "⌘J / Ctrl+J shows or hides the terminal, which runs commands in the open folder (`git status`, `python3 app.py`, `npm install`…). The up and down arrows go through the history and **Stop** ends the running command.",
            },
          ],
        },
        {
          id: "git",
          title: "Source control (git)",
          blocks: [
            {
              type: "ul",
              items: [
                "**Changes**: modified files with their diff; type the **Commit message** and use **Commit all** or **Commit and push**. Also **Amend last commit** and **Undo last commit**.",
                "**Push**, **Pull** and **Check the remote for changes (fetch)**, with what is pending each way.",
                "**History** of the branch or of **All branches**: view the commit, **Revert this commit**, **Apply to the current branch (cherry-pick)**, create a branch or a tag from it and **Reset the branch to this commit…**.",
                "Local and remote **Branches**: create, switch, **Merge**, rename and delete (also on the remote).",
                "**Stash changes** to switch branches and bring them back later.",
                "**Remotes…**, **Initialize repository**, **Clone repository…** and **Publish to GitHub…** (public or private) with your **GitHub account** (a token with the “repo” scope).",
              ],
            },
          ],
        },
        {
          id: "claude-implement",
          title: "Claude: implement",
          blocks: [
            {
              type: "p",
              text: "**Claude: implement** asks Claude for a change through the Anthropic API (Claude Opus 5.5 by default). Claude explores the open folder (lists, reads and searches files) and proposes changes to one or more files.",
            },
            {
              type: "ul",
              items: [
                "Nothing is written until you apply it: the **Proposed changes** list shows each file with its added and removed lines; a click opens the diff with **Apply** and **Discard**.",
                "**Apply all** writes every change; if a file changed on disk while Claude was working, you are warned instead of it being overwritten.",
                "It needs the Anthropic key in **Settings → Artificial intelligence**.",
              ],
            },
          ],
        },
        {
          id: "chat",
          title: "AI chat",
          blocks: [
            {
              type: "p",
              text: "The **AI chat** answers about the open file with the provider from **Settings**. If it proposes the whole file, **Apply to the file** puts it in the tab (unsaved) and **Copy the code** copies it.",
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 6
    {
      slug: "databases",
      title: "Databases",
      summary: "Connections, tables, SQL queries and CSV export.",
      sections: [
        {
          id: "connections",
          title: "Connections",
          blocks: [
            {
              type: "p",
              text: "**+** adds a SQLite, PostgreSQL, MySQL / MariaDB or MongoDB connection, with server, port, database, user, password and **Encrypted connection (SSL)** depending on the type. **Test connection** checks it can be reached.",
            },
            {
              type: "p",
              text: "The connections saved here are the ones the Designer's windows can use through the **Data connection** component.",
            },
            { type: "img", src: shot("databases"), alt: "Database manager", caption: "A SQLite database with its tables and the query editor." },
          ],
        },
        {
          id: "queries",
          title: "Tables and queries",
          blocks: [
            {
              type: "ul",
              items: [
                "The table list can be narrowed with **Filter tables**; each table opens a sample query.",
                "**Run** executes the query in the editor and shows the result in a grid.",
                "Anything that changes data asks for confirmation first.",
                "**CSV** saves the full result to a file.",
              ],
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 7
    {
      slug: "api",
      title: "API client",
      summary: "HTTP requests with collections, variables and history.",
      sections: [
        {
          id: "requests",
          title: "Requests",
          blocks: [
            {
              type: "ul",
              items: [
                "Pick the method (GET, POST, PUT, PATCH, DELETE…), type the URL and click **Send**.",
                "**Parameters**, **Headers**, **Body** (JSON, form or text) and **Authorization** (none, Bearer or Basic) tabs.",
                "The response shows the status code, the time, the headers and the body.",
                "**Copy as curl** gets the request ready for the terminal.",
              ],
            },
            { type: "img", src: shot("api"), alt: "API client", caption: "A request saved in the GitHub collection." },
          ],
        },
        {
          id: "collections",
          title: "Collections, variables and history",
          blocks: [
            {
              type: "ul",
              items: [
                "**Save** stores the request in a **Collection**; **Save as new…** makes a copy.",
                "**Environment variables…** defines values such as `base_url` or `token`, used in the URL, headers and body as `{{base_url}}`.",
                "The **History** keeps the last 100 requests sent; **Clear history** empties it.",
              ],
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 8
    {
      slug: "ftp",
      title: "FTP",
      summary: "FTP, FTPES and FTPS servers.",
      sections: [
        {
          id: "servers",
          title: "Servers and files",
          blocks: [
            {
              type: "ul",
              items: [
                "**+** adds a server with its **Security**: **FTP (unencrypted)**, **FTPES (explicit TLS)** or **FTPS (implicit TLS)**.",
                "Choose a server to browse its folders; **Parent folder** goes up a level.",
                "**Upload files**, **Download**, **New folder**, **Rename…** and **Delete** (folders, with their contents).",
              ],
            },
            { type: "img", src: shot("ftp"), alt: "FTP client", caption: "The FTP client, ready to add a server." },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 9
    {
      slug: "diagrams",
      title: "Diagrams",
      summary: "Flowcharts and database diagrams, with AI and PDF.",
      sections: [
        {
          id: "kinds",
          title: "Flowcharts and database diagrams",
          blocks: [
            {
              type: "ul",
              items: [
                "**Flowchart**: **Start / end**, **Process**, **Decision**, **Input / output** and **Note** shapes. Press → next to a shape to connect it to another; connections can have a label (e.g. “Yes”).",
                "**Database**: tables with their columns, **Primary key** and foreign keys, and the relations between tables. **Diagram SQL** shows the SQL that creates it.",
                "**From a database** draws the diagram of a saved connection (optionally, only the tables starting with a prefix).",
                "**With AI** creates the diagram from a description and **Change with AI** modifies it.",
                "**Arrange** lays the shapes out again and **Export to PDF** saves it for printing or sharing.",
              ],
            },
            { type: "img", src: shot("diagrams"), alt: "Flowchart", caption: "A flowchart for registering a customer." },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 10
    {
      slug: "settings",
      title: "Settings",
      summary: "Language, appearance and artificial intelligence.",
      sections: [
        {
          id: "ai",
          title: "Artificial intelligence",
          blocks: [
            {
              type: "p",
              text: "Choose the provider (**Vendor**): Anthropic (Claude), OpenAI, Gemini, xAI, DeepSeek, Mistral, Groq, Cohere, OpenRouter, Perplexity, Ollama or a compatible custom API. Type the **API key** and the **Model**; **Fetch models** lists those on your account. Claude (`claude-opus-5-5`) is the default provider.",
            },
            {
              type: "p",
              text: "The key is stored on this computer only. Each provider remembers its key and model when you switch between them.",
            },
            { type: "img", src: shot("settings"), alt: "Settings", caption: "Settings: language, appearance, artificial intelligence and version." },
          ],
        },
        {
          id: "other",
          title: "Language, appearance and version",
          blocks: [
            {
              type: "ul",
              items: [
                "**Language**: Español or English, instantly.",
                "**Appearance**: System, Light or Dark.",
                "**About** shows the installed version.",
              ],
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 11
    {
      slug: "shortcuts",
      title: "Keyboard shortcuts",
      summary: "Every Designer and Editor shortcut.",
      sections: [
        {
          id: "designer",
          title: "Designer",
          blocks: [
            {
              type: "table",
              head: ["Shortcut", "Action"],
              rows: [
                ["F9", "Run"],
                ["F12", "Switch between design and code"],
                ["⌘S / Ctrl+S", "Save the project"],
                ["⌘Z / Ctrl+Z", "Undo"],
                ["⌘C, ⌘X, ⌘V (Ctrl on Windows)", "Copy, cut and paste components"],
                ["Delete / Backspace", "Delete the selection"],
                ["Arrows", "Move one grid step (with Alt, one pixel)"],
                ["Shift + arrows", "Resize"],
                ["Double-click on the palette", "Add the component"],
                ["Double-click on a component", "Open its main event"],
                ["Enter in a chat", "Send (Shift+Enter: new line)"],
              ],
            },
          ],
        },
        {
          id: "editor",
          title: "Editor",
          blocks: [
            {
              type: "table",
              head: ["Shortcut", "Action"],
              rows: [
                ["⌘S / Ctrl+S", "Save the file"],
                ["⌘J / Ctrl+J", "Show or hide the terminal"],
                ["↑ / ↓ in the terminal", "Go through the command history"],
                ["Enter in a chat", "Send (Shift+Enter: new line)"],
              ],
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 12
    {
      slug: "troubleshooting",
      title: "Troubleshooting",
      summary: "The most common messages and how to solve them.",
      sections: [
        {
          id: "python",
          title: "Python not found, or no tkinter",
          blocks: [
            {
              type: "ul",
              items: [
                "**Python was not found**: install it (python.org or Homebrew) and click **Look for Python again** on the project list.",
                "**Found … but it does not include tkinter**: on macOS, `brew install python-tk`; on Linux, `sudo apt install python3-tk`; on Windows, reinstall Python ticking **tcl/tk and IDLE**.",
                "**Tk 8.5 is old and does not honor the colors of the design**: that is the Python bundled with macOS. Install one from python.org or Homebrew.",
              ],
            },
          ],
        },
        {
          id: "flask",
          title: "Flask is missing",
          blocks: [
            {
              type: "p",
              text: "Web apps need Flask in the same Python. The **Flask is missing** message shows the exact command, for example `python3 -m pip install flask`.",
            },
          ],
        },
        {
          id: "unsigned",
          title: "The app won't open (unsigned)",
          blocks: [
            {
              type: "ul",
              items: [
                "**macOS**: the first time, right-click DMarlon Studio → **Open** → **Open**.",
                "**Windows**: on “Windows protected your PC”, **More info** → **Run anyway**.",
              ],
            },
          ],
        },
        {
          id: "root",
          title: "AttributeError: 'Form1' object has no attribute 'root'",
          blocks: [
            {
              type: "p",
              text: "This happened when the window's code defined its own `__init__` without calling `super().__init__()`: that method replaced the one that creates the window. Since version 1.0.5 the window and its components are created before your `__init__`, and the **On open** event runs after it.",
            },
            {
              type: "code",
              code: "class Form1(FormDesign):\n    def __init__(self):\n        super().__init__()   # first\n        self.current = \"0\"\n\n    # Even better: the On open event\n    def form_create(self):\n        self.current = \"0\"",
            },
          ],
        },
        {
          id: "claude",
          title: "Claude Code was not found",
          blocks: [
            {
              type: "p",
              text: "Install Claude Code from claude.com/claude-code and run `claude` once in a terminal to sign in. The studio looks for it on the PATH and in `~/.local/bin`.",
            },
          ],
        },
      ],
    },
    // ------------------------------------------------------------------ 13
    {
      slug: "roadmap",
      title: "Roadmap",
      summary: "What comes next.",
      sections: [
        {
          id: "targets",
          title: "More targets",
          blocks: [
            {
              type: "p",
              text: "The same designer will generate and compile apps for more environments. You will choose the target when creating a project:",
            },
            {
              type: "table",
              head: ["Target", "Status"],
              rows: [
                ["Python + tkinter (desktop)", "Available"],
                ["Python + Flask (web)", "Available"],
                ["Electron + React", "On the way"],
                ["C++ with FLTK", "On the way"],
                ["Pascal with Lazarus (LCL)", "On the way"],
              ],
            },
          ],
        },
        {
          id: "projects",
          title: "Richer projects",
          blocks: [
            {
              type: "ul",
              items: [
                "Several forms per project, with a **Project** node in the tree.",
                "The application icon, set in the project.",
                "Building executables (PyInstaller for Python).",
              ],
            },
          ],
        },
      ],
    },
  ],
};
