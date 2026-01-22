/**
 * Commitlint Configuration
 *
 * Extends @commitlint/config-conventional with JIRA ticket integration.
 * Commit format: [TICKET-ID] <type>[scope]: <description>
 *
 * @see https://commitlint.js.org/
 * @see https://www.conventionalcommits.org/en/v1.0.0/
 */
export default {
  extends: ['@commitlint/config-conventional'],

  /**
   * Custom parser preset to support JIRA ticket prefix
   * Pattern: [PROJECT-123] type(scope): description
   */
  parserPreset: {
    parserOpts: {
      headerPattern: /^\[([A-Z]+-\d+)\]\s(\w+)(?:\(([^)]+)\))?!?:\s(.+)$/,
      headerCorrespondence: ['ticket', 'type', 'scope', 'subject'],
    },
  },

  rules: {
    /**
     * Allowed commit types
     * @see https://www.conventionalcommits.org/en/v1.0.0/#specification
     */
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature (MINOR version)
        'fix',      // Bug fix (PATCH version)
        'docs',     // Documentation only changes
        'style',    // Code style (formatting, whitespace)
        'refactor', // Code change that neither fixes a bug nor adds a feature
        'perf',     // Performance improvement (PATCH version)
        'test',     // Adding or updating tests
        'build',    // Build system or external dependencies
        'ci',       // CI configuration changes
        'chore',    // Maintenance tasks
        'revert',   // Reverting a previous commit
      ],
    ],

    /**
     * Subject (description) rules
     */
    'subject-empty': [2, 'never'],
    'subject-case': [2, 'always', 'lower-case'],

    /**
     * Type rules
     */
    'type-empty': [2, 'never'],
    'type-case': [2, 'always', 'lower-case'],

    /**
     * Scope rules (optional but recommended)
     * Recommended scopes: api, ui, db, auth, config, deps, infra, test, core, utils
     */
    'scope-case': [2, 'always', 'lower-case'],

    /**
     * Body rules
     */
    'body-leading-blank': [2, 'always'],
    'body-max-line-length': [2, 'always', 100],

    /**
     * Footer rules
     */
    'footer-leading-blank': [2, 'always'],
    'footer-max-line-length': [2, 'always', 100],

    /**
     * Header rules
     */
    'header-max-length': [2, 'always', 100],
  },

  /**
   * Ignore patterns for automated commits
   */
  ignores: [
    (commit) => commit.startsWith('Merge '),
    (commit) => commit.startsWith('Revert '),
    (commit) => commit.startsWith('Initial commit'),
  ],

  /**
   * Help URL for commit message guidelines
   */
  helpUrl: 'https://www.conventionalcommits.org/en/v1.0.0/',
};
