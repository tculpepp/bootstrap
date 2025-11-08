# Workflow: Rules of Engagement

## Guiding Principles

1. **Plan Before Code**: Always consult `plan.md` and `status.md` before starting work
2. **Follow the Style Guides**: Adhere to `code_styleguide.md` and `prose_styleguide.md` strictly
3. **Test as You Go**: Verify changes work before moving to the next task
4. **Document Changes**: Update relevant documentation when making changes
5. **Update Status**: Always update `status.md` at the end of a work session

## Task Workflow

### 1. Select Task
- Review `plan.md` to identify available tasks
- Check `status.md` for current focus
- Choose a task that aligns with the current phase

### 2. Mark In Progress
- Update `status.md` with the selected task
- Change task status in `plan.md` from `[ ]` to `[~]` (in progress)

### 3. Understand Requirements
- Read relevant sections of `user_guide.md` and `architecture.md`
- Review existing code for patterns and conventions
- Identify dependencies and prerequisites

### 4. Design (if needed)
- For new features, sketch the approach
- Consider edge cases and error handling
- Ensure alignment with architecture

### 5. Implement
- Write code following `code_styleguide.md`
- Write tests if applicable
- Add comments and documentation inline

### 6. Review
- Self-review: Does it follow style guides?
- Does it handle errors gracefully?
- Is it maintainable and readable?
- Does it meet the requirements?

### 7. Test
- Test the implementation
- Verify error handling
- Check edge cases
- Ensure no regressions

### 8. Update Documentation
- Update relevant documentation files
- Add examples if needed
- Update `status.md` with progress

### 9. Mark Complete
- Change task status in `plan.md` from `[~]` to `[x]` (complete)
- Update `status.md` with completion and next actions

## Quality Gates

Before a task can be marked as complete, it must satisfy:

- [ ] Code follows `code_styleguide.md`
- [ ] Documentation follows `prose_styleguide.md`
- [ ] Functionality works as specified
- [ ] Error handling is appropriate
- [ ] Code is reviewed (self-review minimum)
- [ ] Relevant documentation is updated
- [ ] `status.md` is updated

## Definition of Done

A task is considered **done** when:

1. ✅ Implementation is complete and functional
2. ✅ Code passes self-review against style guides
3. ✅ Error cases are handled appropriately
4. ✅ Documentation is updated (code comments, user docs, etc.)
5. ✅ `plan.md` task is marked `[x]`
6. ✅ `status.md` reflects completion
7. ✅ No obvious bugs or issues remain

## Code Review Checklist

When reviewing code (self or peer):

- [ ] Follows naming conventions
- [ ] Proper error handling
- [ ] Appropriate comments
- [ ] No hardcoded values (use config)
- [ ] Functions are focused and single-purpose
- [ ] Variables are properly scoped
- [ ] Quoting is correct
- [ ] Edge cases considered
- [ ] Documentation updated

## Branching Strategy

- Work directly in main for small, isolated changes
- Create feature branches for larger features or experimental work
- Keep commits focused and well-described

## Commit Messages

Format: `[Type] Brief description`

Types:
- `[feat]` - New feature
- `[fix]` - Bug fix
- `[docs]` - Documentation changes
- `[refactor]` - Code refactoring
- `[test]` - Test additions/changes
- `[chore]` - Maintenance tasks

Example: `[feat] Add configuration file validation`

