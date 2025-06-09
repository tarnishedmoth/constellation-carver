class_name ConstellationProject extends Resource

const HEADER:Dictionary = {
	"format": "particle",
	"title": "My Site",
	"content": []
}
const PARAGRAPH:Dictionary = {
	"type": "paragraph",
	"text": "This is a paragraph of text."
}
const BUTTON:Dictionary = {
	"type": "button",
	"label": "New Button",
	"action": "/"
}
const LIST:Dictionary = {
	"type": "list",
	"items": []
}
const BLOCKQUOTE:Dictionary = {
	"type": "blockquote",
	"text": "Indented paragraph."
}
const SEPARATOR:Dictionary = {
	"type": "separator"
}
const IMAGE:Dictionary = {
	"type": "image",
	"width": 100,
	"height": 60,
	"pixels": ""
}

var name:String
var pages:Dictionary = {
	"My Site" = "index.json",
}

func new_page(name:String, directory:String) -> void:
	var template:Dictionary = HEADER.duplicate(true)
	var content:Array = template["content"]
	content.append(PARAGRAPH)
	
	ParticleParser.save_json_to_file(
		JSON.stringify(HEADER),
		String("user://" + directory + name + ".json")
		)
