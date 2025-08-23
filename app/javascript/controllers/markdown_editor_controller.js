import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.loadEasyMDE()
  }

  loadEasyMDE() {
    if (typeof EasyMDE === 'undefined') {
      // Load EasyMDE CSS
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://cdn.jsdelivr.net/npm/easymde/dist/easymde.min.css'
      document.head.appendChild(link)

      // Load EasyMDE JS
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/easymde/dist/easymde.min.js'
      script.onload = () => this.initializeEditor()
      document.head.appendChild(script)
    } else {
      this.initializeEditor()
    }
  }

  initializeEditor() {
    const editor = new EasyMDE({
      element: this.element,
      spellChecker: false,
      autosave: {
        enabled: true,
        uniqueId: this.element.id || "markdown-editor",
        delay: 1000,
      },
      toolbar: [
        "bold", "italic", "heading", "|",
        "quote", "unordered-list", "ordered-list", "|",
        "link", "image", "|",
        "preview", "side-by-side", "fullscreen", "|",
        "guide"
      ],
      status: ["autosave", "lines", "words"],
      previewRender: (plainText) => {
        // This will use the same markdown renderer as the backend
        return this.customMarkdownRender(plainText)
      }
    })

    // Store editor instance for later use
    this.editor = editor
  }

  customMarkdownRender(plainText) {
    // Basic markdown rendering for preview
    // In production, you might want to make an AJAX call to render server-side
    let html = plainText
      .replace(/^### (.*$)/gim, '<h3>$1</h3>')
      .replace(/^## (.*$)/gim, '<h2>$1</h2>')
      .replace(/^# (.*$)/gim, '<h1>$1</h1>')
      .replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>')
      .replace(/\n/g, '<br>')
    
    return html
  }

  disconnect() {
    if (this.editor) {
      this.editor.toTextArea()
      this.editor = null
    }
  }
}