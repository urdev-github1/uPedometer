import 'package:flutter/material.dart';

/// Zeigt einen allgemeinen, wiederverwendbaren Bestätigungsdialog an.
///
/// Gibt `true` zurück, wenn der Bestätigungs-Button gedrückt wird,
/// und `false` (oder `null`, wenn der Dialog anderweitig geschlossen wird), ansonsten.
///
/// [context]: Der BuildContext des aufrufenden Widgets.
/// [title]: Der Titel des Dialogs.
/// [content]: Die Hauptnachricht oder Frage im Dialog.
/// [confirmText]: Der Text für den Bestätigungs-Button (Standard: 'Bestätigen').
/// [cancelText]: Der Text für den Abbrechen-Button (Standard: 'Abbrechen').
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Bestätigen',
  String cancelText = 'Abbrechen',
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      // Greift auf die Theme-Daten des Dialogs zu, für konsistentes Styling.
      final dialogTheme = Theme.of(dialogContext);

      return AlertDialog(
        backgroundColor: dialogTheme.dialogTheme.backgroundColor,
        title: Text(title, style: dialogTheme.textTheme.titleLarge),
        content: Text(content, style: dialogTheme.textTheme.bodyMedium),
        actions: <Widget>[
          // Abbrechen-Button
          TextButton(
            child: Text(
              cancelText,
              style: TextStyle(color: dialogTheme.textTheme.bodyMedium?.color),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          // Bestätigen-Button (mit roter Hervorhebung)
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withAlpha(204),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
}