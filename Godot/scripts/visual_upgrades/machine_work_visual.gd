extends Node
class_name HashRaceMachineWorkVisual
## Work/progress visual component adapted from GDQuest's simulation component pattern.

signal work_started
signal work_progress(value: float)
signal work_finished

@export var progress_bar: ProgressBar
@export var particles: GPUParticles2D
@export var work_time := 2.0

var _timer := 0.0
var _active := false

func start_work(duration := -1.0) -> void:
    if duration > 0.0:
        work_time = duration
    _timer = 0.0
    _active = true
    if is_instance_valid(particles):
        particles.emitting = true
    work_started.emit()

func cancel_work() -> void:
    _active = false
    if is_instance_valid(particles):
        particles.emitting = false

func _process(delta: float) -> void:
    if not _active:
        return
    _timer += delta
    var ratio := clampf(_timer / maxf(work_time, 0.001), 0.0, 1.0)
    if is_instance_valid(progress_bar):
        progress_bar.value = ratio * 100.0
    work_progress.emit(ratio)
    if ratio >= 1.0:
        _active = false
        if is_instance_valid(particles):
            particles.emitting = false
        work_finished.emit()
