//
//  CheckboxToggleUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public enum CheckboxToggleUseCase {
    // MARK: - Toggle

    public static func toggle(at offset: Int, in styles: [TextStyleRun]) -> CheckboxToggle? {
        guard let run = styles.first(where: { $0.span.contains(offset) && $0.kind.isCheckbox }),
              case let .checkbox(isDone) = run.kind,
              run.span.length == 3
        else {
            return nil
        }

        return CheckboxToggle(span: TextSpan(location: run.span.location + 1, length: 1), replacement: isDone ? " " : "x")
    }
}
