extension String {
    func camelToSnakeCase() -> String {
        var newValue: String = ""
        for letter in self {
            let newLetter = letter.isUppercase ? "_\(letter.lowercased())" : "\(letter)"
            newValue.append(newLetter)
        }
        return newValue
    }
}
