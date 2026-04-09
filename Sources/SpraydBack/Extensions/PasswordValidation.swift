import Foundation

func validatePassword(_ password: String) -> Bool {
    guard password.count >= 8 else { return false }
    var classes = 0
    if password.contains(where: { $0.isUppercase }) { classes += 1 }
    if password.contains(where: { $0.isLowercase }) { classes += 1 }
    if password.contains(where: { $0.isNumber }) { classes += 1 }
    if password.contains(where: { !$0.isLetter && !$0.isNumber }) { classes += 1 }
    return classes >= 2
}
