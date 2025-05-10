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
    // 'eqeqeq': ['error', 'always'], // Enforce strict equality (===) over loose equality (==)
    // 'semi': ['error', 'always'], // Enforce semicolons at the end of statements
    // 'quotes': ['error', 'single'], // Enforce single quotes for strings
    'indent': ['error', 2], // Enforce 2-space indentation
    // 'no-magic-numbers': ['warn', { ignore: [0, 1] }], // Warn about magic numbers, but allow 0 and 1
    // 'max-len': ['warn', { code: 80 }], // Warn if lines exceed 80 characters
    'consistent-return': 'error', // Enforce consistent return statements in functions
    // 'no-var': 'error', // Enforce the use of `let` and `const` instead of `var`
  },
  settings: {
    // You can specify additional settings if needed
  },
};
