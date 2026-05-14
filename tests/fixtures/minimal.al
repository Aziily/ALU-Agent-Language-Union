flow root:
  intent: minimal flow with one code child
  steps:
    - greet


code greet:
  intent: print hello
  body: |
    def greet(input=None):
        return "hello"
