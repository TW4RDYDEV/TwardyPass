"""Aggregate counters only; never holds credentials or analysis history."""


class SessionStats:
    def __init__(self):
        self.clear()

    def clear(self):
        self.count = self.total = self.weak = self.strong = self.breaches = 0

    def record(self, score):
        self.count += 1
        self.total += score
        self.weak += score < 40
        self.strong += score >= 80

    def to_dict(self):
        return {
            "analyzed": self.count,
            "average": round(self.total / self.count, 1) if self.count else 0,
            "weak": self.weak,
            "strong": self.strong,
            "breaches": self.breaches,
        }
