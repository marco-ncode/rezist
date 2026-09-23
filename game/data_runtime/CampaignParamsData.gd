## Typed wrapper over data/campaign_nodes.json (generation parameters, not a
## saved graph — see docs/DATA_SCHEMA.md "campaign_nodes").
class_name CampaignParamsData
extends RefCounted

var node_count_range: Array
var layers_range: Array
var nodes_per_layer_range: Array
var edge_density: float
var boss_node_layer_from_end: int
var district_weights: Dictionary
var hero_rescue_node_chance: float

func _init(parsed_json: Dictionary) -> void:
	node_count_range = parsed_json.get("node_count_range", [8, 14])
	layers_range = parsed_json.get("layers_range", [4, 6])
	nodes_per_layer_range = parsed_json.get("nodes_per_layer_range", [2, 4])
	edge_density = parsed_json.get("edge_density", 0.6)
	boss_node_layer_from_end = parsed_json.get("boss_node_layer_from_end", 1)
	district_weights = parsed_json.get("district_weights", {})
	hero_rescue_node_chance = parsed_json.get("hero_rescue_node_chance", 0.2)
