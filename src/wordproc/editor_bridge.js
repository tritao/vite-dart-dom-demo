import { Editor } from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";

const editors = new WeakMap();

function parseJsonString(json) {
  if (json == null || json === "") return null;
  if (typeof json !== "string") return json;
  try {
    return JSON.parse(json);
  } catch {
    return null;
  }
}

function toJsonString(value) {
  try {
    return JSON.stringify(value);
  } catch {
    return "{}";
  }
}

function emitChanged(mount, editor) {
  const detail = toJsonString(editor.getJSON());
  mount.dispatchEvent(new CustomEvent("wordproc:editor-changed", { detail }));
}

globalThis.wordprocEditorInit = (mount, initialJson) => {
  if (!mount) throw new Error("wordprocEditorInit: mount is required");
  if (editors.has(mount)) return;

  mount.textContent = "";
  mount.classList.add("wordproc-editor-host");

  const editor = new Editor({
    element: mount,
    extensions: [StarterKit],
    content: parseJsonString(initialJson) ?? undefined,
    editorProps: {
      attributes: {
        "data-testid": "wordproc-editor",
        "aria-label": "Editor",
      },
    },
  });

  editors.set(mount, editor);

  editor.on("update", () => emitChanged(mount, editor));
  editor.on("create", () => emitChanged(mount, editor));

  mount.dispatchEvent(new CustomEvent("wordproc:editor-ready", { detail: {} }));
};

globalThis.wordprocEditorDestroy = (mount) => {
  const editor = mount ? editors.get(mount) : null;
  if (!editor) return;
  try {
    editor.destroy();
  } finally {
    editors.delete(mount);
  }
};

globalThis.wordprocEditorSetDoc = (mount, json) => {
  const editor = mount ? editors.get(mount) : null;
  if (!editor) return;
  const doc = parseJsonString(json);
  if (!doc) return;
  // Avoid emitting update events when switching sections.
  editor.commands.setContent(doc, false);
};

globalThis.wordprocEditorGetDoc = (mount) => {
  const editor = mount ? editors.get(mount) : null;
  if (!editor) return null;
  return toJsonString(editor.getJSON());
};
