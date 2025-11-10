extends Node
class_name AutoloadUtils

static func get_autoload(autoload_name: String) -> Node:
    var main_loop: MainLoop = Engine.get_main_loop()
    if main_loop == null:
        push_error("[AutoloadUtils] Main loop unavailable when requesting autoload: " + autoload_name)
        return null
    if not (main_loop is SceneTree):
        push_error("[AutoloadUtils] Main loop is not a SceneTree when requesting autoload: " + autoload_name)
        return null
    var scene_tree: SceneTree = main_loop as SceneTree
    var root: Node = scene_tree.root
    if root == null:
        push_error("[AutoloadUtils] Root viewport unavailable when requesting autoload: " + autoload_name)
        return null
    if root.has_node(autoload_name):
        return root.get_node(autoload_name)
    push_error("[AutoloadUtils] Autoload not found: " + autoload_name)
    return null
