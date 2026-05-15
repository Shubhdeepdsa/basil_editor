import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
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
      
      // Transfer attributes like language class
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
  const editor = new Editor({
    element: document.querySelector('#editor'),
    extensions: [
      StarterKit.configure({
        codeBlock: false, // Disable default code block
      }),
      CustomCodeBlock.configure({
        lowlight,
      }),
    ],
    content: '',
    autofocus: 'end',
    onUpdate({ editor }) {
      const html = editor.getHTML();
      window.webkit?.messageHandlers?.onContentChange?.postMessage(html);
    },
  });

  // Force focus on click anywhere in body
  document.body.addEventListener('click', () => {
    editor.chain().focus().run();
  });

  // Bridge to update content from Swift
  window.updateContent = (content) => {
    if (editor.getHTML() !== content) {
      editor.commands.setContent(content, false);
    }
  };
} catch (e) {
  console.error("Tiptap Initialization Failed: " + e.message);
}
