import morphdom from "morphdom";

export function morphPatch(fromNode, toNode) {
  return morphdom(fromNode, toNode, {
    getNodeKey(node) {
      if (!node) return null;
      if (node.id) return node.id;
      if (node.getAttribute) return node.getAttribute("data-key");
      return null;
    },
    onBeforeElUpdated(fromEl, toEl) {
      const isActive = document.activeElement === fromEl;

      if (
        isActive &&
        fromEl instanceof HTMLInputElement &&
        toEl instanceof HTMLInputElement
      ) {
        const type = (fromEl.type || "").toLowerCase();
        const preserveValue =
          type === "" ||
          type === "text" ||
          type === "search" ||
          type === "email" ||
          type === "url" ||
          type === "tel" ||
          type === "password" ||
          type === "number";

        if (preserveValue) {
          toEl.value = fromEl.value;
        }
      }

      if (
        isActive &&
        fromEl instanceof HTMLTextAreaElement &&
        toEl instanceof HTMLTextAreaElement
      ) {
        toEl.value = fromEl.value;
      }
      return true;
    },
  });
}
