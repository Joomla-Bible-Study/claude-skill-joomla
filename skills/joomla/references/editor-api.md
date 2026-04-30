# Joomla Editor API Reference

Joomla's Editor API provides a unified interface for WYSIWYG editors (TinyMCE, CodeMirror, None/textarea) and editor extension buttons (XTD buttons like "Read More", "Article", "Image").

## JavaScript API: Getting and Setting Editor Content

The modern API uses `JoomlaEditor` (imported from `editor-api`). The legacy `Joomla.editors.instances` is deprecated but still works via a Proxy wrapper.

**Get/set content from JavaScript:**

```javascript
// Modern API (preferred)
import { JoomlaEditor } from 'editor-api';

// Get editor by textarea ID
const editor = JoomlaEditor.get('jform_description');

// Get the currently active (focused) editor
const active = JoomlaEditor.getActive();

// Read content
const html = editor.getValue();

// Replace all content
editor.setValue('<p>New content</p>');

// Get selected text
const selection = editor.getSelection();

// Insert at cursor / replace selection
editor.replaceSelection('<hr id="system-readmore">');

// Disable / enable
editor.disable(false);  // disable
editor.disable(true);   // enable

// Get underlying editor instance (e.g., tinymce object)
const raw = editor.getRawInstance();

// Get editor type name
const type = editor.getType(); // 'tinymce', 'codemirror', 'none'
```

**Legacy API (deprecated but functional):**

```javascript
// Still works but logs deprecation warnings
const editor = Joomla.editors.instances['jform_description'];
editor.getValue();
editor.setValue('content');
editor.replaceSelection('inserted text');
```

## Editor Decorator (Implementing a Custom Editor)

All editors must subclass `JoomlaEditorDecorator` and implement the abstract methods:

```javascript
import JoomlaEditorDecorator from 'editor-decorator';
import { JoomlaEditor } from 'editor-api';

class MyEditorDecorator extends JoomlaEditorDecorator {
    getValue() {
        return this.instance.getContent(); // Your editor's get method
    }

    setValue(value) {
        this.instance.setContent(value);
        return this;
    }

    getSelection() {
        return this.instance.getSelectedText();
    }

    replaceSelection(value) {
        this.instance.insertAtCursor(value);
        return this;
    }

    disable(enable) {
        this.instance.setReadOnly(!enable);
        return this;
    }
}

// Register with Joomla
const decorator = new MyEditorDecorator(editorInstance, 'myeditor', textareaId);
JoomlaEditor.register(decorator);
```

**Required methods:** `getValue()`, `setValue()`, `getSelection()`, `replaceSelection()`, `disable()`

## Editor XTD Buttons (Extension Buttons)

XTD buttons appear below the editor (e.g., "Read More", "Article", "Image"). They are plugins in the `editors-xtd` group.

**Creating an XTD button plugin:**

```php
// plugins/editors-xtd/mybutton/src/Extension/MyButton.php
namespace Vendor\Plugin\EditorsXtd\MyButton\Extension;

use Joomla\CMS\Editor\Button\Button;
use Joomla\CMS\Event\Editor\EditorButtonsSetupEvent;
use Joomla\CMS\Language\Text;
use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\Event\SubscriberInterface;

final class MyButton extends CMSPlugin implements SubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return ['onEditorButtonsSetup' => 'onEditorButtonsSetup'];
    }

    public function onEditorButtonsSetup(EditorButtonsSetupEvent $event): void
    {
        $disabled = $event->getDisabledButtons();
        if (\in_array($this->_name, $disabled)) {
            return;
        }

        $wa = $this->getApplication()->getDocument()->getWebAssetManager();
        $wa->registerScript(
            'editor-button.' . $this->_name,
            'plg_editors-xtd_mybutton/button.min.js',
            [],
            ['type' => 'module'],
            ['editors']  // dependency on editor API
        );

        $button = new Button($this->_name, [
            'action'  => 'insert-mywidget',   // Custom action name
            'text'    => Text::_('PLG_MYBUTTON_BUTTON_TEXT'),
            'icon'    => 'star',
            'name'    => $this->_type . '_' . $this->_name,
        ]);

        $event->getButtonsRegistry()->add($button);
    }
}
```

