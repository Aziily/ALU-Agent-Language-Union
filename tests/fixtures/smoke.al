flow root:
  intent: smoke test for sequential orchestration
  steps:
    - add_one
    - add_one
    - times_two


code add_one:
  intent: add 1 to input
  input: int
  output: int
  body: |
    def add_one(x):
        return x + 1


code times_two:
  intent: multiply input by 2
  input: int
  output: int
  body: |
    def times_two(x):
        return x * 2
