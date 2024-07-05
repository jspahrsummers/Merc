extends Control

@export var markdown_label: MarkdownLabel

@export_file("*.md") var license_file_path: String

func _ready() -> void:
    var all_license_text := self._merc_licenses() + self._godot_licenses()
    self.markdown_label.markdown_text = all_license_text

func _merc_licenses() -> String:
    var file := FileAccess.open(self.license_file_path, FileAccess.READ)
    return file.get_as_text()

func _godot_licenses() -> String:
    var result := "# Godot components"

    var copyright_info := Engine.get_copyright_info()
    for component in copyright_info:
        var component_name: String = component["name"]
        var parts: Array = component["parts"]
        for part: Dictionary in parts:
            var _files: Array = part["files"]
            var copyright: Array = part["copyright"]
            var license: String = part["license"]
            
            var all_copyrights: String = copyright.reduce(
                func(acc: String, item: String) -> String: return acc + item, ""
            )

            result += "\n\n" + component_name + "\n" + all_copyrights + "\nLicense: " + license

    result += "\n\n# Licenses"

    var licenses := Engine.get_license_info()
    for license_name: String in licenses:
        var text: String = licenses[license_name]
        result += "\n\n## " + license_name + "\n\n" + text.strip_edges()

    return result