**JavaScript handler for the button action:**

```javascript
// build/media_source/plg_editors-xtd_mybutton/js/button.es6.js
import { JoomlaEditorButton } from 'editor-api';

JoomlaEditorButton.registerAction('insert-mywidget', (editor, options) => {
    editor.replaceSelection('<div class="my-widget">Widget content</div>');
});
```

## Button Action Types

| Action | Behavior | Use Case |
|--------|----------|----------|
| `insert` | Inserts `options.content` at cursor | Simple static content insertion |
| `modal` | Opens `JoomlaDialog` iframe, listens for `postMessage` | Content selection (articles, images, contacts) |
| Custom name | Your registered handler | Any custom logic |

## Modal Button Pattern (Content Selection)

For buttons that open a modal to select content (like the "Article" button):

**PHP — define button with `action: 'modal'`:**

```php
$link = 'index.php?option=com_example&view=items&layout=modal&tmpl=component&'
    . Session::getFormToken() . '=1&editor=' . $event->getEditorId();

$button = new Button($this->_name, [
    'action' => 'modal',
    'link'   => $link,
    'text'   => Text::_('PLG_MYBUTTON_SELECT_ITEM'),
    'icon'   => 'list',
    'name'   => $this->_type . '_' . $this->_name,
], [
    'popupType'  => 'iframe',
    'textHeader' => Text::_('PLG_MYBUTTON_MODAL_TITLE'),
    'modalWidth' => '800px',
    'modalHeight' => '400px',
]);
```

**JavaScript in the modal iframe** — send selection back via `postMessage`:

```javascript
// In the modal's layout template
document.querySelectorAll('.select-link').forEach((el) => {
    el.addEventListener('click', (event) => {
        event.preventDefault();
        const title = event.target.dataset.title;
        const url = event.target.dataset.uri;

        window.parent.postMessage({
            messageType: 'joomla:content-select',
            html: `<a href="${url}">${title}</a>`,
        });
    });
});
```

The parent window's `modal` action handler automatically calls `editor.replaceSelection()` with the received `html` (or `text`) and closes the dialog.

## Editor Form Field (PHP)

The `editor` form field type in XML automatically renders the configured WYSIWYG editor:

```xml
<field
    name="description"
    type="editor"
    label="JGLOBAL_DESCRIPTION"
    filter="\Joomla\CMS\Component\ComponentHelper::filterText"
    buttons="true"
    height="400"
    width="100%"
/>
```

**Attributes:**

| Attribute | Values | Purpose |
|-----------|--------|---------|
| `buttons` | `true`, `false`, or comma-separated list | Show/hide XTD buttons. List = show only named buttons |
| `hide` | Comma-separated list | Hide specific XTD buttons |
| `height` | Pixels (e.g., `500`) | Editor height |
| `width` | CSS value (e.g., `100%`) | Editor width |
| `editor` | Pipe-separated list | Force specific editor(s): `tinymce\|codemirror\|none` |
| `filter` | `\Joomla\CMS\Component\ComponentHelper::filterText` | Server-side HTML filtering (FQCN form — the legacy `JComponentHelper::filterText` alias still resolves on J5/J6 but is slated for removal with the rest of the legacy class aliases) |
| `asset_field` | Field name | Form field containing asset ID (for ACL) |
| `created_by_field` | Field name | Form field containing author ID |
| `syntax` | `html`, `css`, `php`, etc. | Syntax highlighting mode (CodeMirror) |

## Editor Plugin Registration (PHP)

Editor plugins register via the `onEditorSetup` event:

```php
// plugins/editors/myeditor/src/Extension/MyEditor.php
use Joomla\CMS\Event\Editor\EditorSetupEvent;

final class MyEditor extends CMSPlugin implements SubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return ['onEditorSetup' => 'onEditorSetup'];
    }

    public function onEditorSetup(EditorSetupEvent $event): void
    {
        $event->getEditorsRegistry()->add(
            new MyEditorProvider($this->params, $this->getApplication(), $this->getDispatcher())
        );
    }
}
```

The provider extends `AbstractEditorProvider` and implements `display()` (renders the editor HTML) and `getName()` (returns the editor identifier like `'tinymce'`).
