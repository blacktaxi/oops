# CLAUDE.md

This document helps Claude Code (and AI assistants) work effectively with the Oops repository.

## Project Overview

Oops is a lightweight, class-based object-oriented programming (OOP) library for Lua. It provides:
- First-class classes with clean inheritance
- Concise syntax for class definitions
- Class fields and methods (Python-style)
- Full metamethod support with inheritance
- Minimal runtime overhead

The entire implementation is in a single file: `src/oops.lua` (~200 lines of pure Lua).

## Key Concepts

### Architecture
- **Single-file library**: All code is in `src/oops.lua`
- **Pure Lua**: No external dependencies, works with Lua 5.1+
- **Metatable-based**: Uses Lua metatables for inheritance and OOP mechanics
- **Performance-focused**: Designed for minimal overhead

### Core API
- `class(base_class?)`: Creates a new class, optionally inheriting from `base_class`
- `isinstanceof(obj, cls)`: Runtime type checking
- Classes are callable (to create instances)
- `__init` method: Constructor
- `__super`: Access to parent class in methods
- `__class`: Special table for class fields/methods

## Development Workflow

### Setup
```bash
make deps  # Install dependencies (luarocks packages)
make all   # Run linter and tests
```

### Testing
```bash
make test  # Run test suite (uses busted)
```

Tests are in the `tests/` directory.

### Linting
```bash
make lint  # Run luacheck
```

Configuration: `.luacheckrc`

### Performance Testing
```bash
make perf  # Run performance benchmarks
```

Benchmarks are in `perftest/`.

## Code Style

### Formatting
- Uses StyLua for formatting (config: `stylua.toml`)
- 2-space indentation
- Run `make format` to auto-format code

### Conventions
- Follow existing naming patterns (lowercase with underscores)
- Keep implementation minimal and focused
- Prefer clarity over cleverness
- Document non-obvious metatable mechanics with comments

## Working with the Codebase

### Making Changes to Core Library

When modifying `src/oops.lua`:

1. **Understand the metatable chain**: The library relies heavily on Lua metatables for:
   - Instance creation and initialization
   - Method lookup and inheritance
   - Metamethod delegation

2. **Preserve backward compatibility**: This is a published library on LuaRocks
   - Don't break existing API
   - Add new features as opt-in when possible

3. **Test thoroughly**:
   - Add tests for new features in `tests/`
   - Run existing tests: `make test`
   - Check performance impact: `make perf`
   - Test with examples: `make examples`

4. **Consider edge cases**:
   - Multiple inheritance levels
   - Metamethod overriding
   - Class vs instance method behavior
   - Memory/performance implications

### Examples

The `examples/` directory contains usage demonstrations. When adding features:
- Add corresponding examples if the feature is user-facing
- Keep examples simple and focused on one concept
- Examples should be runnable: `lua examples/your_example.lua`

## Testing Guidelines

### Test Structure
- Tests use the Busted framework
- Test files are in `tests/`
- Each test file focuses on specific functionality

### Writing Tests
```lua
describe("feature name", function()
  it("should do something specific", function()
    -- arrange
    local MyClass = class { ... }

    -- act
    local result = MyClass()

    -- assert
    assert.are.equal(expected, result)
  end)
end)
```

### What to Test
- Class creation and instantiation
- Inheritance behavior
- Method resolution order
- Metamethod behavior
- Edge cases and error conditions
- Performance-critical paths (via perftest)

## Common Tasks

### Adding a New Feature
1. Read the existing implementation in `src/oops.lua`
2. Write tests first (TDD approach works well here)
3. Implement the feature
4. Run `make all` to verify
5. Add example if user-facing
6. Update README.md if needed

### Fixing a Bug
1. Add a failing test that reproduces the bug
2. Fix the implementation
3. Verify all tests pass: `make test`
4. Check for performance regression: `make perf`

### Refactoring
1. Ensure test coverage is good first
2. Make incremental changes
3. Run tests after each change
4. Use `make perf` to ensure no performance degradation
5. Keep backward compatibility

## Important Files

- `src/oops.lua` - Core implementation
- `tests/` - Test suite
- `examples/` - Usage examples
- `.luacheckrc` - Linter configuration
- `stylua.toml` - Formatter configuration
- `Makefile` - Build and test commands
- `*.rockspec` - LuaRocks package specifications

## Performance Considerations

This library is designed for minimal overhead:
- Avoid unnecessary table allocations
- Keep metatable lookups efficient
- Use local variables for frequently accessed values
- Profile with `make perf` before and after changes

## Lua Version Compatibility

- Primary target: Lua 5.1+
- Should work with LuaJIT
- Test with multiple Lua versions when making core changes

## Questions or Issues?

When working with this codebase, refer to:
1. Lua metatable documentation (crucial for understanding implementation)
2. Existing tests for usage patterns
3. Examples for user-facing behavior
4. README.md for public API documentation
