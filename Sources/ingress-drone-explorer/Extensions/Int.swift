extension Int {
    var digitCount: Int {
        var number = self
        var result = number < 0 ? 1 : 0;
        while (number != 0) {
            number /= 10
            result += 1
        }
        return result
    }
}