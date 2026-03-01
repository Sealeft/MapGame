# Testing Setup (GdUnit4)

This project uses **GdUnit4** for GDScript tests.

## Test folders

- `res://tests/unit` – pure logic tests
- `res://tests/integration` – scene/script integration tests

## Current test suites

- `res://tests/unit/GameStateTest.gd`
- `res://tests/integration/SceneInstantiationTest.gd`

## Run tests in the Godot editor

1. Open the project in Godot.
2. Open the **GdUnit4** panel (bottom panel / plugin tab).
3. Run all tests, or run a single suite from the test tree.

## Run tests from CLI (headless)

Use your Godot executable path, for example:

`godot4 --headless --path . -s res://addons/gdUnit4/runtest.gd -a res://tests`

If `godot4` is not on PATH, replace it with your full Godot executable path.

## Notes

- Unit tests avoid depending on scene tree where possible.
- Integration tests currently validate that critical scenes instantiate and contain required nodes.
- Add new tests by creating `*Test.gd` files that `extends GdUnitTestSuite`.
