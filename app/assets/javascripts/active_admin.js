// ActiveAdmin JavaScript for Propshaft
// Enhanced functionality with modern markdown editor

document.addEventListener('DOMContentLoaded', function() {
  // Handle batch actions checkboxes
  const toggleAll = document.querySelector('#collection_selection_toggle_all');
  if (toggleAll) {
    toggleAll.addEventListener('change', function() {
      const checkboxes = document.querySelectorAll('.collection_selection input[type="checkbox"]');
      checkboxes.forEach(function(checkbox) {
        checkbox.checked = toggleAll.checked;
      });
    });
  }

  // Handle dropdown menus
  const dropdowns = document.querySelectorAll('.dropdown_menu_button');
  dropdowns.forEach(function(dropdown) {
    dropdown.addEventListener('click', function(e) {
      e.preventDefault();
      const menu = dropdown.nextElementSibling;
      if (menu && menu.classList.contains('dropdown_menu_list')) {
        menu.style.display = menu.style.display === 'block' ? 'none' : 'block';
      }
    });
  });

  // Close dropdowns when clicking outside
  document.addEventListener('click', function(e) {
    if (!e.target.closest('.dropdown_menu')) {
      document.querySelectorAll('.dropdown_menu_list').forEach(function(menu) {
        menu.style.display = 'none';
      });
    }
  });

  // Initialize enhanced markdown editor
  const markdownTextareas = document.querySelectorAll('textarea.markdown-editor');
  if (markdownTextareas.length > 0) {
    // Load EasyMDE CSS
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'https://cdn.jsdelivr.net/npm/easymde/dist/easymde.min.css';
    document.head.appendChild(link);

    // Load EasyMDE JS
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/easymde/dist/easymde.min.js';
    script.onload = function() {
      markdownTextareas.forEach(function(textarea) {
        const editor = new EasyMDE({
          element: textarea,
          spellChecker: false,
          autosave: {
            enabled: true,
            uniqueId: textarea.id || "markdown-editor",
            delay: 1000,
            text: "Autosaved: "
          },
          toolbar: [
            {
              name: "bold",
              action: EasyMDE.toggleBold,
              className: "fa fa-bold",
              title: "Bold (Ctrl+B)",
            },
            {
              name: "italic",
              action: EasyMDE.toggleItalic,
              className: "fa fa-italic",
              title: "Italic (Ctrl+I)",
            },
            {
              name: "heading",
              action: EasyMDE.toggleHeadingSmaller,
              className: "fa fa-header",
              title: "Heading (Ctrl+H)",
            },
            "|",
            {
              name: "quote",
              action: EasyMDE.toggleBlockquote,
              className: "fa fa-quote-left",
              title: "Quote (Ctrl+Q)",
            },
            {
              name: "unordered-list",
              action: EasyMDE.toggleUnorderedList,
              className: "fa fa-list-ul",
              title: "Unordered List (Ctrl+L)",
            },
            {
              name: "ordered-list",
              action: EasyMDE.toggleOrderedList,
              className: "fa fa-list-ol",
              title: "Ordered List (Ctrl+Alt+L)",
            },
            "|",
            {
              name: "link",
              action: EasyMDE.drawLink,
              className: "fa fa-link",
              title: "Create Link (Ctrl+K)",
            },
            {
              name: "image",
              action: EasyMDE.drawImage,
              className: "fa fa-picture-o",
              title: "Insert Image (Ctrl+Alt+I)",
            },
            {
              name: "table",
              action: EasyMDE.drawTable,
              className: "fa fa-table",
              title: "Insert Table",
            },
            "|",
            {
              name: "preview",
              action: EasyMDE.togglePreview,
              className: "fa fa-eye no-disable",
              title: "Toggle Preview (Ctrl+P)",
            },
            {
              name: "side-by-side",
              action: EasyMDE.toggleSideBySide,
              className: "fa fa-columns no-disable no-mobile",
              title: "Toggle Side by Side (F9)",
            },
            {
              name: "fullscreen",
              action: EasyMDE.toggleFullScreen,
              className: "fa fa-arrows-alt no-disable no-mobile",
              title: "Toggle Fullscreen (F11)",
            },
            "|",
            {
              name: "guide",
              action: "https://www.markdownguide.org/basic-syntax/",
              className: "fa fa-question-circle",
              title: "Markdown Guide",
            }
          ],
          status: ["autosave", "lines", "words", "cursor"],
          placeholder: "Start writing your post in Markdown...",
          renderingConfig: {
            singleLineBreaks: false,
            codeSyntaxHighlighting: true,
          },
          shortcuts: {
            "toggleBold": "Cmd-B",
            "toggleItalic": "Cmd-I",
            "toggleHeading": "Cmd-H",
            "toggleUnorderedList": "Cmd-L",
            "toggleOrderedList": "Cmd-Alt-L",
            "drawLink": "Cmd-K",
            "togglePreview": "Cmd-P",
            "toggleSideBySide": "F9",
            "toggleFullScreen": "F11"
          },
          previewRender: function(plainText, preview) {
            // Add a loading indicator
            preview.innerHTML = '<div style="text-align: center; padding: 20px;">Loading preview...</div>';
            
            // Simulate markdown rendering (in production, you'd call your server)
            setTimeout(function() {
              // Basic markdown to HTML conversion for preview
              let html = plainText;
              
              // Headers
              html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
              html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
              html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');
              
              // Bold
              html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
              
              // Italic
              html = html.replace(/\*([^*]+)\*/g, '<em>$1</em>');
              
              // Links
              html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
              
              // Line breaks
              html = html.replace(/\n\n/g, '</p><p>');
              html = '<p>' + html + '</p>';
              
              preview.innerHTML = '<div class="markdown-preview-content">' + html + '</div>';
            }, 200);
            
            return "Loading...";
          }
        });

        // Add custom styling to the editor
        const editorContainer = editor.codemirror.getWrapperElement().parentElement;
        editorContainer.classList.add('enhanced-markdown-editor');
        
        // Add word count display
        const statusBar = editorContainer.querySelector('.editor-statusbar');
        if (statusBar) {
          // Update reading time calculation
          editor.codemirror.on("change", function() {
            const text = editor.value();
            const wordCount = text.trim().split(/\s+/).length;
            const readingTime = Math.ceil(wordCount / 200); // 200 words per minute
            
            // Check if reading time element exists
            let readingTimeEl = statusBar.querySelector('.reading-time');
            if (!readingTimeEl) {
              readingTimeEl = document.createElement('span');
              readingTimeEl.className = 'reading-time';
              statusBar.appendChild(readingTimeEl);
            }
            readingTimeEl.textContent = `${readingTime} min read`;
          });
        }
      });
    };
    document.head.appendChild(script);
  }

  // Handle mobile sidebar toggle
  const sidebarToggle = document.createElement('button');
  sidebarToggle.className = 'sidebar-toggle';
  sidebarToggle.innerHTML = '☰';
  sidebarToggle.setAttribute('aria-label', 'Toggle navigation');
  
  sidebarToggle.addEventListener('click', function() {
    const header = document.getElementById('header');
    header.classList.toggle('mobile-open');
  });
  
  // Add toggle button to mobile view
  if (window.innerWidth <= 768) {
    document.body.insertBefore(sidebarToggle, document.body.firstChild);
  }

  // Handle form submission feedback
  const forms = document.querySelectorAll('form');
  forms.forEach(function(form) {
    form.addEventListener('submit', function() {
      const submitButton = form.querySelector('input[type="submit"]');
      if (submitButton) {
        submitButton.value = 'Saving...';
        submitButton.disabled = true;
      }
    });
  });

  // Add smooth scrolling
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
      }
    });
  });

  // Add keyboard shortcuts
  document.addEventListener('keydown', function(e) {
    // Cmd/Ctrl + S to save
    if ((e.metaKey || e.ctrlKey) && e.key === 's') {
      e.preventDefault();
      const form = document.querySelector('form.formtastic');
      if (form) {
        form.submit();
      }
    }
    
    // Cmd/Ctrl + Enter to save and continue editing
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault();
      const form = document.querySelector('form.formtastic');
      if (form) {
        // Add a hidden field to indicate "save and continue"
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = 'commit_action';
        input.value = 'save_and_continue';
        form.appendChild(input);
        form.submit();
      }
    }
  });
});