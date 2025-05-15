import tinymce from "tinymce";

// Required core assets
import "tinymce/themes/silver";
import "tinymce/icons/default";
import "tinymce/models/dom";

// Minimal useful plugins
import "tinymce/plugins/link";
import "tinymce/plugins/lists";
import "tinymce/plugins/code";
import "tinymce/plugins/image";

// Required CSS for editor to render properly
import "tinymce/skins/ui/oxide/skin.min.css?inline";
import "tinymce/skins/content/default/content.min.css?inline";

document.addEventListener("turbo:load", () => {
  tinymce.init({
    selector: ".rich-text",
    license_key: 'gpl',
    skin: false,
    content_css: false,
    promotion: false,
    branding: false,
    plugins: ["link", "lists", "code", "image"],
    toolbar: "undo redo | bold italic | bullist numlist | link image | code",

    setup: (editor) => {
      editor.on("init", () => {
        const container = editor.getContainer();
        if (container) container.style.visibility = "visible";
      });
    },
  });
});

document.addEventListener("turbo:before-cache", () => {
  if (tinymce?.remove) tinymce.remove();
});
