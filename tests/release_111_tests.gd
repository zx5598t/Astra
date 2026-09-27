extends SceneTree

var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    var workflow := FileAccess.get_file_as_string("res://.github/workflows/release.yml")
    var version := FileAccess.get_file_as_string("res://VERSION").strip_edges()
    var notes := FileAccess.get_file_as_string("res://docs/RELEASE_NOTES.md")
    check("workflow_run" in workflow and 'workflows: ["Godot CI"]' in workflow, "release waits for Godot CI")
    check("github.event.workflow_run.head_branch == 'main'" in workflow, "release only publishes tested main")
    check("ref: ${{ github.event.workflow_run.head_sha }}" in workflow, "checkout uses exact tested head SHA")
    check("RUN_ID: ${{ github.event.workflow_run.id }}" in workflow, "artifact download is bound to exact CI run")
    check('ASTRA-$VERSION-windows-rc' in workflow, "artifact name is dynamic from VERSION")
    check('ASTRA-$VERSION-windows.zip' in workflow, "ZIP name is dynamic from VERSION")
    check('sha256sum' in workflow and 'test "$actual" = "$expected"' in workflow, "release verifies artifact SHA256")
    check('gh release view "v$version"' in workflow, "existing version release is left untouched")
    check('--target "$TESTED_SHA"' in workflow, "release tag targets exact tested SHA")
    check('docs/RELEASE_NOTES.md' in workflow and 'ENVIRON["VERSION"]' in workflow, "release notes section is selected dynamically")
    check(("1.1.0" not in workflow), "generic publisher contains no 1.1.0 hardcode")
    check(("# ASTRA " + version + " ") in notes, "current VERSION has a release-notes heading")
    if failures.is_empty():
        print("ASTRA RELEASE 111 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA RELEASE 111 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)
