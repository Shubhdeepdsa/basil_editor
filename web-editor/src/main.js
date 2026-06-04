import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import BubbleMenu from '@tiptap/extension-bubble-menu'
import Placeholder from '@tiptap/extension-placeholder'
import { Markdown } from '@tiptap/markdown'
import { createLowlight, common } from 'lowlight'
import './style.css'

const lowlight = createLowlight(common)

const CustomCodeBlock = CodeBlockLowlight.extend({
  addNodeView() {
    return ({ node, HTMLAttributes }) => {
      const dom = document.createElement('div')
      dom.classList.add('code-block-wrapper')

      const copyButton = document.createElement('button')
      copyButton.classList.add('copy-button')
      copyButton.innerText = 'Copy'
      copyButton.contentEditable = 'false'
      copyButton.addEventListener('click', () => {
        const text = node.textContent
        navigator.clipboard.writeText(text).then(() => {
          copyButton.innerText = 'Copied!'
          setTimeout(() => {
            copyButton.innerText = 'Copy'
          }, 2000)
        })
      })

      const pre = document.createElement('pre')
      const code = document.createElement('code')
      
      Object.entries(HTMLAttributes).forEach(([key, value]) => {
        pre.setAttribute(key, value)
      })

      pre.appendChild(code)
      dom.appendChild(pre)
      dom.appendChild(copyButton)

      return {
        dom,
        contentDOM: code,
      }
    }
  },
})

try {
  // Create Bubble Menu element (don't append manually, Tiptap handles it)
  const menuEl = document.createElement('div')
  menuEl.className = 'bubble-menu'
  menuEl.innerHTML = `
    <button data-command="bold">Bold</button>
    <button data-command="h1">H1</button>
    <button data-command="h2">H2</button>
    <button data-command="bulletList">Bullet</button>
    <button data-command="codeBlock">Code</button>
  `

  const editor = new Editor({
    element: document.querySelector('#editor'),
    extensions: [
      StarterKit.configure({
        codeBlock: false,
      }),
      CustomCodeBlock.configure({
        lowlight,
      }),
      BubbleMenu.configure({
        element: menuEl,
        tippyOptions: {
          duration: 150,
          animation: 'scale-subtle',
          zIndex: 999,
        },
      }),
      Placeholder.configure({
        placeholder: 'Start writing...',
      }),
      Markdown,
    ],
    content: '',
    contentType: 'markdown',
    autofocus: 'end',
    onUpdate({ editor }) {
      const markdown = editor.getMarkdown();
      window.webkit?.messageHandlers?.onContentChange?.postMessage(markdown);
      
      const text = editor.getText();
      const wordCount = text.trim() ? text.trim().split(/\s+/).length : 0;
      window.webkit?.messageHandlers?.onWordCountChange?.postMessage(wordCount);
    },
  });

  // Handle Bubble Menu button clicks
  menuEl.addEventListener('mousedown', (e) => {
    e.preventDefault() // Prevent losing editor focus
    if (!editor.isEditable) return

    const command = e.target.getAttribute('data-command')
    if (!command) return

    if (command === 'bold') editor.chain().focus().toggleBold().run()
    if (command === 'h1') editor.chain().focus().toggleHeading({ level: 1 }).run()
    if (command === 'h2') editor.chain().focus().toggleHeading({ level: 2 }).run()
    if (command === 'bulletList') editor.chain().focus().toggleBulletList().run()
    if (command === 'codeBlock') editor.chain().focus().toggleCodeBlock().run()
  })

  // Update active state of menu buttons
  editor.on('selectionUpdate', () => {
    menuEl.querySelectorAll('button').forEach(btn => {
      const command = btn.getAttribute('data-command')
      let active = false
      if (command === 'bold') active = editor.isActive('bold')
      if (command === 'h1') active = editor.isActive('heading', { level: 1 })
      if (command === 'h2') active = editor.isActive('heading', { level: 2 })
      if (command === 'bulletList') active = editor.isActive('bulletList')
      if (command === 'codeBlock') active = editor.isActive('codeBlock')
      
      btn.classList.toggle('is-active', active)
    })
  })

  // Focus editor on click anywhere in body
  document.addEventListener('click', (e) => {
    if (e.target.closest('#editor') || e.target.closest('.bubble-menu')) return
    editor.chain().focus().run()
  });

  window.updateContent = (content) => {
    if (editor.getMarkdown() !== content) {
      editor.commands.setContent(content, { contentType: 'markdown', emitUpdate: false });
    }
  };

  window.setEditable = (isEditable) => {
    editor.setEditable(isEditable);
  };
} catch (e) {
  console.error("Tiptap Initialization Failed: " + e.message);
}
