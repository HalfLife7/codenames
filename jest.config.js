module.exports = {
    preset: 'vite-jest',

    testMatch: [
        // '**/tests/unit/**/*.spec.ts?(x)',
        // '**/__tests__/*.ts?(x)',
        '**/tests/Frontend/**/*.ts?(x)',
    ],
    testEnvironment: 'jest-environment-jsdom'
}
