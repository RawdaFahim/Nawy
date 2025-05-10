module.exports = {
  languageOptions: {
    parserOptions: {
      ecmaVersion: 2021, // Allows parsing of modern ECMAScript features
      sourceType: 'module', // Allows the use of ES6 import/export
    },
    globals: {
      __dirname: 'readonly',
      module: 'readonly',
      require: 'readonly',
      process: 'readonly',
    },
  },
  rules: {
    'no-console': 'warn', // Warn when console.log is used
    'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }], // Warn for unused variables, except those starting with an underscore
    'indent': ['error', 2], // Enforce 2-space indentation
    'consistent-return': 'error', // Enforce consistent return statements in functions
    'no-var': 'error', // Enforce the use of `let` and `const` instead of `var`
  },
  settings: {
    // additional settings if needed
  },
};
