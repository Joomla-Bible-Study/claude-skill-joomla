# Admin URL Routing (`task=` vs `view=`)

Joomla admin URLs use two patterns, and choosing the wrong one is the single most common cause of "two users overwriting each other's edits" bugs. Understanding when each pattern applies — and how to render list-view links so checkout is triggered — is non-negotiable for any component with multi-user editing.

## `task=` routing — triggers a controller action

The task format is `{controller}.{method}`:

```
index.php?option=com_example&task=item.edit&id=5
```

This calls `ItemController::edit()` (FormController), which:

1. Checks out the record (sets `checked_out` to current user and `checked_out_time` to now).
2. Stores the return URL so the cancel/save flow can return there.
3. Redirects to the edit view.

## `view=` routing — displays a view directly (no controller action)

```
index.php?option=com_example&view=items         → List view
index.php?option=com_example&view=item&id=5     → Detail/edit view (NO checkout)
```

## When to use which

| Context | URL Pattern | Why |
|---------|-------------|-----|
| List → edit link | `task=item.edit&id=5` | Checks out the record to prevent concurrent edits |
| Toolbar "New" button | `task=item.add` | Creates a new record context |
| Submenu / menu link | `view=items` | Just display, no action needed |
| After save redirect | `view=items` or `view=item&id=5` | Display only, save already handled |
| Form action (POST) | Task set via hidden field | `<input type="hidden" name="task" value="">` — JS sets this on submit |

**Common mistake:** Using `view=item&layout=edit&id=5` to link from a list — this skips checkout, so two users can open the same record simultaneously and overwrite each other's changes.

## Checked-out handling in list templates

```php
<?php
$isCheckedOut = !empty($item->checked_out) && $item->checked_out != $userId;

if ($isCheckedOut) {
    // Show lock icon + plain text (another user is editing)
    echo HTMLHelper::_('jgrid.checkedout', $i, $item->editor, $item->checked_out_time, 'items.', $canCheckin);
    echo $this->escape($item->title);
} elseif ($canEdit) {
    // Editable — link via task routing (triggers checkout)
    echo '<a href="' . Route::_('index.php?option=com_example&task=item.edit&id=' . $item->id) . '">';
    echo $this->escape($item->title) . '</a>';
} else {
    // No permission — plain text
    echo $this->escape($item->title);
}
?>
```

## Including the editor name in the list query

To show "who has it checked out" in the lock UI, JOIN the users table in your list model:

```php
$query->select($db->quoteName('uc.name', 'editor'))
    ->join('LEFT', $db->quoteName('#__users', 'uc'), $db->quoteName('uc.id') . ' = ' . $db->quoteName('a.checked_out'));
```

The aliased `editor` column is what `HTMLHelper::_('jgrid.checkedout', …)` reads.

## Related

- The `checked_out` / `checked_out_time` columns themselves are part of the standard schema — see [`database.md`](database.md).
- The model lifecycle that clears these on save lives in [`component-lifecycle.md`](component-lifecycle.md).
- SEF / frontend routing (a separate concern) is in [`component-router.md`](component-router.md).
