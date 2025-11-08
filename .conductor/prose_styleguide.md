# Prose Style Guide

## Core Voice

**"The Accessible Expert"**: Write as someone who deeply understands macOS system configuration but explains concepts clearly and without condescension. Be helpful, precise, and approachable.

## Guiding Principles

### DO
- ✅ Use clear, direct language
- ✅ Explain technical terms on first use
- ✅ Provide context for why something is done, not just how
- ✅ Use examples to illustrate concepts
- ✅ Write in active voice when possible
- ✅ Break complex topics into digestible sections
- ✅ Use consistent terminology throughout

### DON'T
- ❌ Use jargon without explanation
- ❌ Assume prior knowledge of macOS internals
- ❌ Write overly technical explanations when simple ones suffice
- ❌ Use passive voice unnecessarily
- ❌ Create overly long paragraphs
- ❌ Use inconsistent naming or terminology

## Tone

- **Professional but friendly**: Like a helpful colleague, not a manual
- **Confident but not arrogant**: Show expertise without being condescending
- **Concise but complete**: Say what needs to be said, no more, no less
- **Encouraging**: Help users feel capable, not overwhelmed

## Formatting

### Headers
- Use descriptive headers that clearly indicate content
- Use proper markdown hierarchy (## for sections, ### for subsections)

### Lists
- Use bullet points for unordered lists
- Use numbered lists for sequential steps
- Keep list items parallel in structure

### Code Blocks
- Use appropriate syntax highlighting: `bash`, `yaml`, `json`
- Include comments in code examples when helpful
- Show both the command and expected output when relevant

### Callouts

Use these callout formats for important information:

**Note:** For general information or tips
**Warning:** For potential issues or gotchas
**Important:** For critical information that must not be missed
**Example:** For illustrative examples

## Specific Stylistic Choices

### Analogies
- Use analogies sparingly, but when helpful, use them
- Prefer concrete, relatable analogies over abstract ones
- Example: "Think of modules like kitchen appliances—each has a specific job, but they work together to create a meal"

### Technical Terms
- Define acronyms on first use: "Homebrew (a package manager for macOS)"
- Use consistent capitalization: "Homebrew", "macOS", "App Store"
- Use backticks for code/commands: `` `brew install` ``

### Instructions
- Use imperative mood for commands: "Run the script" not "You should run the script"
- Number steps when sequence matters
- Provide expected outcomes: "You should see a success message"

## Documentation Structure

### README Files
1. Brief description
2. Quick start
3. Detailed usage
4. Configuration options
5. Troubleshooting

### Function Documentation
1. Purpose/description
2. Usage/parameters
3. Return values
4. Examples
5. Notes/warnings

## Examples

### Good Documentation
```markdown
## Installing Packages

The script installs packages using Homebrew, a package manager for macOS. 
Packages are defined in the configuration file and can be either formulae 
(command-line tools) or casks (GUI applications).

**Example:**
```yaml
packages:
  - name: git
    type: formula
  - name: visual-studio-code
    type: cask
```

The script checks if packages are already installed before attempting 
installation, so it's safe to run multiple times.
```

### Poor Documentation
```markdown
## Packages

Uses brew. Put stuff in config. It installs things.
```

