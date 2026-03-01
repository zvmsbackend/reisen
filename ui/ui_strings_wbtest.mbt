///|
test "ui strings resolve from selected locale" {
  let locales_json = "{\"en\":{\"settings_back\":\"Back\"},\"ja\":{\"settings_back\":\"戻る\"}}"
  let strings = UiStrings::from_locales_json(locales_json, "ja", "en")
  assert_eq(strings.settings_back, "戻る")
}

///|
test "ui strings fallback to default locale when selected missing" {
  let locales_json = "{\"en\":{\"settings_back\":\"Back\"},\"ja\":{}}"
  let strings = UiStrings::from_locales_json(locales_json, "ja", "en")
  assert_eq(strings.settings_back, "Back")
}

///|
test "ui strings fallback to built-in defaults when key missing in all locales" {
  let locales_json = "{\"en\":{},\"ja\":{}}"
  let strings = UiStrings::from_locales_json(locales_json, "ja", "en")
  assert_eq(strings.settings_back, "Back")
}
