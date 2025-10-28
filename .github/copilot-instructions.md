# Copilot Instructions for cctweakedminer

## Project Overview

This repository contains a Lua script for CC:Tweaked (ComputerCraft: Tweaked) that automates strip mining using turtles in Minecraft. The main script (`main.lua`) controls a turtle to dig parallel tunnels, manage fuel, handle inventory, and place torches.

## Technology Stack

- **Language**: Lua 5.2/5.3 (CC:Tweaked compatible)
- **Platform**: CC:Tweaked (ComputerCraft: Tweaked mod for Minecraft)
- **Runtime**: Runs on in-game turtle computers
- **Testing**: CraftOS-PC (via GitHub Actions)

## Code Style and Conventions

### Lua Style Guidelines

- Use 2 spaces for indentation (consistent with existing code)
- Use `local` for all variables unless global scope is explicitly needed
- Follow existing naming conventions:
  - `camelCase` for functions: `safeForward()`, `mineTunnel()`
  - `UPPER_SNAKE_CASE` for constants: `DEFAULT_LENGTH`, `MAX_SLOT`
  - Descriptive variable names: `torchInterval`, `numTunnels`
- Add comments for:
  - Function purposes and assumptions
  - Complex logic or non-obvious behavior
  - Section headers for logical code groupings

### CC:Tweaked Specific Guidelines

- Always check fuel levels before long operations using `turtle.getFuelLevel()`
- Use retry-based movement pattern: attempt movement first, then detect and dig/attack if movement fails
- Handle both block obstacles (detect then dig) and mob/entity obstacles (attack if detect fails)
- Respect the 16-slot inventory limitation (`MAX_SLOT = 16`)
- Use `pause()` helper for delays (compatible with both `os.sleep` and `sleep`)
- Prefer safe movement functions (`safeForward()`, `safeUp()`, `safeDown()`) over direct turtle API calls

### Error Handling

- Check return values from movement and action commands
- Print informative error messages with context (e.g., current step number)
- Return `false` from functions when operations fail
- Ensure turtle can recover or indicate its state clearly

## Development Guidelines

### Testing

- Test with CraftOS-PC before committing changes
- Verify fuel consumption calculations
- Test edge cases:
  - Running out of fuel mid-operation
  - Full inventory scenarios
  - Obstacle handling (blocks, mobs, falling blocks)
  - Torch placement logic and slot validation

### Making Changes

- Preserve backward compatibility with existing command-line arguments
- Maintain the default values for parameters
- Keep the script runnable as a standalone file (`main.lua`)
- Ensure changes work within CC:Tweaked's limited Lua environment (no external libraries)

## Project-Specific Constraints

- **Single File Design**: The entire program is in `main.lua` - avoid splitting into modules unless absolutely necessary
- **No External Dependencies**: CC:Tweaked provides a limited standard library; don't use or suggest external Lua libraries
- **Turtle API Limitations**: 
  - Turtles have limited inventory (16 slots)
  - Movement and actions can fail (blocks, entities, bedrock)
  - Fuel is required for movement (unless configured as unlimited)
- **In-Game Execution**: Code runs on in-game computers with no filesystem access beyond the turtle's own storage
- **User Interaction**: The script uses `read()` for user confirmation before starting operations

## Common Operations

### Adding New Features

When adding features to the miner:
1. Add configurable parameters as command-line arguments
2. Provide sensible defaults as constants at the top of the file
3. Update the `usage()` function to document new parameters
4. Ensure fuel and inventory checks are in place
5. Test that the turtle can complete operations and return to start position

### Refactoring

- Maintain the existing function structure and naming
- Keep utility functions general and reusable
- Preserve the main loop structure (mine → return → shift → repeat)
- Don't change the coordinate system or movement patterns without careful consideration

## Testing Commands

The GitHub workflow uses CraftOS-PC to validate the script. When making changes, ensure:
- The script has no syntax errors
- It runs without crashing in the CraftOS-PC environment
- Basic Lua functionality is preserved
