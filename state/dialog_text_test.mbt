///|
test "DialogText::new parses ruby and enhanced text" {
  let text = "This is a [test](ruby) and [test]{style} text."
  let dialog_text = DialogText::new(text)
  json_inspect(dialog_text.to_json(), content=[
    "Concat",
    [
      ["String", "This is a "],
      ["Ruby", "test", { "ruby": "ruby" }],
      ["String", " and "],
      ["Enhanced", ["String", "test"], { "style": "style" }],
      ["String", " text."],
    ],
  ])
}

///|
test "DialogText::new handles unclosed brackets" {
  let text = "This is an [unclosed ruby](ruby"
  let dialog_text = DialogText::new(text)
  json_inspect(dialog_text.to_json(), content=[
    "Concat",
    [
      ["String", "This is an "],
      ["Concat", [["String", "unclosed ruby"], ["String", "(ruby"]]],
    ],
  ])
}

///|
test "DialogText::new handles nested brackets" {
  let text = "This is a [nested [enhanced]{inner}]{outer} text."
  let dialog_text = DialogText::new(text)
  json_inspect(dialog_text.to_json(), content=[
    "Concat",
    [
      ["String", "This is a "],
      [
        "Enhanced",
        [
          "Concat",
          [
            ["String", "nested "],
            ["Enhanced", ["String", "enhanced"], { "style": "inner" }],
          ],
        ],
        { "style": "outer" },
      ],
      ["String", " text."],
    ],
  ])
}

///|
test "DialogText::new handles interpolation" {
  let text = "This is an {interpolation} test."
  let dialog_text = DialogText::new(text)
  json_inspect(dialog_text.to_json(), content=[
    "String", "This is an {interpolation} test.",
  ])
}

///|
test "DialogText::new handles text in brackets" {
  let text = "This is a [bracketed text] test."
  let dialog_text = DialogText::new(text)
  json_inspect(dialog_text.to_json(), content=[
    "Concat",
    [
      ["String", "This is a "],
      [
        "Concat",
        [["String", "["], ["String", "bracketed text"], ["String", "]"]],
      ],
      ["String", " test."],
    ],
  ])
}

///|
test "DialogText::new handles text in brackets nested in enhanced text" {
  let text = "This is an [enhanced with [bracketed text]]{style} test."
  let dialog_text = DialogText::new(text)
  json_inspect(dialog_text.to_json(), content=[
    "Concat",
    [
      ["String", "This is an "],
      [
        "Enhanced",
        [
          "Concat",
          [
            ["String", "enhanced with "],
            [
              "Concat",
              [["String", "["], ["String", "bracketed text"], ["String", "]"]],
            ],
          ],
        ],
        { "style": "style" },
      ],
      ["String", " test."],
    ],
  ])
}
