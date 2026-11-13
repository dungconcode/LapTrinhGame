extends Resource

class_name MapArchetype

@export var viabilityLargeRange: Vector3
@export var viabilitySmallRange: Vector3

@export var generateResources := true

@export var width := 80
@export var depth := 40
@export var tileCount := 0
@export var max_tile_count_deviation := 0.015

@export var viability_large_noise: FastNoiseLite
@export var viability_small_noise: FastNoiseLite
@export var hardness_noise: FastNoiseLite

@export var first_biome_size = 400
@export var biome_max_size = 1400
@export var biome_size_multiplier = 1.05
@export var biome_size_addition = 150
@export var biome_cleanup_passes := 1

@export var viability_large_noise_strength := 60.0
@export var viability_small_noise_strength := 10.0
@export var viability_base := 110.0

@export var viability_thin_top_length := 10.0
@export var viability_thin_top_width := 22.0
@export var viability_thin_top_strength := 200.0

@export var viability_stop_depth_factor := 0.1
@export var viability_stop_width_factor := 0.07

@export var keep_core_strength := 1.5
@export var keep_core_falloff_y := 0.9

@export var stop_depth_at_fraction := 0.5
@export var stop_depth_factor := 10.0
@export var stop_depth_exponent := 2.0

@export var stop_width_at_fraction := 10.0
@export var stop_width_factor := 10.0
@export var stop_width_exponent := 2.0

@export var entry_tightening_until := 0.6
@export var entry_tightening_y_exp := 3.0
@export var entry_tightening_x_exp := 2.0

@export var thin_top_factor := 30.0

@export var hardness_scale := 4.0
@export var hardness_offset := 0.4
@export var hardness_min := 0
@export var hardness_max := 4

@export var iron_cluster_rate := 10.0
@export var water_rate := 8.0
@export var cobalt_rate := 8.0

@export var iron_cluster_removal_rate := 0.2
@export var water_removal_rate := 0.2
@export var cobalt_removal_rate := 0.2

@export var iron_cluster_size_base := 1.5
@export var iron_cluster_size_per_y := 0.2
@export var iron_cluster_size_randomness := 0.02

@export var relics := 1
@export var relic_switches := 2
@export var relic_switch_distance_range := Vector2(10, 20)
@export var relic_switch_angle_range_pi := Vector2(-0.2, 0.2)
@export var relic_depth_step := 12

@export var gadgets := 3
@export var gadget_first_depth := 15
@export var gadget_depth_step := 17

@export var powercores := 1
@export var powercore_first_depth := 20
@export var powercore_depth_step := 24

@export var hole_size_base := 5.0
@export var hole_size_per_biome := 1.0
@export var hole_size_randomness := 0.3
@export var holes_per_biome := 3
@export var holes_per_biome_randomness := 0.0


func randomize_values(rand:RandomNumberGenerator):
	if viabilityLargeRange:
		var factor = rand.randf_range(-1.0, 1.0)
		factor = sign(factor) * pow(rand.randf(), viabilityLargeRange.z)
		viability_large_noise_strength = viabilityLargeRange.x - viabilityLargeRange.y * 0.5 + factor * viabilityLargeRange.y 
	
	if viabilitySmallRange:
		var factor = rand.randf_range(-1.0, 1.0)
		factor = sign(factor) * pow(rand.randf(), viabilitySmallRange.z)
		viability_small_noise_strength = viabilitySmallRange.x - viabilitySmallRange.y * 0.5 + factor * viabilitySmallRange.y 


func ensureNoiseExists():
	if not viability_large_noise:
		viability_large_noise = preload("res://content/map/generation/noises/viability_large_noise.tres")
	if not viability_small_noise:
		viability_small_noise = preload("res://content/map/generation/noises/viability_small_noise.tres")
	if not hardness_noise:
		hardness_noise = preload("res://content/map/generation/noises/hardness_noise.tres")
